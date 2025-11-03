const std = @import("std");

pub const Image = struct {
    width: usize,
    height: usize,
    pixels: []Pixel,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Image {
        const size = width * height;
        const buffer = try allocator.alloc(Pixel, size);
        return Image{
            .width = width,
            .height = height,
            .pixels = buffer,
        };
    }

    pub fn fill(self: *Image, pixel: Pixel) void {
        for (self.pixels) |*p| {
            p.* = pixel;
        }
    }
};

pub const Pixel = struct {
    glyph: []const u8 = " ",
    fg: u24 = 0xFFFFFF,
    bg: u24 = 0x000000,
};
