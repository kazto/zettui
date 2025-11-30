const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== ScreenInteractive nested screen demo ===\n");

    var interactive = try zettui.screen.ScreenInteractive.init(gpa, 44, 8);
    defer interactive.deinit();

    try drawOuter(interactive.screen(), &stdout, 0);

    {
        var guard = interactive.nestedScreen();
        try drawNested(interactive.screen(), &stdout, interactive.nested_depth);
        guard.restore();
    }

    try drawOuter(interactive.screen(), &stdout, interactive.nested_depth);
}

fn drawOuter(screen: *zettui.screen.Screen, stdout: *std.fs.File, depth: usize) !void {
    screen.clear(.{ .glyph = " ", .fg = 0xE5E7EB, .bg = 0x111827 });
    screen.drawString(2, 1, "Outer surface (parent)");
    screen.drawString(2, 3, "Depth (after nested restore):");
    var buf: [32]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "{d}", .{depth});
    screen.drawString(4, 4, msg);
    try screen.present(stdout.*);
    try stdout.writeAll("\n");
}

fn drawNested(screen: *zettui.screen.Screen, stdout: *std.fs.File, depth: usize) !void {
    screen.clear(.{ .glyph = " ", .fg = 0x111827, .bg = 0xE5E7EB });
    screen.drawString(2, 1, "Nested screen guard in effect");
    var buf: [32]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "Nested depth: {d}", .{depth});
    screen.drawString(2, 3, msg);
    try screen.present(stdout.*);
    try stdout.writeAll("\n");
}
