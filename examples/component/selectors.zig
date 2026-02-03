const std = @import("std");
const posix = std.posix;
const zettui = @import("zettui");

const Cursor = zettui.screen.Cursor;
const ScreenCtl = zettui.screen.ScreenControl;
const Style = zettui.screen.Style;

const ArrowKey = enum { up, down, left, right };

const InputEvent = union(enum) {
    character: u8,
    arrow: ArrowKey,
    escape: void,
    control: u8,
    enter: void,
    space: void,
    tab: void,
};

const Section = enum { checkboxes, toggles, radio };

// Pre-computed style sequences
const active_header = Style.bold ++ "\x1b[33m"; // bold yellow
const highlight = "\x1b[36m"; // cyan
const green = "\x1b[32m";
const magenta = "\x1b[35m";
const yellow = "\x1b[33m";
const red = "\x1b[31m";
const blue = "\x1b[34m";

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();

    // Create checkbox components
    var checkbox_states = [_]bool{ false, true, false };
    const checkbox_labels = [_][]const u8{ "Enable notifications", "Dark mode", "Auto-save" };

    // Create toggle component
    var toggle_on = true;

    // Create radio group state
    var radio_selected: usize = 0;
    const radio_labels = [_][]const u8{ "Small", "Medium", "Large" };

    // Current section and item index
    var current_section: Section = .checkboxes;
    var checkbox_index: usize = 0;
    var radio_index: usize = 0;

    // Enter raw mode
    const stdin_fd = posix.STDIN_FILENO;
    const token = try enableRawMode(stdin_fd);
    defer disableRawMode(stdin_fd, token);

    // Hide cursor
    try stdout.writeAll(Cursor.hide);
    defer stdout.writeAll(Cursor.show) catch {};

    var running = true;

    while (running) {
        // Clear screen
        try stdout.writeAll(ScreenCtl.clearAndHome);

        // Header
        try renderHeading(&stdout, a, "=== Interactive Selectors Demo ===", .{ .bold = true, .fg = 0xEC4899 });
        try stdout.writeAll("\n");
        try stdout.writeAll("Use " ++ Style.bold ++ "↑/↓" ++ Style.reset ++ " to move, " ++
            Style.bold ++ "Tab" ++ Style.reset ++ " to switch section, " ++
            Style.bold ++ "Space" ++ Style.reset ++ " to toggle, " ++
            Style.bold ++ "q" ++ Style.reset ++ " to quit\n\n");

        // === Checkboxes Section ===
        const cb_active = current_section == .checkboxes;
        if (cb_active) {
            try stdout.writeAll(active_header ++ "▶ Checkboxes" ++ Style.reset ++ "\n");
        } else {
            try stdout.writeAll("  Checkboxes\n");
        }
        for (checkbox_labels, 0..) |label, i| {
            const is_selected = cb_active and checkbox_index == i;
            const checked = checkbox_states[i];
            const box = if (checked) "[x]" else "[ ]";
            const prefix = if (is_selected) highlight ++ " > " else "   ";
            const suffix = if (is_selected) Style.reset else "";
            var buf: [128]u8 = undefined;
            const line = try std.fmt.bufPrint(&buf, "{s}{s} {s}{s}\n", .{ prefix, box, label, suffix });
            try stdout.writeAll(line);
        }
        try stdout.writeAll("\n");

        // === Toggle Section ===
        const tg_active = current_section == .toggles;
        if (tg_active) {
            try stdout.writeAll(active_header ++ "▶ Toggle" ++ Style.reset ++ "\n");
        } else {
            try stdout.writeAll("  Toggle\n");
        }
        {
            const prefix = if (tg_active) highlight ++ " > " else "   ";
            const suffix = if (tg_active) Style.reset else "";
            const state_text = if (toggle_on) "[ON]  Sound" else "[OFF] Sound";
            var buf: [128]u8 = undefined;
            const line = try std.fmt.bufPrint(&buf, "{s}{s}{s}\n", .{ prefix, state_text, suffix });
            try stdout.writeAll(line);
        }
        try stdout.writeAll("\n");

        // === Radio Section ===
        const rd_active = current_section == .radio;
        if (rd_active) {
            try stdout.writeAll(active_header ++ "▶ Size (Radio)" ++ Style.reset ++ "\n");
        } else {
            try stdout.writeAll("  Size (Radio)\n");
        }
        for (radio_labels, 0..) |label, i| {
            const is_cursor = rd_active and radio_index == i;
            const is_selected = radio_selected == i;
            const dot = if (is_selected) "(●)" else "( )";
            const prefix = if (is_cursor) highlight ++ " > " else "   ";
            const suffix = if (is_cursor) Style.reset else "";
            var buf: [128]u8 = undefined;
            const line = try std.fmt.bufPrint(&buf, "{s}{s} {s}{s}\n", .{ prefix, dot, label, suffix });
            try stdout.writeAll(line);
        }
        try stdout.writeAll("\n");

        // === Status display based on selections ===
        try stdout.writeAll(Style.bold ++ "--- Current Settings ---" ++ Style.reset ++ "\n");
        {
            var buf: [256]u8 = undefined;

            // Checkbox summary
            var enabled_count: usize = 0;
            for (checkbox_states) |s| {
                if (s) enabled_count += 1;
            }
            const cb_msg = try std.fmt.bufPrint(&buf, "Features: {d}/3 enabled", .{enabled_count});
            try stdout.writeAll(cb_msg);
            if (checkbox_states[0]) try stdout.writeAll(" " ++ green ++ "[notifications]" ++ Style.reset);
            if (checkbox_states[1]) try stdout.writeAll(" " ++ magenta ++ "[dark]" ++ Style.reset);
            if (checkbox_states[2]) try stdout.writeAll(" " ++ yellow ++ "[auto-save]" ++ Style.reset);
            try stdout.writeAll("\n");

            // Toggle summary
            const sound_msg = if (toggle_on) "Sound: " ++ green ++ "ON" ++ Style.reset else "Sound: " ++ red ++ "OFF" ++ Style.reset;
            try stdout.writeAll(sound_msg);
            try stdout.writeAll("\n");

            // Radio summary
            const size_msg = try std.fmt.bufPrint(&buf, "Size: " ++ blue ++ "{s}" ++ Style.reset ++ "\n", .{radio_labels[radio_selected]});
            try stdout.writeAll(size_msg);
        }

        // Read input
        const event = try readEvent(stdin_fd);
        switch (event) {
            .character => |ch| {
                if (ch == 'q') running = false;
            },
            .arrow => |arrow| {
                switch (current_section) {
                    .checkboxes => {
                        if (arrow == .up and checkbox_index > 0) checkbox_index -= 1;
                        if (arrow == .down and checkbox_index < checkbox_labels.len - 1) checkbox_index += 1;
                    },
                    .toggles => {},
                    .radio => {
                        if (arrow == .up and radio_index > 0) radio_index -= 1;
                        if (arrow == .down and radio_index < radio_labels.len - 1) radio_index += 1;
                    },
                }
            },
            .space, .enter => {
                switch (current_section) {
                    .checkboxes => checkbox_states[checkbox_index] = !checkbox_states[checkbox_index],
                    .toggles => toggle_on = !toggle_on,
                    .radio => radio_selected = radio_index,
                }
            },
            .tab => {
                current_section = switch (current_section) {
                    .checkboxes => .toggles,
                    .toggles => .radio,
                    .radio => .checkboxes,
                };
            },
            .control => |code| {
                if (code == 0x03) running = false;
            },
            .escape => {},
        }
    }

    try stdout.writeAll(ScreenCtl.clearAndHome);
    try stdout.writeAll("Goodbye!\n");
}

fn readEvent(fd: posix.fd_t) !InputEvent {
    const byte = try readByte(fd);
    return switch (byte) {
        0x1B => try decodeEscape(fd),
        '\r', '\n' => .enter,
        ' ' => .space,
        '\t' => .tab,
        else => blk: {
            if (byte < 32) break :blk InputEvent{ .control = byte };
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
