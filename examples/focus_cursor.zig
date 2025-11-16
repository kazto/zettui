const std = @import("std");
const zettui = @import("zettui");
const posix = std.posix;

const Entry = struct { label: []const u8, value: []const u8 };

const entries = [_]Entry{
    .{ .label = "Project", .value = "Zettui" },
    .{ .label = "Module", .value = "components/dom" },
    .{ .label = "Screen", .value = "screen_interactive" },
};

const EntryCount = entries.len;

const ArrowKey = enum { up, down, left, right };

const InputEvent = union(enum) {
    character: u8,
    arrow: ArrowKey,
    escape: void,
    control: u8,
};

const DemoState = struct {
    focus_index: usize = 0,
    cursor_positions: [EntryCount]usize = [_]usize{0} ** EntryCount,
    running: bool = true,
};

pub fn main() !void {
    var state = DemoState{};
    for (&state.cursor_positions, 0..) |*slot, idx| {
        slot.* = entries[idx].value.len;
    }

    var stdout = std.fs.File.stdout();
    const stdin_fd = posix.STDIN_FILENO;
    const token = try enableRawMode(stdin_fd);
    defer disableRawMode(stdin_fd, token);

    while (state.running) {
        try renderState(&stdout, &state);
        const event = try readEvent(stdin_fd);
        handleEvent(&state, event);
    }
}

fn renderState(stdout: *std.fs.File, state: *DemoState) !void {
    try stdout.writeAll("\x1b[2J\x1b[H");
    try stdout.writeAll("Focus Cursor Demo\n");
    try stdout.writeAll("Use Up/Down to move focus, Left/Right for cursor, Tab to advance, 'q' to quit.\n\n");

    const active = entries[state.focus_index];
    var status_buf: [96]u8 = undefined;
    const cursor = state.cursor_positions[state.focus_index];
    const status = try std.fmt.bufPrint(&status_buf, "Focus: {s} | Cursor: {d}/{d}\n\n", .{ active.label, cursor, active.value.len });
    try stdout.writeAll(status);

    var ctx = makeRenderContext(stdout);
    for (entries, 0..) |entry, idx| {
        var line_buf: [128]u8 = undefined;
        const line = try std.fmt.bufPrint(&line_buf, "{s}: {s}", .{ entry.label, entry.value });
        var base_node = zettui.dom.elements.text(line);
        var render_node = base_node;
        if (idx == state.focus_index) {
            render_node = zettui.dom.elements.stylePtr(&base_node, .{ .bold = true, .fg = 0xF97316 });
        }
        try render_node.render(&ctx);
        try stdout.writeAll("\n");
        if (idx == state.focus_index) {
            try drawCursor(stdout, entry.value, cursor);
        }
    }
}

fn drawCursor(stdout: *std.fs.File, value: []const u8, cursor: usize) !void {
    try stdout.writeAll("    ");
    var i: usize = 0;
    const limit = if (cursor > value.len) value.len else cursor;
    while (i < limit) : (i += 1) {
        try stdout.writeAll(" ");
    }
    try stdout.writeAll("^\n\n");
}

fn handleEvent(state: *DemoState, event: InputEvent) void {
    switch (event) {
        .arrow => |arrow| switch (arrow) {
            .up => moveFocus(state, -1),
            .down => moveFocus(state, 1),
            .left => moveCursor(state, -1),
            .right => moveCursor(state, 1),
        },
        .character => |ch| switch (ch) {
            'q' => state.running = false,
            '\t' => moveFocus(state, 1),
            '\r', '\n' => moveFocus(state, 1),
            else => {},
        },
        .control => |code| {
            if (code == 0x03) state.running = false;
        },
        .escape => {},
    }
}

fn moveFocus(state: *DemoState, delta: i32) void {
    if (entries.len == 0) return;
    const count = entries.len;
    const current = @as(i32, @intCast(state.focus_index)) + delta;
    var wrapped = current;
    if (wrapped < 0) {
        wrapped = @as(i32, @intCast(count)) - 1;
    } else if (wrapped >= @as(i32, @intCast(count))) {
        wrapped = 0;
    }
    state.focus_index = @as(usize, @intCast(wrapped));
    const active_len = entries[state.focus_index].value.len;
    if (state.cursor_positions[state.focus_index] > active_len) {
        state.cursor_positions[state.focus_index] = active_len;
    }
}

fn moveCursor(state: *DemoState, delta: i32) void {
    const idx = state.focus_index;
    var cursor = @as(i32, @intCast(state.cursor_positions[idx])) + delta;
    if (cursor < 0) cursor = 0;
    const max_len = @as(i32, @intCast(entries[idx].value.len));
    if (cursor > max_len) cursor = max_len;
    state.cursor_positions[idx] = @as(usize, @intCast(cursor));
}

fn readEvent(fd: posix.fd_t) !InputEvent {
    const byte = try readByte(fd);
    return switch (byte) {
        0x1B => try decodeEscape(fd),
        else => blk: {
            if (byte < 32 and byte != '\n' and byte != '\r' and byte != '\t') break :blk InputEvent{ .control = byte };
            break :blk InputEvent{ .character = byte };
        },
    };
}

fn decodeEscape(fd: posix.fd_t) !InputEvent {
    const second = readByte(fd) catch return .escape;
    if (second == '[') {
        const third = readByte(fd) catch return .escape;
        return switch (third) {
            'A' => .{ .arrow = .up },
            'B' => .{ .arrow = .down },
            'C' => .{ .arrow = .right },
            'D' => .{ .arrow = .left },
            else => .escape,
        };
    }
    return .escape;
}

fn enableRawMode(fd: posix.fd_t) !posix.termios {
    const term = try posix.tcgetattr(fd);
    var raw = term;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    raw.cc[6] = 1; // VMIN
    raw.cc[5] = 0; // VTIME
    try posix.tcsetattr(fd, .NOW, raw);
    return term;
}

fn disableRawMode(fd: posix.fd_t, token: posix.termios) void {
    posix.tcsetattr(fd, .NOW, token) catch {};
}

fn readByte(fd: posix.fd_t) !u8 {
    var buf: [1]u8 = undefined;
    while (true) {
        const result = posix.read(fd, &buf) catch |err| return err;
        if (result == 0) continue;
        return buf[0];
    }
}

fn makeRenderContext(stdout: *std.fs.File) zettui.dom.RenderContext {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    return .{ .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write } };
}
