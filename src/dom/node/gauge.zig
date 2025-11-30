const std = @import("std");
const common = @import("common.zig");

pub const GaugeOrientation = enum { horizontal, vertical };

pub const Gauge = struct {
    fraction: f32 = 0.0,
    width: usize = 10,
    orientation: GaugeOrientation = .horizontal,
    fill_char: u8 = '#',
    empty_char: u8 = '.',
    show_percentage: bool = false,
    label: []const u8 = "",

    pub fn requirement(self: Gauge) common.Requirement {
        return switch (self.orientation) {
            .horizontal => blk: {
                const body = @max(@as(usize, 3), self.width);
                const label_width: usize = if (self.label.len > 0) self.label.len + 1 else 0;
                const percent_width: usize = if (self.show_percentage) 5 else 0;
                break :blk .{ .min_width = body + label_width + percent_width, .min_height = 1 };
            },
            .vertical => blk: {
                const body = @max(@as(usize, 3), self.width);
                const label_width: usize = if (self.label.len > 0) self.label.len + 1 else 0;
                var label_lines: usize = 0;
                if (self.label.len > 0) label_lines = 1;
                var percent_lines: usize = 0;
                if (self.show_percentage) percent_lines = 1;
                break :blk .{ .min_width = 3 + label_width, .min_height = body + label_lines + percent_lines };
            },
        };
    }

    pub fn render(self: Gauge, ctx: *common.RenderContext) !void {
        switch (self.orientation) {
            .horizontal => try renderHorizontalGauge(self, ctx),
            .vertical => try renderVerticalGauge(self, ctx),
        }
    }
};

fn renderHorizontalGauge(g: Gauge, ctx: *common.RenderContext) !void {
    const total = if (g.width < 3) 3 else g.width;
    const inner: usize = total - 2;
    const clamped = std.math.clamp(g.fraction, 0.0, 1.0);
    const filled: usize = @intFromFloat(@floor(@as(f32, @floatFromInt(inner)) * clamped + 0.0001));
    const empty: usize = inner - filled;

    var buf = std.array_list.Managed(u8).init(std.heap.page_allocator);
    defer buf.deinit();
    try buf.appendSlice("[");
    var i: usize = 0;
    while (i < filled) : (i += 1) try buf.append(g.fill_char);
    i = 0;
    while (i < empty) : (i += 1) try buf.append(g.empty_char);
    try buf.appendSlice("]");

    if (g.show_percentage) {
        var tmp: [16]u8 = undefined;
        const percent: usize = @intFromFloat(@round(clamped * 100.0));
        const pct_text = try std.fmt.bufPrint(&tmp, " {d:0>3}%", .{percent});
        try buf.appendSlice(pct_text);
    }
    if (g.label.len > 0) {
        try buf.appendSlice(" ");
        try buf.appendSlice(g.label);
    }

    if (ctx.drawer != null) {
        try common.ctxDraw(ctx, ctx.origin_x, ctx.origin_y, buf.items);
    } else {
        try common.ctxWrite(ctx, buf.items);
    }
}

fn renderVerticalGauge(g: Gauge, ctx: *common.RenderContext) !void {
    const total = if (g.width < 3) 3 else g.width;
    const clamped = std.math.clamp(g.fraction, 0.0, 1.0);
    const filled: usize = @intFromFloat(@floor(@as(f32, @floatFromInt(total)) * clamped + 0.0001));

    var buf = std.array_list.Managed(u8).init(std.heap.page_allocator);
    defer buf.deinit();

    var row: usize = total;
    while (row > 0) : (row -= 1) {
        const ch = if (row <= filled) g.fill_char else g.empty_char;
        try buf.appendSlice("[");
        try buf.append(ch);
        try buf.appendSlice("]\n");
    }

    if (g.show_percentage) {
        var tmp: [16]u8 = undefined;
        const percent: usize = @intFromFloat(@round(clamped * 100.0));
        const pct_text = try std.fmt.bufPrint(&tmp, "{d:0>3}%", .{percent});
        try buf.appendSlice(pct_text);
        try buf.appendSlice("\n");
    }
    if (g.label.len > 0) {
        try buf.appendSlice(g.label);
        try buf.appendSlice("\n");
    }

    if (ctx.drawer != null) {
        try common.ctxDraw(ctx, ctx.origin_x, ctx.origin_y, buf.items);
    } else {
        try common.ctxWrite(ctx, buf.items);
    }
}
