const std = @import("std");

pub const Color = struct {
    value: u32 = 0,

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{ .value = (@as(u32, r) << 16) | (@as(u32, g) << 8) | @as(u32, b) };
    }

    pub fn blend(a: Color, b: Color, t: f32) Color {
        const inv = 1.0 - std.math.clamp(t, 0.0, 1.0);
        const ar = @as(f32, @floatFromInt((a.value >> 16) & 0xFF));
        const br = @as(f32, @floatFromInt((b.value >> 16) & 0xFF));
        const ag = @as(f32, @floatFromInt((a.value >> 8) & 0xFF));
        const bg = @as(f32, @floatFromInt((b.value >> 8) & 0xFF));
        const ab = @as(f32, @floatFromInt(a.value & 0xFF));
        const bb = @as(f32, @floatFromInt(b.value & 0xFF));

        const r = @as(u8, @intFromFloat(ar * inv + br * t));
        const g = @as(u8, @intFromFloat(ag * inv + bg * t));
        const b_val = @as(u8, @intFromFloat(ab * inv + bb * t));
        return Color.rgb(r, g, b_val);
    }
};

pub const ColorInfo = struct {
    supports_true_color: bool = false,
    palette_size: usize = 16,
};
