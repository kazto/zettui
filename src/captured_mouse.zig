const std = @import("std");
const events = @import("component/events.zig");

pub const CapturedMouse = struct {
    active: bool = false,
    position: events.MousePosition = .{},

    pub fn capture(self: *CapturedMouse, pos: events.MousePosition) void {
        self.active = true;
        self.position = pos;
    }

    pub fn move(self: *CapturedMouse, pos: events.MousePosition) void {
        self.position = pos;
    }

    pub fn release(self: *CapturedMouse) void {
        self.active = false;
    }

    pub fn captureGuard(self: *CapturedMouse, pos: events.MousePosition) CaptureGuard {
        self.capture(pos);
        return CaptureGuard{ .mouse = self };
    }
};

pub const CaptureGuard = struct {
    mouse: *CapturedMouse,
    active: bool = true,

    pub fn release(self: *CaptureGuard) void {
        if (!self.active) return;
        self.mouse.release();
        self.active = false;
    }

    pub fn deinit(self: *CaptureGuard) void {
        self.release();
    }
};

test "captured mouse toggles state" {
    var capture = CapturedMouse{};
    capture.capture(.{ .x = 1, .y = 2 });
    try std.testing.expect(capture.active);
    try std.testing.expectEqual(@as(i32, 1), capture.position.x);
    capture.release();
    try std.testing.expect(!capture.active);
}

test "capture guard releases on deinit" {
    var capture = CapturedMouse{};
    {
        var guard = capture.captureGuard(.{ .x = 5, .y = 6 });
        defer guard.deinit();
        try std.testing.expect(capture.active);
    }
    try std.testing.expect(!capture.active);
}
