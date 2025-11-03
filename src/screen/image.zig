const std = @import("std");

const glyph_table = initGlyphTable();

fn initGlyphTable() [256][1]u8 {
    var table: [256][1]u8 = undefined;
    var index: usize = 0;
    while (index < table.len) : (index += 1) {
        table[index] = .{@as(u8, @intCast(index))};
    }
    return table;
}

pub fn glyphFromByte(byte: u8) []const u8 {
    return glyph_table[@as(usize, byte)][0..];
}

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
    glyph: []const u8 = glyphFromByte(' '),
    fg: u24 = 0xFFFFFF,
    bg: u24 = 0x000000,
};
