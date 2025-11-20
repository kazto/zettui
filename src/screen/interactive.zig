const std = @import("std");
const surface = @import("screen.zig");
const events = @import("../component/events.zig");

const LoopQueue = std.fifo.LinearFifo(LoopEvent, .Dynamic);
const AnimationList = std.ArrayList(AnimationDriver);

pub const TickEvent = struct {
    delta_ns: u64,
};

pub const ResizeEvent = struct {
    width: usize,
    height: usize,
};

pub const CustomEvent = struct {
    tag: []const u8 = "",
    payload: []const u8 = "",
};

pub const LoopEvent = union(enum) {
    input: events.Event,
    tick: TickEvent,
    resize: ResizeEvent,
    custom: CustomEvent,
};

pub const EventHandler = *const fn (*ScreenInteractive, LoopEvent, ?*anyopaque) anyerror!bool;
pub const FetchFn = *const fn (*ScreenInteractive, ?*anyopaque) anyerror!?LoopEvent;
pub const AnimationCallback = *const fn (*ScreenInteractive, f32, ?*anyopaque) anyerror!bool;
pub const MouseReleaseFn = *const fn (?*anyopaque) void;
pub const RestoreFn = *const fn (?*anyopaque) void;

pub const ScreenInteractive = struct {
    allocator: std.mem.Allocator,
    surface_impl: surface.Screen,
    queue: LoopQueue,
    running: bool = false,
    nested_depth: usize = 0,
    io_depth: usize = 0,
    idle_sleep_ns: u64 = std.time.ns_per_ms,
    animation_drivers: AnimationList,
    next_animation_id: usize = 0,
    mouse_capture: ?CaptureState = null,

    const CaptureState = struct {
        release_fn: ?MouseReleaseFn = null,
        context: ?*anyopaque = null,
    };

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !ScreenInteractive {
        return ScreenInteractive{
            .allocator = allocator,
            .surface_impl = try surface.Screen.init(allocator, width, height),
            .queue = LoopQueue.init(allocator),
            .animation_drivers = AnimationList.init(allocator),
        };
    }

    pub fn deinit(self: *ScreenInteractive) void {
        self.queue.deinit();
        self.animation_drivers.deinit();
        self.allocator.free(self.surface_impl.image.pixels);
        self.mouse_capture = null;
    }

    pub fn screen(self: *ScreenInteractive) *surface.Screen {
        return &self.surface_impl;
    }

    pub fn run(self: *ScreenInteractive, handler: EventHandler, ctx: ?*anyopaque) !void {
        self.running = true;
        var timer = try std.time.Timer.start();
        while (self.running) {
            const delta = timer.lap();
            if (delta > 0) {
                try self.advanceAnimations(delta);
            }
            if (try self.queue.readItem()) |event| {
                const keep_running = try handler(self, event, ctx);
                if (!keep_running) {
                    self.running = false;
                }
            } else {
                std.time.sleep(self.idle_sleep_ns);
            }
        }
    }

    pub fn requestStop(self: *ScreenInteractive) void {
        self.running = false;
    }

    pub fn nextEvent(self: *ScreenInteractive) !?LoopEvent {
        return try self.queue.readItem();
    }

    pub fn postInput(self: *ScreenInteractive, value: events.Event) !void {
        try self.queue.writeItem(.{ .input = value });
    }

    pub fn postTick(self: *ScreenInteractive, delta_ns: u64) !void {
        try self.queue.writeItem(.{ .tick = .{ .delta_ns = delta_ns } });
    }

    pub fn notifyResize(self: *ScreenInteractive, width: usize, height: usize) !void {
        try self.queue.writeItem(.{ .resize = .{ .width = width, .height = height } });
    }

    pub fn postCustom(self: *ScreenInteractive, tag: []const u8, payload: []const u8) !void {
        try self.queue.writeItem(.{ .custom = .{ .tag = tag, .payload = payload } });
    }

    pub fn nestedScreen(self: *ScreenInteractive) NestedScreenGuard {
        self.nested_depth += 1;
        return NestedScreenGuard{ .screen = self };
    }

    pub fn restoredIo(self: *ScreenInteractive, callback: RestoreFn, ctx: ?*anyopaque) RestoredIoGuard {
        self.io_depth += 1;
        return RestoredIoGuard{
            .screen = self,
            .callback = callback,
            .context = ctx,
        };
    }

    pub fn captureMouse(self: *ScreenInteractive, release_fn: ?MouseReleaseFn, ctx: ?*anyopaque) CapturedMouse {
        self.releaseMouse();
        self.mouse_capture = CaptureState{ .release_fn = release_fn, .context = ctx };
        return CapturedMouse{ .screen = self, .active = true };
    }

    fn releaseMouse(self: *ScreenInteractive) void {
        if (self.mouse_capture) |state| {
            if (state.release_fn) |callback| {
                callback(state.context);
            }
        }
        self.mouse_capture = null;
    }

    pub fn addAnimation(self: *ScreenInteractive, fps: f32, callback: AnimationCallback, ctx: ?*anyopaque) !AnimationHandle {
        std.debug.assert(fps > 0.0);
        const interval = @max(@as(u64, 1), @as(u64, @intFromFloat(@as(f64, std.time.ns_per_s) / fps)));
        const id = self.next_animation_id;
        self.next_animation_id += 1;
        const entry = AnimationDriver{
            .id = id,
            .interval_ns = interval,
            .callback = callback,
            .context = ctx,
        };
        try self.animation_drivers.append(entry);
        return AnimationHandle{ .screen = self, .id = id };
    }

    pub fn advanceAnimations(self: *ScreenInteractive, delta_ns: u64) !void {
        var index: usize = 0;
        while (index < self.animation_drivers.items.len) {
            var driver = &self.animation_drivers.items[index];
            if (!driver.active) {
                _ = self.animation_drivers.swapRemove(index);
                continue;
            }
            driver.accumulator += delta_ns;
            var keep = true;
            while (driver.accumulator >= driver.interval_ns and keep) {
                driver.accumulator -= driver.interval_ns;
                const seconds = @as(f32, @floatFromInt(driver.interval_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
                keep = try driver.callback(self, seconds, driver.context);
            }
            if (!keep) {
                driver.active = false;
                _ = self.animation_drivers.swapRemove(index);
                continue;
            }
            index += 1;
        }
    }

    fn cancelAnimation(self: *ScreenInteractive, id: usize) void {
        var index: usize = 0;
        while (index < self.animation_drivers.items.len) {
            if (self.animation_drivers.items[index].id == id) {
                _ = self.animation_drivers.swapRemove(index);
                return;
            }
            index += 1;
        }
    }
};

const AnimationDriver = struct {
    id: usize,
    interval_ns: u64,
    accumulator: u64 = 0,
    callback: AnimationCallback,
    context: ?*anyopaque,
    active: bool = true,
};

pub const CapturedMouse = struct {
    screen: *ScreenInteractive,
    active: bool = true,

    pub fn release(self: *CapturedMouse) void {
        if (!self.active) return;
        self.screen.releaseMouse();
        self.active = false;
    }

    pub fn isActive(self: CapturedMouse) bool {
        return self.active;
    }
};

pub const NestedScreenGuard = struct {
    screen: *ScreenInteractive,
    active: bool = true,

    pub fn restore(self: *NestedScreenGuard) void {
        if (!self.active) return;
        std.debug.assert(self.screen.nested_depth > 0);
        self.screen.nested_depth -= 1;
        self.active = false;
    }
};

pub const RestoredIoGuard = struct {
    screen: *ScreenInteractive,
    callback: ?RestoreFn = null,
    context: ?*anyopaque = null,
    active: bool = true,

    pub fn restore(self: *RestoredIoGuard) void {
        if (!self.active) return;
        if (self.screen.io_depth > 0) self.screen.io_depth -= 1;
        if (self.callback) |callback| {
            callback(self.context);
        }
        self.active = false;
    }
};

pub const AnimationHandle = struct {
    screen: *ScreenInteractive,
    id: usize,
    active: bool = true,

    pub fn cancel(self: *AnimationHandle) void {
        if (!self.active) return;
        self.screen.cancelAnimation(self.id);
        self.active = false;
    }
};

pub const CustomLoop = struct {
    screen: *ScreenInteractive,
    fetch: FetchFn,
    handler: EventHandler,
    ctx: ?*anyopaque,

    pub fn run(self: CustomLoop) !void {
        while (true) {
            const maybe_event = try self.fetch(self.screen, self.ctx);
            if (maybe_event) |event| {
                const keep = try self.handler(self.screen, event, self.ctx);
                if (!keep) break;
            } else {
                break;
            }
        }
    }
};

pub fn customLoop(self: *ScreenInteractive, fetch: FetchFn, handler: EventHandler, ctx: ?*anyopaque) CustomLoop {
    return CustomLoop{
        .screen = self,
        .fetch = fetch,
        .handler = handler,
        .ctx = ctx,
    };
}

test "screen interactive handles posted input event" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var interactive = try ScreenInteractive.init(arena.allocator(), 4, 2);
    defer interactive.deinit();

    try interactive.postInput(events.Event{ .key = .{ .codepoint = 'a' } });

    var seen: usize = 0;
    const Handler = struct {
        fn handle(_: *ScreenInteractive, event: LoopEvent, ctx: ?*anyopaque) anyerror!bool {
            switch (event) {
                .input => {
                    const ptr = @as(*usize, @ptrCast(@alignCast(ctx.?)));
                    ptr.* += 1;
                    return false;
                },
                else => return true,
            }
        }
    };
    try interactive.run(Handler.handle, @as(?*anyopaque, @ptrCast(&seen)));
    try std.testing.expectEqual(@as(usize, 1), seen);
}

test "captured mouse guard releases callback" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var interactive = try ScreenInteractive.init(arena.allocator(), 2, 2);
    defer interactive.deinit();

    var released = false;
    const Release = struct {
        fn cb(ctx: ?*anyopaque) void {
            const ptr = @as(*bool, @ptrCast(@alignCast(ctx.?)));
            ptr.* = true;
        }
    };

    var guard = interactive.captureMouse(Release.cb, @as(?*anyopaque, @ptrCast(&released)));
    guard.release();
    try std.testing.expect(released);
}

