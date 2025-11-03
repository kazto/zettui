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
            self.image.pixels[offset].glyph = &[1]u8{char_byte};
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
