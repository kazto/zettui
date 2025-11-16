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

pub const GradientStop = struct {
    position: f32,
    color: Color,
};

pub const Gradient = struct {
    stops: []const GradientStop,

    pub fn init(stops: []const GradientStop) Gradient {
        std.debug.assert(stops.len >= 2);
        return Gradient{ .stops = stops };
    }

    pub fn colorAt(self: Gradient, position: f32) Color {
        const clamped = std.math.clamp(position, 0.0, 1.0);
        var prev = self.stops[0];
        for (self.stops[1..]) |stop| {
            if (clamped <= stop.position) {
                const span = stop.position - prev.position;
                const local = if (span <= 0.0) 0.0 else (clamped - prev.position) / span;
                return Color.blend(prev.color, stop.color, local);
            }
            prev = stop;
        }
        return self.stops[self.stops.len - 1].color;
    }

    pub fn fill(self: Gradient, buffer: []Color) void {
        if (buffer.len == 0) return;
        if (buffer.len == 1) {
            buffer[0] = self.colorAt(0.0);
            return;
        }
        const denom = @as(f32, @floatFromInt(buffer.len - 1));
        for (buffer, 0..) |*slot, idx| {
            const position = @as(f32, @floatFromInt(idx)) / denom;
            slot.* = self.colorAt(position);
        }
    }

    pub fn generate(self: Gradient, allocator: std.mem.Allocator, steps: usize) ![]Color {
        std.debug.assert(steps > 0);
        const buf = try allocator.alloc(Color, steps);
        errdefer allocator.free(buf);
        self.fill(buf);
        return buf;
    }
};

test "blend mixes RGB channels linearly" {
    const red = Color.rgb(255, 0, 0);
    const blue = Color.rgb(0, 0, 255);
    const purple = Color.blend(red, blue, 0.5);
    try std.testing.expectEqual(Color.rgb(127, 0, 127).value, purple.value);
}

test "gradient colorAt interpolates between stops" {
    const gradient = Gradient.init(&[_]GradientStop{
        .{ .position = 0.0, .color = Color.rgb(0, 0, 0) },
        .{ .position = 1.0, .color = Color.rgb(255, 255, 255) },
    });
    const mid = gradient.colorAt(0.5);
    try std.testing.expectEqual(Color.rgb(127, 127, 127).value, mid.value);
}

test "gradient fill distributes colors across buffer" {
    const gradient = Gradient.init(&[_]GradientStop{
        .{ .position = 0.0, .color = Color.rgb(255, 0, 0) },
        .{ .position = 0.5, .color = Color.rgb(0, 0, 255) },
        .{ .position = 1.0, .color = Color.rgb(0, 255, 0) },
    });
    var colors: [3]Color = undefined;
    gradient.fill(colors[0..]);
    try std.testing.expectEqual(Color.rgb(255, 0, 0).value, colors[0].value);
    try std.testing.expectEqual(Color.rgb(0, 0, 255).value, colors[1].value);
    try std.testing.expectEqual(Color.rgb(0, 255, 0).value, colors[2].value);
}
