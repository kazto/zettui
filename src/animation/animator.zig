const std = @import("std");

pub fn easeLinear(t: f32) f32 {
    return std.math.clamp(t, 0.0, 1.0);
}

pub fn easeInOutQuad(t: f32) f32 {
    const clamped = easeLinear(t);
    if (clamped < 0.5) {
        return 2.0 * clamped * clamped;
    }
    const inv = 1.0 - clamped;
    return 1.0 - 2.0 * inv * inv;
}

pub fn easeOutBack(t: f32) f32 {
    const clamped = easeLinear(t);
    const c1: f32 = 1.70158;
    const c3 = c1 + 1.0;
    return 1.0 + c3 * std.math.pow(f32, clamped - 1.0, 3) + c1 * std.math.pow(f32, clamped - 1.0, 2);
}

pub const Animator = struct {
    duration: f32,
    elapsed: f32 = 0,

    pub fn reset(self: *Animator) void {
        self.elapsed = 0;
    }

    pub fn advance(self: *Animator, delta: f32) void {
        self.elapsed += delta;
        if (self.elapsed > self.duration) self.elapsed = self.duration;
    }

    pub fn value(self: Animator, easing: fn (f32) f32) f32 {
        if (self.duration == 0) return 1.0;
        const progress = std.math.clamp(self.elapsed / self.duration, 0.0, 1.0);
        return easing(progress);
    }
};

test "animator clamps progression" {
    var anim = Animator{ .duration = 1.0 };
    anim.advance(0.25);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), anim.value(easeInOutQuad), 0.5);
    anim.advance(2.0);
    try std.testing.expectEqual(@as(f32, 1.0), anim.value(easeLinear));
}
