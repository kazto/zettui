const std = @import("std");
const zettui = @import("zettui");
const posix = std.posix;
const MENU_ROW_BASE: usize = 7;

const DemoState = struct {
    menu_items: []const []const u8,
    menu_index: usize = 0,
    log: std.ArrayListUnmanaged(u8) = .{},
    running: bool = true,
    button_flash: bool = false,
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator, items: []const []const u8) DemoState {
        return .{
            .menu_items = items,
            .menu_index = 0,
            .allocator = allocator,
        };
    }

    fn deinit(self: *DemoState) void {
        self.log.deinit(self.allocator);
    }

    fn setLog(self: *DemoState, comptime fmt: []const u8, args: anytype) !void {
        self.log.clearRetainingCapacity();
        try std.fmt.format(self.log.writer(self.allocator), fmt, args);
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const menu_items = [_][]const u8{ "Overview", "Networking", "Rendering", "Input" };
    var state = DemoState.init(allocator, &menu_items);
    defer state.deinit();

    const stdin_fd = posix.STDIN_FILENO;
    const raw_token = try enableRawMode(stdin_fd);
    defer disableRawMode(stdin_fd, raw_token);

    try enableMouseTracking();
    defer disableMouseTracking();

    try renderUI(allocator, &state);

    while (state.running) {
        const byte = try readByte(stdin_fd);
        try processInput(stdin_fd, byte, &state);
        if (!state.running) break;
        try renderUI(allocator, &state);
        state.button_flash = false;
    }
}

fn renderUI(allocator: std.mem.Allocator, state: *DemoState) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const stdout = std.fs.File.stdout();
    try stdout.writeAll("\x1b[2J\x1b[H");

    var ctx: zettui.dom.RenderContext = .{};
    const heading = try zettui.dom.elements.styleOwned(a, zettui.dom.elements.text("Interactive Menu & Button Demo"), .{ .bold = true, .fg = 0x22D3EE });
    try heading.render(&ctx);
    try stdout.writeAll("\n");
    const instructions = [_][]const u8{
        "Use arrow keys to move the menu. Enter selects.",
        "Press space or click to toggle the button. Press q to quit.",
    };
    for (instructions) |line| {
        try stdout.writeAll(line);
        try stdout.writeAll("\n");
    }
    try stdout.writeAll("\n");
    try stdout.writeAll("[Menu]\n");

    var menu_nodes = try a.alloc(zettui.dom.Node, state.menu_items.len);
    for (state.menu_items, 0..) |item, idx| {
        const base = zettui.dom.elements.text(item);
        if (idx == state.menu_index) {
            menu_nodes[idx] = try zettui.dom.elements.styleOwned(a, base, .{ .bold = true, .fg = 0xF97316 });
        } else {
            menu_nodes[idx] = base;
        }
    }
    const menu_box = zettui.dom.elements.vbox(menu_nodes);
    try menu_box.render(&ctx);
    try stdout.writeAll("\n");

    var button_style = zettui.dom.StyleAttributes{ .bold = true, .fg = 0xA855F7 };
    if (state.button_flash) {
        button_style = .{
            .inverse = true,
            .fg = 0xFFFFFF,
            .bg = 0x0F172A,
            .bold = true,
        };
    }
    const button = try zettui.dom.elements.styleOwned(a, zettui.dom.elements.text("[ Click me ]"), button_style);
    try stdout.writeAll("[Action Button]\n");
    try button.render(&ctx);
    try stdout.writeAll("\n\n");

    const log_text = if (state.log.items.len == 0) "No actions yet." else state.log.items;
    try stdout.writeAll("[Last Action]\n");
    try stdout.writeAll(log_text);
    try stdout.writeAll("\n");
}

fn enableMouseTracking() !void {
    const stdout = std.fs.File.stdout();
    try stdout.writeAll("\x1b[?1002h\x1b[?1006h");
}

fn disableMouseTracking() void {
    const stdout = std.fs.File.stdout();
    stdout.writeAll("\x1b[?1002l\x1b[?1006l") catch {};
}

fn processInput(fd: posix.fd_t, byte: u8, state: *DemoState) !void {
    switch (byte) {
        'q' => state.running = false,
        ' ' => try clickButton(state),
        '\r', '\n' => try selectCurrent(state),
        0x1B => try handleEscape(fd, state),
        else => {
            if (byte == 'k') try moveMenu(state, -1) else if (byte == 'j') try moveMenu(state, 1);
        },
    }
}

fn handleEscape(fd: posix.fd_t, state: *DemoState) !void {
    const first = readByte(fd) catch return;
    if (first != '[') return;
    const second = readByte(fd) catch return;
    switch (second) {
        'A' => try moveMenu(state, -1),
        'B' => try moveMenu(state, 1),
        'C', 'D' => {},
        '<' => try handleMouseSequence(fd, state),
        else => {},
    }
}

fn handleMouseSequence(fd: posix.fd_t, state: *DemoState) !void {
    var buf: [32]u8 = undefined;
    var idx: usize = 0;
    while (idx < buf.len) {
        const ch = readByte(fd) catch return;
        buf[idx] = ch;
        idx += 1;
        if (ch == 'M' or ch == 'm') break;
    }
    if (idx == 0) return;
    var parts_iter = std.mem.splitScalar(u8, buf[0 .. idx - 1], ';');
    _ = parts_iter.next() orelse return;
    _ = parts_iter.next() orelse return;
    const row_part = parts_iter.next() orelse return;
    if (row_part.len == 0) return;
    const row_value = row_part[0..row_part.len];
    const row_int = std.fmt.parseUnsigned(usize, row_value, 10) catch return;
    if (row_int >= MENU_ROW_BASE and row_int < MENU_ROW_BASE + state.menu_items.len) {
        const idx_target = row_int - MENU_ROW_BASE;
        state.menu_index = if (idx_target >= state.menu_items.len) state.menu_items.len - 1 else idx_target;
        try state.setLog("Mouse moved to {s}", .{state.menu_items[state.menu_index]});
    } else {
        try clickButton(state);
    }
}

fn moveMenu(state: *DemoState, delta: i32) !void {
    if (state.menu_items.len == 0) return;
    const count = state.menu_items.len;
    const idx = @as(i32, @intCast(state.menu_index)) + delta;
    var next = idx;
    if (next < 0) {
        next = @as(i32, @intCast(count)) - 1;
    } else if (next >= @as(i32, @intCast(count))) {
        next = 0;
    }
    state.menu_index = @as(usize, @intCast(next));
    try state.setLog("Moved to {s}", .{state.menu_items[state.menu_index]});
}

fn selectCurrent(state: *DemoState) !void {
    if (state.menu_items.len == 0) return;
    try state.setLog("Selected {s}", .{state.menu_items[state.menu_index]});
}

fn clickButton(state: *DemoState) !void {
    state.button_flash = true;
    try state.setLog("Button clicked!", .{});
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

fn disableRawMode(fd: posix.fd_t, original: posix.termios) void {
    posix.tcsetattr(fd, .NOW, original) catch {};
}

fn readByte(fd: posix.fd_t) !u8 {
    var buf: [1]u8 = undefined;
    while (true) {
        const result = posix.read(fd, &buf) catch |err| return err;
        if (result == 0) continue;
        return buf[0];
    }
}