test "nested screen guard tracks depth" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var interactive = try ScreenInteractive.init(arena.allocator(), 2, 2);
    defer interactive.deinit();

    {
        var guard = interactive.nestedScreen();
        try std.testing.expectEqual(@as(usize, 1), interactive.nested_depth);
        guard.restore();
    }
    try std.testing.expectEqual(@as(usize, 0), interactive.nested_depth);
}

test "animation loop runs callbacks" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var interactive = try ScreenInteractive.init(arena.allocator(), 2, 2);
    defer interactive.deinit();

    var frames: usize = 0;
    const Callback = struct {
        fn cb(_: *ScreenInteractive, delta_s: f32, ctx: ?*anyopaque) anyerror!bool {
            _ = delta_s;
            const ptr = @as(*usize, @ptrCast(@alignCast(ctx.?)));
            ptr.* += 1;
            return ptr.* < 3;
        }
    };

    _ = try interactive.addAnimation(60.0, Callback.cb, @as(?*anyopaque, @ptrCast(&frames)));
    try interactive.advanceAnimations(std.time.ns_per_s / 60);
    try interactive.advanceAnimations(std.time.ns_per_s / 60);
    try interactive.advanceAnimations(std.time.ns_per_s / 60);
    try std.testing.expectEqual(@as(usize, 3), frames);
    try std.testing.expectEqual(@as(usize, 0), interactive.animation_drivers.items.len);
}

test "custom loop fetch and handler cooperate" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var interactive = try ScreenInteractive.init(arena.allocator(), 2, 2);
    defer interactive.deinit();

    var pulls: usize = 0;
    const Fetcher = struct {
        fn fetch(_: *ScreenInteractive, ctx: ?*anyopaque) anyerror!?LoopEvent {
            const ptr = @as(*usize, @ptrCast(@alignCast(ctx.?)));
            if (ptr.* >= 2) return null;
            ptr.* += 1;
            return LoopEvent{ .tick = .{ .delta_ns = 16 } };
        }
    };

    const Handler = struct {
        fn handle(_: *ScreenInteractive, _: LoopEvent, _: ?*anyopaque) anyerror!bool {
            return true;
        }
    };

    var loop = customLoop(&interactive, Fetcher.fetch, Handler.handle, @as(?*anyopaque, @ptrCast(&pulls)));
    try loop.run();
    try std.testing.expectEqual(@as(usize, 2), pulls);
}
