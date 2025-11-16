const std = @import("std");
const posix = std.posix;

pub fn main() !void {
    var stdout = std.fs.File.stdout();
    try stdout.writeAll("Entering raw mode briefly (press any key)...\n");

    const stdin_fd = posix.STDIN_FILENO;
    const token = try enableRawMode(stdin_fd);
    {
        const byte = try readByte(stdin_fd);
        var buf: [64]u8 = undefined;
        const msg = try std.fmt.bufPrint(&buf, "Captured byte 0x{X:0>2}\n", .{byte});
        try stdout.writeAll(msg);
    }
    disableRawMode(stdin_fd, token);
    try stdout.writeAll("Raw mode disabled — terminal restored.\n");
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
