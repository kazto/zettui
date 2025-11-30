const common = @import("common.zig");
const std = @import("std");

fn blendColor(start: u24, end: u24, t: f32) u24 {
    const clamped = std.math.clamp(t, 0.0, 1.0);
    const sr = (start >> 16) & 0xFF;
    const sg = (start >> 8) & 0xFF;
    const sb = start & 0xFF;
    const er = (end >> 16) & 0xFF;
    const eg = (end >> 8) & 0xFF;
    const eb = end & 0xFF;
    const r = @as(u8, @intFromFloat(@as(f32, @floatFromInt(sr)) * (1.0 - clamped) + @as(f32, @floatFromInt(er)) * clamped));
    const g = @as(u8, @intFromFloat(@as(f32, @floatFromInt(sg)) * (1.0 - clamped) + @as(f32, @floatFromInt(eg)) * clamped));
    const b = @as(u8, @intFromFloat(@as(f32, @floatFromInt(sb)) * (1.0 - clamped) + @as(f32, @floatFromInt(eb)) * clamped));
    return (@as(u24, r) << 16) | (@as(u24, g) << 8) | b;
}

pub const GradientText = struct {
    text: []const u8,
    start_color: u24,
    end_color: u24,

    pub fn requirement(self: GradientText) common.Requirement {
        return .{ .min_width = self.text.len, .min_height = if (self.text.len == 0) 0 else 1 };
    }

    pub fn render(self: GradientText, ctx: *common.RenderContext) !void {
        if (self.text.len == 0) return;
        const saved = ctx.style;
        const total = self.text.len;
        var idx: usize = 0;
        while (idx < total) : (idx += 1) {
            const ratio = if (total <= 1) 0 else @as(f32, @floatFromInt(idx)) / @as(f32, @floatFromInt(total - 1));
            const blended = blendColor(self.start_color, self.end_color, ratio);
            const next_style = common.mergeStyles(saved, .{ .fg = blended });
            ctx.style = next_style;
            if (ctx.drawer != null) {
                try common.ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(idx)), ctx.origin_y, self.text[idx .. idx + 1]);
            } else {
                try common.applyAnsiStyle(ctx, next_style);
                try common.ctxWrite(ctx, self.text[idx .. idx + 1]);
            }
        }
        ctx.style = saved;
        if (ctx.drawer == null) {
            try common.applyAnsiStyle(ctx, saved);
        }
    }
};
