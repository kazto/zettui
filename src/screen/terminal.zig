const std = @import("std");

pub const TerminalInfo = struct {
    width: usize = 0,
    height: usize = 0,
    supports_true_color: bool = false,
    max_colors: usize = 16,
};

pub const Terminal = struct {
    pub fn init() Terminal {
        return Terminal{};
    }

    pub fn queryInfo(_: Terminal) TerminalInfo {
        return TerminalInfo{
            .width = 80,
            .height = 24,
            .supports_true_color = true,
            .max_colors = 256,
        };
    }
};

/// ANSI escape sequence utilities for terminal control
pub const Cursor = struct {
    /// Hide cursor: ESC[?25l
    pub const hide = "\x1b[?25l";
    /// Show cursor: ESC[?25h
    pub const show = "\x1b[?25h";
    /// Move cursor to home position (1,1): ESC[H
    pub const home = "\x1b[H";

    /// Move cursor to specific position (1-indexed)
    pub fn moveTo(buf: []u8, row: usize, col: usize) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[{d};{d}H", .{ row, col }) catch return "";
        return buf[0..len.len];
    }

    /// Move cursor up by n lines
    pub fn up(buf: []u8, n: usize) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[{d}A", .{n}) catch return "";
        return buf[0..len.len];
    }

    /// Move cursor down by n lines
    pub fn down(buf: []u8, n: usize) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[{d}B", .{n}) catch return "";
        return buf[0..len.len];
    }

    /// Move cursor right by n columns
    pub fn right(buf: []u8, n: usize) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[{d}C", .{n}) catch return "";
        return buf[0..len.len];
    }

    /// Move cursor left by n columns
    pub fn left(buf: []u8, n: usize) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[{d}D", .{n}) catch return "";
        return buf[0..len.len];
    }

    /// Save cursor position
    pub const save = "\x1b[s";
    /// Restore cursor position
    pub const restore = "\x1b[u";
};

/// Screen control sequences
pub const Screen = struct {
    /// Clear entire screen: ESC[2J
    pub const clear = "\x1b[2J";
    /// Clear screen and move to home: ESC[2J ESC[H
    pub const clearAndHome = "\x1b[2J\x1b[H";
    /// Clear from cursor to end of screen: ESC[0J
    pub const clearToEnd = "\x1b[0J";
    /// Clear from cursor to beginning of screen: ESC[1J
    pub const clearToBegin = "\x1b[1J";
    /// Clear current line: ESC[2K
    pub const clearLine = "\x1b[2K";
    /// Clear from cursor to end of line: ESC[0K
    pub const clearLineToEnd = "\x1b[0K";
    /// Clear from cursor to beginning of line: ESC[1K
    pub const clearLineToBegin = "\x1b[1K";

    /// Enter alternate screen buffer
    pub const enterAlternate = "\x1b[?1049h";
    /// Exit alternate screen buffer
    pub const exitAlternate = "\x1b[?1049l";
};

/// Text style sequences
pub const Style = struct {
    /// Reset all attributes: ESC[0m
    pub const reset = "\x1b[0m";
    /// Bold: ESC[1m
    pub const bold = "\x1b[1m";
    /// Dim: ESC[2m
    pub const dim = "\x1b[2m";
    /// Italic: ESC[3m
    pub const italic = "\x1b[3m";
    /// Underline: ESC[4m
    pub const underline = "\x1b[4m";
    /// Blink: ESC[5m
    pub const blink = "\x1b[5m";
    /// Reverse video: ESC[7m
    pub const reverse = "\x1b[7m";
    /// Hidden: ESC[8m
    pub const hidden = "\x1b[8m";
    /// Strikethrough: ESC[9m
    pub const strikethrough = "\x1b[9m";

    /// Set foreground color (8-color)
    pub fn fg(buf: []u8, color_code: u8) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[{d}m", .{30 + color_code}) catch return "";
        return buf[0..len.len];
    }

    /// Set background color (8-color)
    pub fn bg(buf: []u8, color_code: u8) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[{d}m", .{40 + color_code}) catch return "";
        return buf[0..len.len];
    }

    /// Set foreground color (256-color)
    pub fn fg256(buf: []u8, color_code: u8) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[38;5;{d}m", .{color_code}) catch return "";
        return buf[0..len.len];
    }

    /// Set background color (256-color)
    pub fn bg256(buf: []u8, color_code: u8) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[48;5;{d}m", .{color_code}) catch return "";
        return buf[0..len.len];
    }

    /// Set foreground color (24-bit RGB)
    pub fn fgRgb(buf: []u8, r: u8, g: u8, b: u8) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[38;2;{d};{d};{d}m", .{ r, g, b }) catch return "";
        return buf[0..len.len];
    }

    /// Set background color (24-bit RGB)
    pub fn bgRgb(buf: []u8, r: u8, g: u8, b: u8) []const u8 {
        const len = std.fmt.bufPrint(buf, "\x1b[48;2;{d};{d};{d}m", .{ r, g, b }) catch return "";
        return buf[0..len.len];
    }

    /// Basic color codes for fg/bg functions
    pub const Color = struct {
        pub const black = 0;
        pub const red = 1;
        pub const green = 2;
        pub const yellow = 3;
        pub const blue = 4;
        pub const magenta = 5;
        pub const cyan = 6;
        pub const white = 7;
    };
};

