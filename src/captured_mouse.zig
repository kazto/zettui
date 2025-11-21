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
};

test "captured mouse toggles state" {
    var capture = CapturedMouse{};
    capture.capture(.{ .x = 1, .y = 2 });
    try std.testing.expect(capture.active);
    try std.testing.expectEqual(@as(i32, 1), capture.position.x);
    capture.release();
    try std.testing.expect(!capture.active);
}
