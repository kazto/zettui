const std = @import("std");
const image_mod = @import("image.zig");

pub const Pixel = image_mod.Pixel;

pub const Box = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
};

pub const Screen = struct {
    image: image_mod.Image,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Screen {
        return Screen{ .image = try image_mod.Image.init(allocator, width, height) };
    }

    pub fn clear(self: *Screen, pixel: Pixel) void {
        self.image.fill(pixel);
    }

    pub fn drawString(self: *Screen, x: usize, y: usize, text: []const u8) void {
        const width = self.image.width;
        for (text, 0..) |char_byte, idx| {
            const offset = y * width + x + idx;
            if (offset >= self.image.pixels.len) break;
            self.image.pixels[offset].glyph = image_mod.glyphFromByte(char_byte);
        }
    }

    pub fn present(self: *Screen, writer: anytype) !void {
        var row: usize = 0;
        while (row < self.image.height) : (row += 1) {
            const start = row * self.image.width;
            const end = start + self.image.width;
            for (self.image.pixels[start..end]) |pixel| {
                try writer.writeAll(pixel.glyph);
            }
            try writer.writeAll("\n");
        }
    }
};

test "drawString writes glyphs and present flushes rows" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var screen = try Screen.init(allocator, 4, 2);
    defer allocator.free(screen.image.pixels);

    screen.clear(.{
        .glyph = " ",
        .fg = 0x000000,
        .bg = 0x000000,
    });
    screen.drawString(1, 0, "hi");

    var buffer = std.array_list.Managed(u8).init(allocator);
    defer buffer.deinit();
    try screen.present(buffer.writer());

    try std.testing.expectEqualStrings(" hi \n    \n", buffer.items);
}
