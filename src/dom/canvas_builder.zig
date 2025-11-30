const std = @import("std");
const node = @import("node.zig");

pub const CanvasBuilder = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    fill_char: u8 = ' ',
    buffer: []u8,
    row_views: [][]const u8,

    pub const Coord = struct {
        x: i32,
        y: i32,
    };
    pub const Dimensions = struct {
        width: usize,
        height: usize,
    };

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, fill_char: u8) !CanvasBuilder {
        std.debug.assert(width > 0 and height > 0);
        const total = std.math.mul(usize, width, height) catch @panic("canvas dimensions overflow");
        var builder = CanvasBuilder{
            .allocator = allocator,
            .width = width,
            .height = height,
            .fill_char = fill_char,
            .buffer = try allocator.alloc(u8, total),
            .row_views = try allocator.alloc([]const u8, height),
        };
        builder.clear();
        builder.bindRowViews();
        return builder;
    }

    pub fn dimensions(self: CanvasBuilder) Dimensions {
        return .{ .width = self.width, .height = self.height };
    }

    pub fn deinit(self: *CanvasBuilder) void {
        self.allocator.free(self.buffer);
        self.allocator.free(self.row_views);
        self.* = undefined;
    }

    fn bindRowViews(self: *CanvasBuilder) void {
        var row: usize = 0;
        while (row < self.height) : (row += 1) {
            const start = row * self.width;
            self.row_views[row] = self.buffer[start .. start + self.width];
        }
    }

    pub fn clear(self: *CanvasBuilder) void {
        @memset(self.buffer, self.fill_char);
    }

    pub fn setPixel(self: *CanvasBuilder, coord: Coord, ch: u8) void {
        self.setPixelInternal(coord.x, coord.y, ch);
    }

    fn setPixelInternal(self: *CanvasBuilder, x: i32, y: i32, ch: u8) void {
        if (x < 0 or y < 0) return;
        const ux: usize = @intCast(x);
        const uy: usize = @intCast(y);
        if (ux >= self.width or uy >= self.height) return;
        self.buffer[uy * self.width + ux] = ch;
    }

    pub fn drawLine(self: *CanvasBuilder, start: Coord, end: Coord, ch: u8) void {
        var x0 = start.x;
        var y0 = start.y;
        const x1 = end.x;
        const y1 = end.y;

        const dx = absDiff(x1, x0);
        const sx: i32 = if (x0 < x1) 1 else -1;
        const dy = -absDiff(y1, y0);
        const sy: i32 = if (y0 < y1) 1 else -1;
        var err = dx + dy;

        while (true) {
            self.setPixelInternal(x0, y0, ch);
            if (x0 == x1 and y0 == y1) break;
            const e2 = err * 2;
            if (e2 >= dy) {
                err += dy;
                x0 += sx;
            }
            if (e2 <= dx) {
                err += dx;
                y0 += sy;
            }
        }
    }

    pub fn drawRect(self: *CanvasBuilder, top_left: Coord, width: usize, height: usize, ch: u8) void {
        if (width == 0 or height == 0) return;
        const top_right = Coord{
            .x = top_left.x + @as(i32, @intCast(width - 1)),
            .y = top_left.y,
        };
        const bottom_left = Coord{
            .x = top_left.x,
            .y = top_left.y + @as(i32, @intCast(height - 1)),
        };
        const bottom_right = Coord{
            .x = top_right.x,
            .y = bottom_left.y,
        };
        self.drawLine(top_left, top_right, ch);
        self.drawLine(top_left, bottom_left, ch);
        self.drawLine(bottom_left, bottom_right, ch);
        self.drawLine(top_right, bottom_right, ch);
    }

    pub fn drawCircle(self: *CanvasBuilder, center: Coord, radius: usize, ch: u8) void {
        if (radius == 0) {
            self.setPixel(center, ch);
            return;
        }
        var x: i32 = @intCast(radius);
        var y: i32 = 0;
        var err: i32 = 0;
        while (x >= y) : (y += 1) {
            self.plotCirclePoints(center, x, y, ch);
            err += 1 + 2 * y;
            if (2 * (err - x) + 1 > 0) {
                x -= 1;
                err += 1 - 2 * x;
            }
        }
    }

    pub fn drawEllipse(self: *CanvasBuilder, center: Coord, radius_x: usize, radius_y: usize, ch: u8) void {
        if (radius_x == 0 and radius_y == 0) {
            self.setPixel(center, ch);
            return;
        }
        if (radius_x == 0) {
            self.drawLine(.{ .x = center.x, .y = center.y - @as(i32, @intCast(radius_y)) }, .{ .x = center.x, .y = center.y + @as(i32, @intCast(radius_y)) }, ch);
            return;
        }
        if (radius_y == 0) {
            self.drawLine(.{ .x = center.x - @as(i32, @intCast(radius_x)), .y = center.y }, .{ .x = center.x + @as(i32, @intCast(radius_x)), .y = center.y }, ch);
            return;
        }

        const rx: f64 = @floatFromInt(radius_x);
        const ry: f64 = @floatFromInt(radius_y);
        const rx2 = rx * rx;
        const ry2 = ry * ry;

        var x: f64 = 0;
        var y: f64 = ry;
        var p1: f64 = ry2 - (rx2 * ry) + (0.25 * rx2);

        while (2 * ry2 * x < 2 * rx2 * y) {
            self.plotEllipsePoints(center, @intFromFloat(x), @intFromFloat(y), ch);
            if (p1 < 0) {
                x += 1;
                p1 += 2 * ry2 * x + ry2;
            } else {
                x += 1;
                y -= 1;
                p1 += 2 * ry2 * x - 2 * rx2 * y + ry2;
            }
        }

        var p2: f64 = ry2 * (x + 0.5) * (x + 0.5) + rx2 * (y - 1) * (y - 1) - rx2 * ry2;
        while (y >= 0) : (y -= 1) {
            self.plotEllipsePoints(center, @intFromFloat(x), @intFromFloat(y), ch);
            if (p2 > 0) {
                p2 += rx2 - (2 * rx2 * y);
            } else {
                x += 1;
                p2 += 2 * ry2 * x - 2 * rx2 * y + rx2;
            }
        }
    }

    fn plotCirclePoints(self: *CanvasBuilder, center: Coord, x: i32, y: i32, ch: u8) void {
        const cx = center.x;
        const cy = center.y;
        self.setPixelInternal(cx + x, cy + y, ch);
        self.setPixelInternal(cx - x, cy + y, ch);
        self.setPixelInternal(cx + x, cy - y, ch);
        self.setPixelInternal(cx - x, cy - y, ch);
        self.setPixelInternal(cx + y, cy + x, ch);
        self.setPixelInternal(cx - y, cy + x, ch);
        self.setPixelInternal(cx + y, cy - x, ch);
        self.setPixelInternal(cx - y, cy - x, ch);
    }

    fn plotEllipsePoints(self: *CanvasBuilder, center: Coord, x: i32, y: i32, ch: u8) void {
        const cx = center.x;
        const cy = center.y;
        self.setPixelInternal(cx + x, cy + y, ch);
        self.setPixelInternal(cx - x, cy + y, ch);
        self.setPixelInternal(cx + x, cy - y, ch);
        self.setPixelInternal(cx - x, cy - y, ch);
    }

    pub fn writeText(self: *CanvasBuilder, origin: Coord, text: []const u8) void {
        if (origin.y < 0) return;
        const row: usize = @intCast(origin.y);
        if (row >= self.height) return;
        var col: usize = 0;
        while (col < text.len) : (col += 1) {
            const target_col = origin.x + @as(i32, @intCast(col));
            self.setPixelInternal(target_col, origin.y, text[col]);
        }
    }

    pub fn toNode(self: *CanvasBuilder) node.Node {
        return .{
            .canvas = .{
                .rows = self.row_views,
                .width = self.width,
                .height = self.height,
                .fill_char = self.fill_char,
            },
        };
    }
};

