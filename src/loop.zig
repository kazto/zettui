const std = @import("std");

pub const Loop = struct {
    target_frame_ms: u32 = 16,
    running: bool = false,

    pub fn run(self: *Loop, tick: fn (*Loop, f32) void) void {
        self.running = true;
        var last = std.time.milliTimestamp();
        while (self.running) {
            const now = std.time.milliTimestamp();
            const delta_ms = @as(f32, @floatFromInt(now - last));
            last = now;
            tick(self, delta_ms / 1000.0);
            if (self.target_frame_ms == 0) {
                self.running = false;
                break;
            }
            std.Thread.sleep(@as(u64, self.target_frame_ms) * std.time.ns_per_ms);
        }
    }

    pub fn stop(self: *Loop) void {
        self.running = false;
    }
};

test "loop tick executes at least once" {
    var loop = Loop{ .target_frame_ms = 0 };
    const Handler = struct {
        var count: usize = 0;
        fn tick(loop_ptr: *Loop, delta: f32) void {
            _ = delta;
            count += 1;
            loop_ptr.stop();
        }
    };
    loop.run(Handler.tick);
    try std.testing.expectEqual(@as(usize, 1), Handler.count);
}
