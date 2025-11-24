const std = @import("std");

pub const Loop = struct {
    target_frame_ms: u32 = 16,
    running: bool = false,
    last_tick_ms: ?i128 = null,

    pub fn run(self: *Loop, tick: fn (*Loop, f32) void) void {
        self.running = true;
        self.last_tick_ms = null;
        while (self.running) {
            self.tickOnce(tick);
        }
    }

    pub fn poll(self: *Loop, tick: fn (*Loop, f32) void) bool {
        if (!self.running) {
            self.running = true;
            self.last_tick_ms = null;
        }
        self.tickOnce(tick);
        return self.running;
    }

    pub fn tickOnce(self: *Loop, tick: fn (*Loop, f32) void) void {
        const now = std.time.milliTimestamp();
        const last = self.last_tick_ms orelse now;
        self.last_tick_ms = now;
        const delta_ms = @as(f32, @floatFromInt(now - last));
        tick(self, delta_ms / 1000.0);
        if (self.target_frame_ms == 0) {
            self.running = false;
        } else if (self.running) {
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

test "poll runs tick once when target frame is zero" {
    var loop = Loop{ .target_frame_ms = 0 };
    const Handler = struct {
        var ticks: usize = 0;
        fn tick(loop_ptr: *Loop, delta: f32) void {
            _ = delta;
            ticks += 1;
            loop_ptr.stop();
        }
    };
    const keep_running = loop.poll(Handler.tick);
    try std.testing.expect(!keep_running);
    try std.testing.expectEqual(@as(usize, 1), Handler.ticks);
}
