const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var outer = try zettui.screen.Screen.init(allocator, 40, 6);
    defer allocator.free(outer.image.pixels);
    var inner = try zettui.screen.Screen.init(allocator, 24, 4);
    defer allocator.free(inner.image.pixels);

    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== Screen nested rendering demo ===\n");

    outer.clear(.{ .glyph = " ", .fg = 0xE5E7EB, .bg = 0x1F2933 });
    outer.drawString(2, 1, "Outer screen (40x6)");
    outer.drawString(2, 3, "Embedding child below...");
    try outer.present(stdout);

    inner.clear(.{ .glyph = " ", .fg = 0x000000, .bg = 0xE5E7EB });
    inner.drawString(1, 1, "+ Nested Screen +");
    inner.drawString(1, 2, "Rows copied separately");

    try stdout.writeAll("\n-- Child screen output --\n");
    try inner.present(stdout);
}
