const common = @import("common.zig");

pub fn GridBox(comptime Node: type) type {
    return struct {
        cells: [][]const Node = &[_][]const Node{},
        column_gap: usize = 1,
        row_gap: usize = 0,
        owned_cells: ?[][]Node = null,

        pub fn requirement(self: @This()) common.Requirement {
            var max_width: usize = 0;
            var total_height: usize = 0;
            var row_index: usize = 0;
            for (self.cells) |row| {
                var row_width: usize = 0;
                var row_height: usize = 0;
                for (row) |cell| {
                    const req = cell.computeRequirement();
                    row_width += req.min_width;
                    row_height = @max(row_height, req.min_height);
                }
                if (row.len > 1) {
                    row_width += self.column_gap * (row.len - 1);
                }
                max_width = @max(max_width, row_width);
                total_height += row_height;
                if (row_index + 1 < self.cells.len) {
                    total_height += self.row_gap;
                }
                row_index += 1;
            }
            return .{ .min_width = max_width, .min_height = total_height };
        }

        pub fn render(self: @This(), ctx: *common.RenderContext) anyerror!void {
            var y = ctx.origin_y;
            for (self.cells, 0..) |row, row_idx| {
                var x = ctx.origin_x;
                var row_height: usize = 0;
                for (row) |cell| {
                    const req = cell.computeRequirement();
                    var child_ctx = ctx.*;
                    child_ctx.origin_x = x;
                    child_ctx.origin_y = y;
                    try cell.render(&child_ctx);
                    x += @as(i32, @intCast(req.min_width + self.column_gap));
                    row_height = @max(row_height, req.min_height);
                }
                if (row_idx + 1 < self.cells.len) {
                    y += @as(i32, @intCast(row_height + self.row_gap));
                }
            }
        }
    };
}