fn absDiff(a: i32, b: i32) i32 {
    return if (a >= b) a - b else b - a;
}

test "CanvasBuilder draws diagonal line" {
    var builder = try CanvasBuilder.init(std.testing.allocator, 4, 4, '.');
    defer builder.deinit();
    builder.drawLine(.{ .x = 0, .y = 0 }, .{ .x = 3, .y = 3 }, '#');
    const canvas_node = builder.toNode();
    const rows = switch (canvas_node) {
        .canvas => |c| c.rows,
        else => unreachable,
    };
    try std.testing.expectEqualStrings("#...", rows[0]);
    try std.testing.expectEqualStrings(".#..", rows[1]);
    try std.testing.expectEqualStrings("..#.", rows[2]);
    try std.testing.expectEqualStrings("...#", rows[3]);
}

test "CanvasBuilder drawRect bounds the canvas" {
    var builder = try CanvasBuilder.init(std.testing.allocator, 6, 4, ' ');
    defer builder.deinit();
    builder.drawRect(.{ .x = 0, .y = 0 }, 6, 4, '*');
    const rows = switch (builder.toNode()) {
        .canvas => |c| c.rows,
        else => unreachable,
    };
    try std.testing.expectEqualStrings("******", rows[0]);
    try std.testing.expectEqualStrings("*    *", rows[1]);
    try std.testing.expectEqualStrings("*    *", rows[2]);
    try std.testing.expectEqualStrings("******", rows[3]);
}

test "CanvasBuilder drawCircle plots symmetric points" {
    var builder = try CanvasBuilder.init(std.testing.allocator, 7, 7, '.');
    defer builder.deinit();
    builder.drawCircle(.{ .x = 3, .y = 3 }, 3, 'o');
    const rows = switch (builder.toNode()) {
        .canvas => |c| c.rows,
        else => unreachable,
    };
    try std.testing.expectEqualStrings("..ooo..", rows[0]);
    try std.testing.expectEqualStrings(".o...o.", rows[1]);
    try std.testing.expectEqualStrings("o.....o", rows[2]);
    try std.testing.expectEqualStrings("o.....o", rows[4]);
    try std.testing.expectEqualStrings(".o...o.", rows[5]);
    try std.testing.expectEqualStrings("..ooo..", rows[6]);
}

test "CanvasBuilder drawEllipse renders oval edges" {
    var builder = try CanvasBuilder.init(std.testing.allocator, 9, 7, '.');
    defer builder.deinit();
    builder.drawEllipse(.{ .x = 4, .y = 3 }, 3, 2, '*');
    const rows = switch (builder.toNode()) {
        .canvas => |c| c.rows,
        else => unreachable,
    };
    try std.testing.expectEqual('*', rows[1][4]);
    try std.testing.expectEqual('*', rows[3][1]);
    try std.testing.expectEqual('*', rows[3][7]);
    try std.testing.expectEqual('*', rows[5][4]);
}
