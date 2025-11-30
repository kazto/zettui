const std = @import("std");
const posix = std.posix;
const zettui = @import("zettui");

pub fn main() !void {
    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== ScreenInteractive restored IO demo ===\n");
    try stdout.writeAll("A guard temporarily yields control so we can touch the terminal directly.\n");

    const gpa = std.heap.page_allocator;
    var interactive = try zettui.screen.ScreenInteractive.init(gpa, 32, 4);
    defer interactive.deinit();

    const stdin_fd = posix.STDIN_FILENO;
    const Restore = struct {
        fn cb(ctx: ?*anyopaque) void {
            const out = @as(*std.fs.File, @ptrCast(@alignCast(ctx.?)));
            _ = out.writeAll("Restored IO callback fired.\n") catch {};
        }
    };

    var guard = interactive.restoredIo(Restore.cb, @as(?*anyopaque, @ptrCast(&stdout)));
    try stdout.writeAll("Entering raw mode (press any key)...\n");
    const token = try enableRawMode(stdin_fd);
    const byte = try readByte(stdin_fd);
    disableRawMode(stdin_fd, token);
    try stdout.writeAll("Raw mode disabled via guard scope.\n");
    var buf: [64]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "Captured byte 0x{X:0>2}\n", .{byte});
    try stdout.writeAll(msg);
    guard.restore();
    try stdout.writeAll("Guard restored; depth back to normal.\n");
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
