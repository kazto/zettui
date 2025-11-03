const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var screen = try zettui.screen.Screen.init(allocator, 32, 4);
    defer allocator.free(screen.image.pixels);

    screen.clear(.{
        .glyph = " ",
        .fg = 0xFFFFFF,
        .bg = 0x000000,
    });

    screen.drawString(2, 1, "Zettui demo");

    const stdout = std.fs.File.stdout();
    try screen.present(stdout);
}
