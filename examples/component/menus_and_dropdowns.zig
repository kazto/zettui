const std = @import("std");
const posix = std.posix;
const zettui = @import("zettui");

const ArrowKey = enum { up, down, left, right };

const InputEvent = union(enum) {
    character: u8,
    arrow: ArrowKey,
    escape: void,
    control: u8,
    enter: void,
};

const Cursor = zettui.screen.Cursor;
const ScreenCtl = zettui.screen.ScreenControl;
const Style = zettui.screen.Style;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();

    // Setup: create menu component
    const labels = [_][]const u8{ "Home", "Graphs", "Tables", "Settings", "Help" };
    const menu_component = try zettui.component.widgets.menu(a, .{
        .items = &labels,
        .selected_index = 0,
        .loop_navigation = true,
        .highlight_color = 0xF97316,
    });

    // Enter raw mode for interactive input
    const stdin_fd = posix.STDIN_FILENO;
    const token = try enableRawMode(stdin_fd);
    defer disableRawMode(stdin_fd, token);

    // Hide cursor
    try stdout.writeAll(Cursor.hide);
    defer stdout.writeAll(Cursor.show) catch {};

    var selected_label: ?[]const u8 = null;
    var running = true;

    while (running) {
        // Clear screen and move cursor to top-left
        try stdout.writeAll(ScreenCtl.clearAndHome);

        // Render header
        try renderHeading(&stdout, a, "=== Interactive Menu Demo ===", .{ .bold = true, .fg = 0x3B82F6 });
        try stdout.writeAll("\n");
        try stdout.writeAll("Use " ++ Style.bold ++ "↑/↓" ++ Style.reset ++ " to navigate, " ++
            Style.bold ++ "Enter" ++ Style.reset ++ " to select, " ++
            Style.bold ++ "q" ++ Style.reset ++ " to quit\n\n");

        // Render menu
        try menu_component.render();
        try stdout.writeAll("\n");

        // Show selection result if any
        if (selected_label) |label| {
            var buf: [16]u8 = undefined;
            try stdout.writeAll(Style.fg(&buf, Style.Color.green));
            try stdout.writeAll("✓ Selected: ");
            try stdout.writeAll(label);
            try stdout.writeAll(Style.reset ++ "\n");
        }

        // Read and handle input
        const event = try readEvent(stdin_fd);
        switch (event) {
            .character => |ch| {
                if (ch == 'q') {
                    running = false;
                }
            },
            .arrow => |arrow| {
                const key_event = zettui.component.Event{
                    .key = .{
                        .arrow_key = switch (arrow) {
                            .up => .up,
                            .down => .down,
                            .left => .left,
                            .right => .right,
                        },
                    },
                };
                _ = menu_component.onEvent(key_event);
            },
            .enter => {
                // Get current selection from menu's focus_index
                const idx = menu_component.base.focus_index;
                if (idx < labels.len) {
                    selected_label = labels[idx];
                }
            },
            .control => |code| {
                if (code == 0x03) { // Ctrl+C
                    running = false;
                }
            },
            .escape => {},
        }
    }

    // Clear screen before exit
    try stdout.writeAll(ScreenCtl.clearAndHome);
    try stdout.writeAll("Goodbye!\n");
}

fn readEvent(fd: posix.fd_t) !InputEvent {
    const byte = try readByte(fd);
    return switch (byte) {
        0x1B => try decodeEscape(fd),
        '\r', '\n' => .enter,
        else => blk: {
            if (byte < 32 and byte != '\t') break :blk InputEvent{ .control = byte };
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

fn renderHeading(stdout: *std.fs.File, allocator: std.mem.Allocator, text: []const u8, attrs: zettui.dom.StyleAttributes) !void {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    var ctx: zettui.dom.RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write },
    };
    const node = try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text(text), attrs);
    try node.render(&ctx);
    try stdout.writeAll("\n");
}
