const std = @import("std");
const common = @import("common.zig");

pub const Graph = struct {
    values: []const f32 = &[_]f32{},
    width: usize = 0,
    height: usize = 4,
    min_value: ?f32 = null,
    max_value: ?f32 = null,
    fill_char: u8 = '#',
    empty_char: u8 = ' ',

    pub const Dimensions = struct { width: usize, height: usize };
    const Extents = struct { min: f32, max: f32 };

    pub fn dimensions(self: Graph) Dimensions {
        const raw_width = if (self.width > 0) self.width else self.values.len;
        const w = if (raw_width == 0) 1 else raw_width;
        const h = if (self.height == 0) 1 else self.height;
        return .{ .width = w, .height = h };
    }

    pub fn requirement(self: Graph) common.Requirement {
        const dims = self.dimensions();
        return .{ .min_width = dims.width, .min_height = dims.height };
    }

    fn extents(self: Graph) Extents {
        var min_val: f32 = if (self.values.len > 0) self.values[0] else 0.0;
        var max_val: f32 = min_val;
        if (self.values.len > 0) {
            for (self.values[1..]) |val| {
                min_val = @min(min_val, val);
                max_val = @max(max_val, val);
            }
        }
        if (self.min_value) |mv| min_val = mv;
        if (self.max_value) |mv| max_val = mv;
        if (max_val <= min_val) {
            max_val = min_val + 1.0;
        }
        return .{ .min = min_val, .max = max_val };
    }

    fn sampleValue(self: Graph, column: usize, width: usize) f32 {
        if (self.values.len == 0) return 0.0;
        if (self.values.len == width) {
            return self.values[@min(column, self.values.len - 1)];
        }
        const scaled = column * self.values.len;
        const idx = @min(self.values.len - 1, scaled / width);
        return self.values[idx];
    }

    pub fn render(self: Graph, ctx: *common.RenderContext) anyerror!void {
        const dims = self.dimensions();
        const width = dims.width;
        const height = dims.height;
        const ext = self.extents();
        const range = ext.max - ext.min;
        var row: usize = 0;
        while (row < height) : (row += 1) {
            var col: usize = 0;
            while (col < width) : (col += 1) {
                const value = self.sampleValue(col, width);
                const normalized = if (range <= 0.0)
                    0.0
                else
                    std.math.clamp((value - ext.min) / range, 0.0, 1.0);
                var filled_rows: usize = @intFromFloat(@round(normalized * @as(f32, @floatFromInt(height))));
                if (filled_rows > height) filled_rows = height;
                const threshold = height - row;
                const draw_fill = filled_rows >= threshold and filled_rows > 0;
                const ch = if (draw_fill) self.fill_char else self.empty_char;
                if (ctx.drawer != null) {
                    const cell = [1]u8{ch};
                    try common.ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(col)), ctx.origin_y + @as(i32, @intCast(row)), cell[0..]);
                } else {
                    const cell = [1]u8{ch};
                    try common.ctxWrite(ctx, cell[0..]);
                }
            }
            if (ctx.drawer == null) {
                try common.ctxWrite(ctx, "\n");
            }
        }
    }
};
