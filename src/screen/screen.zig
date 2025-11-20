const std = @import("std");
const image_mod = @import("image.zig");

pub const Pixel = image_mod.Pixel;

pub const Box = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,

    pub fn right(self: Box) i32 {
        return self.x + @as(i32, @intCast(self.width));
    }

    pub fn bottom(self: Box) i32 {
        return self.y + @as(i32, @intCast(self.height));
    }

    pub fn contains(self: Box, px: i32, py: i32) bool {
        return px >= self.x and py >= self.y and px < self.right() and py < self.bottom();
    }

    pub fn intersects(self: Box, other: Box) bool {
        return self.x < other.right() and other.x < self.right() and self.y < other.bottom() and other.y < self.bottom();
    }

    pub fn intersection(self: Box, other: Box) ?Box {
        const nx: i32 = @max(self.x, other.x);
        const ny: i32 = @max(self.y, other.y);
        const nr: i32 = @min(self.right(), other.right());
        const nb: i32 = @min(self.bottom(), other.bottom());
        if (nr <= nx or nb <= ny) return null;
        return Box{
            .x = nx,
            .y = ny,
            .width = @as(u32, @intCast(nr - nx)),
            .height = @as(u32, @intCast(nb - ny)),
        };
    }

    pub fn merge(self: Box, other: Box) Box {
        const nx: i32 = @min(self.x, other.x);
        const ny: i32 = @min(self.y, other.y);
        const nr: i32 = @max(self.right(), other.right());
        const nb: i32 = @max(self.bottom(), other.bottom());
        return Box{
            .x = nx,
            .y = ny,
            .width = @as(u32, @intCast(nr - nx)),
            .height = @as(u32, @intCast(nb - ny)),
        };
    }

    pub fn inset(self: Box, dx: i32, dy: i32) Box {
        const new_x = self.x + dx;
        const new_y = self.y + dy;
        const w_i32: i32 = @as(i32, @intCast(self.width)) - dx * 2;
        const h_i32: i32 = @as(i32, @intCast(self.height)) - dy * 2;
        return Box{
            .x = new_x,
            .y = new_y,
            .width = @as(u32, @intCast(@max(0, w_i32))),
            .height = @as(u32, @intCast(@max(0, h_i32))),
        };
    }

    pub fn outset(self: Box, dx: i32, dy: i32) Box {
        return self.inset(-dx, -dy);
    }

    pub fn translate(self: Box, dx: i32, dy: i32) Box {
        return Box{
            .x = self.x + dx,
            .y = self.y + dy,
            .width = self.width,
            .height = self.height,
        };
    }
};

pub const Screen = struct {
    image: image_mod.Image,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Screen {
        return Screen{ .image = try image_mod.Image.init(allocator, width, height) };
    }

    pub fn clear(self: *Screen, pixel: Pixel) void {
        self.image.fill(pixel);
    }

    pub fn drawString(self: *Screen, x: usize, y: usize, text: []const u8, style: Pixel) void {
        const width = self.image.width;
        for (text, 0..) |char_byte, idx| {
            const offset = y * width + x + idx;
            if (offset >= self.image.pixels.len) break;
            self.image.pixels[offset].glyph = image_mod.glyphFromByte(char_byte);
            self.image.pixels[offset].fg = style.fg;
            self.image.pixels[offset].bg = style.bg;
            self.image.pixels[offset].style = style.style;
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

test "box geometry helpers" {
    const a = Box{ .x = 2, .y = 3, .width = 5, .height = 4 }; // covers [2,7) x [3,7)
    try std.testing.expect(a.contains(2, 3));
    try std.testing.expect(a.contains(6, 6));
    try std.testing.expect(!a.contains(7, 6)); // right edge exclusive
    try std.testing.expect(!a.contains(6, 7)); // bottom edge exclusive

    const b = Box{ .x = 5, .y = 5, .width = 3, .height = 3 }; // overlaps with a
    try std.testing.expect(a.intersects(b));

    const c = Box{ .x = -10, .y = -10, .width = 2, .height = 2 }; // disjoint
    try std.testing.expect(!a.intersects(c));

    const isect = a.intersection(b).?;
    try std.testing.expectEqual(@as(i32, 5), isect.x);
    try std.testing.expectEqual(@as(i32, 5), isect.y);
    try std.testing.expectEqual(@as(u32, 2), isect.width);
    try std.testing.expectEqual(@as(u32, 2), isect.height);

    const uni = a.merge(b);
    try std.testing.expectEqual(@as(i32, 2), uni.x);
    try std.testing.expectEqual(@as(i32, 3), uni.y);
    try std.testing.expectEqual(@as(u32, 6), uni.width); // right 8 - left 2 = 6
    try std.testing.expectEqual(@as(u32, 5), uni.height); // bottom 8 - top 3 = 5

    const inset_box = a.inset(1, 2);
    try std.testing.expectEqual(@as(i32, 3), inset_box.x);
    try std.testing.expectEqual(@as(i32, 5), inset_box.y);
    try std.testing.expectEqual(@as(u32, 3), inset_box.width);
    try std.testing.expectEqual(@as(u32, 0), inset_box.height); // clamped to 0

    const outset_box = a.outset(2, 1);
    try std.testing.expectEqual(@as(i32, 0), outset_box.x);
    try std.testing.expectEqual(@as(i32, 2), outset_box.y);
    try std.testing.expectEqual(@as(u32, 9), outset_box.width);
    try std.testing.expectEqual(@as(u32, 6), outset_box.height);

    const moved = a.translate(-2, 10);
    try std.testing.expectEqual(@as(i32, 0), moved.x);
    try std.testing.expectEqual(@as(i32, 13), moved.y);
    try std.testing.expectEqual(a.width, moved.width);
    try std.testing.expectEqual(a.height, moved.height);
}

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
        .style = 0,
    });
    screen.drawString(1, 0, "hi", .{});

    var buffer = std.array_list.Managed(u8).init(allocator);
    defer buffer.deinit();
    try screen.present(buffer.writer());

    try std.testing.expectEqualStrings(" hi \n    \n", buffer.items);
}
