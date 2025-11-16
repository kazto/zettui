const std = @import("std");
const posix = std.posix;

const ArrowKey = enum { up, down, left, right };

const InputEvent = union(enum) {
    character: u8,
    arrow: ArrowKey,
    escape: void,
    control: u8,
};

pub fn main() !void {
    var stdout = std.fs.File.stdout();
    try stdout.writeAll("Press keys to see their decoded representation. Press 'q' or Ctrl+C to exit.\n");

    const stdin_fd = posix.STDIN_FILENO;
    const token = try enableRawMode(stdin_fd);
    defer disableRawMode(stdin_fd, token);

    while (true) {
        const event = try readEvent(stdin_fd);
        switch (event) {
            .character => |ch| {
                try logCharacter(&stdout, ch);
                if (ch == 'q') break;
            },
            .arrow => |arrow| try logArrow(&stdout, arrow),
            .escape => try stdout.writeAll("ESC sequence (no mapping)\n"),
            .control => |code| {
                if (code == 0x03) {
                    try stdout.writeAll("Ctrl+C detected, exiting...\n");
                    break;
                }
                try logControl(&stdout, code);
            },
        }
    }
}

fn logCharacter(stdout: *std.fs.File, ch: u8) !void {
    var buf: [64]u8 = undefined;
    const printable = if (ch >= 32 and ch <= 126) try std.fmt.bufPrint(&buf, "printable '{c}' (0x{X:0>2})\n", .{ ch, ch }) else try std.fmt.bufPrint(&buf, "byte 0x{X:0>2}\n", .{ch});
    try stdout.writeAll(printable);
}

fn logArrow(stdout: *std.fs.File, arrow: ArrowKey) !void {
    const name = switch (arrow) {
        .up => "ArrowUp",
        .down => "ArrowDown",
        .left => "ArrowLeft",
        .right => "ArrowRight",
    };
    var buf: [64]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "special key: {s}\n", .{name});
    try stdout.writeAll(msg);
}

fn logControl(stdout: *std.fs.File, code: u8) !void {
    var buf: [64]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "control byte 0x{X:0>2}\n", .{code});
    try stdout.writeAll(msg);
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