/// Convenience writer that wraps a file and provides terminal control methods
pub const TerminalWriter = struct {
    file: std.fs.File,

    pub fn init(file: std.fs.File) TerminalWriter {
        return .{ .file = file };
    }

    pub fn stdout() TerminalWriter {
        return init(std.fs.File.stdout());
    }

    pub fn write(self: TerminalWriter, bytes: []const u8) !void {
        try self.file.writeAll(bytes);
    }

    // Cursor control
    pub fn hideCursor(self: TerminalWriter) !void {
        try self.write(Cursor.hide);
    }

    pub fn showCursor(self: TerminalWriter) !void {
        try self.write(Cursor.show);
    }

    pub fn cursorHome(self: TerminalWriter) !void {
        try self.write(Cursor.home);
    }

    pub fn cursorMoveTo(self: TerminalWriter, row: usize, col: usize) !void {
        var buf: [32]u8 = undefined;
        try self.write(Cursor.moveTo(&buf, row, col));
    }

    pub fn saveCursor(self: TerminalWriter) !void {
        try self.write(Cursor.save);
    }

    pub fn restoreCursor(self: TerminalWriter) !void {
        try self.write(Cursor.restore);
    }

    // Screen control
    pub fn clearScreen(self: TerminalWriter) !void {
        try self.write(Screen.clear);
    }

    pub fn clearScreenAndHome(self: TerminalWriter) !void {
        try self.write(Screen.clearAndHome);
    }

    pub fn clearLine(self: TerminalWriter) !void {
        try self.write(Screen.clearLine);
    }

    pub fn enterAlternateScreen(self: TerminalWriter) !void {
        try self.write(Screen.enterAlternate);
    }

    pub fn exitAlternateScreen(self: TerminalWriter) !void {
        try self.write(Screen.exitAlternate);
    }

    // Style control
    pub fn resetStyle(self: TerminalWriter) !void {
        try self.write(Style.reset);
    }

    pub fn setBold(self: TerminalWriter) !void {
        try self.write(Style.bold);
    }

    pub fn setUnderline(self: TerminalWriter) !void {
        try self.write(Style.underline);
    }

    pub fn setFgColor(self: TerminalWriter, color_code: u8) !void {
        var buf: [16]u8 = undefined;
        try self.write(Style.fg(&buf, color_code));
    }

    pub fn setBgColor(self: TerminalWriter, color_code: u8) !void {
        var buf: [16]u8 = undefined;
        try self.write(Style.bg(&buf, color_code));
    }

    pub fn setFgRgb(self: TerminalWriter, r: u8, g: u8, b: u8) !void {
        var buf: [32]u8 = undefined;
        try self.write(Style.fgRgb(&buf, r, g, b));
    }

    pub fn setBgRgb(self: TerminalWriter, r: u8, g: u8, b: u8) !void {
        var buf: [32]u8 = undefined;
        try self.write(Style.bgRgb(&buf, r, g, b));
    }
};

test "cursor sequences" {
    const testing = std.testing;
    try testing.expectEqualStrings("\x1b[?25l", Cursor.hide);
    try testing.expectEqualStrings("\x1b[?25h", Cursor.show);
    try testing.expectEqualStrings("\x1b[H", Cursor.home);

    var buf: [32]u8 = undefined;
    try testing.expectEqualStrings("\x1b[5;10H", Cursor.moveTo(&buf, 5, 10));
}

test "screen sequences" {
    const testing = std.testing;
    try testing.expectEqualStrings("\x1b[2J", Screen.clear);
    try testing.expectEqualStrings("\x1b[2J\x1b[H", Screen.clearAndHome);
}

test "style sequences" {
    const testing = std.testing;
    try testing.expectEqualStrings("\x1b[0m", Style.reset);
    try testing.expectEqualStrings("\x1b[1m", Style.bold);

    var buf: [32]u8 = undefined;
    try testing.expectEqualStrings("\x1b[31m", Style.fg(&buf, Style.Color.red));
    try testing.expectEqualStrings("\x1b[38;2;255;128;64m", Style.fgRgb(&buf, 255, 128, 64));
}
