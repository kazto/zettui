const common = @import("common.zig");

pub const Canvas = struct {
    rows: []const []const u8 = &[_][]const u8{},
    width: usize = 0,
    height: usize = 0,
    fill_char: u8 = ' ',

    const Dimensions = struct { width: usize, height: usize };

    pub fn dimensions(self: Canvas) Dimensions {
        var w = self.width;
        for (self.rows) |row| {
            w = @max(w, row.len);
        }
        const h = if (self.height > 0) self.height else self.rows.len;
        return .{ .width = w, .height = h };
    }

    pub fn requirement(self: Canvas) common.Requirement {
        const dims = self.dimensions();
        return .{ .min_width = dims.width, .min_height = dims.height };
    }

    pub fn render(self: Canvas, ctx: *common.RenderContext) anyerror!void {
        const dims = self.dimensions();
        if (dims.height == 0 and dims.width == 0) return;
        var row_idx: usize = 0;
        while (row_idx < dims.height) : (row_idx += 1) {
            const row_data = if (row_idx < self.rows.len) self.rows[row_idx] else "";
            if (ctx.drawer != null) {
                var col: usize = 0;
                while (col < dims.width) : (col += 1) {
                    const ch = if (col < row_data.len) row_data[col] else self.fill_char;
                    const cell = [1]u8{ch};
                    try common.ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(col)), ctx.origin_y + @as(i32, @intCast(row_idx)), cell[0..]);
                }
            } else {
                if (dims.width == 0) {
                    try common.ctxWrite(ctx, "\n");
                    continue;
                }
                var col: usize = 0;
                while (col < dims.width) : (col += 1) {
                    const ch = if (col < row_data.len) row_data[col] else self.fill_char;
                    const cell = [1]u8{ch};
                    try common.ctxWrite(ctx, cell[0..]);
                }
                try common.ctxWrite(ctx, "\n");
            }
        }
    }
};
