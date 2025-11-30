const std = @import("std");
const component = @import("component.zig");
const task = @import("task.zig");
const animator = @import("animation/animator.zig");
const loop_mod = @import("loop.zig");
const captured_mouse = @import("captured_mouse.zig");

pub const InputFetcher = *const fn (*EventLoop, ?*anyopaque) anyerror!?component.Event;
pub const TerminalHook = *const fn (?*anyopaque) anyerror!void;

pub const EventLoop = struct {
    allocator: std.mem.Allocator,
    scheduler: task.Scheduler,
    loop: loop_mod.Loop = .{},
    queue: std.ArrayListUnmanaged(component.Event) = .{},
    mouse: ?*captured_mouse.CapturedMouse = null,
    animator_state: animator.Animator = .{ .duration = 0.25 },
    root: ?component.Component = null,
    input_fetcher: ?InputFetcher = null,
    input_ctx: ?*anyopaque = null,
    on_start: ?TerminalHook = null,
    on_stop: ?TerminalHook = null,
    terminal_ctx: ?*anyopaque = null,
    cursor_visible: bool = true,

    pub fn init(allocator: std.mem.Allocator) EventLoop {
        return .{
            .allocator = allocator,
            .scheduler = task.Scheduler.init(allocator),
            .animator_state = .{ .duration = 0.25, .elapsed = 0.25 },
        };
    }

    pub fn deinit(self: *EventLoop) void {
        self.scheduler.deinit();
        self.queue.deinit(self.allocator);
    }

    pub fn postEvent(self: *EventLoop, event: component.Event) !void {
        try self.queue.append(self.allocator, event);
    }

    pub fn bindMouse(self: *EventLoop, mouse: *captured_mouse.CapturedMouse) void {
        self.mouse = mouse;
    }

    pub fn bindInputFetcher(self: *EventLoop, fetcher: InputFetcher, ctx: ?*anyopaque) void {
        self.input_fetcher = fetcher;
        self.input_ctx = ctx;
    }

    pub fn setTerminalHooks(self: *EventLoop, start: ?TerminalHook, stop: ?TerminalHook, ctx: ?*anyopaque) void {
        self.on_start = start;
        self.on_stop = stop;
        self.terminal_ctx = ctx;
    }

    pub fn requestAnimationFrame(self: *EventLoop) void {
        self.animator_state.reset();
    }

    pub fn postTask(self: *EventLoop, t: task.Task) !void {
        try self.scheduler.add(t);
    }

    pub fn requestStop(self: *EventLoop) void {
        self.loop.stop();
    }

    pub fn run(self: *EventLoop, root: component.Component) !void {
        self.root = root;
        if (self.on_start) |hook| try hook(self.terminal_ctx);
        defer {
            if (self.on_stop) |hook| {
                hook(self.terminal_ctx) catch {};
            }
        }
        self.loop.run(struct {
            fn tick(loop_ptr: *loop_mod.Loop, delta: f32) void {
                const parent = parentFromLoop(loop_ptr);
                parent.processFrame(delta) catch |err| {
                    std.log.err("event loop tick failed: {s}", .{@errorName(err)});
                    loop_ptr.stop();
                };
            }
        }.tick);
    }

    pub fn pump(self: *EventLoop, root: component.Component) !bool {
        self.root = self.root orelse root;
        return self.loop.poll(struct {
            fn tick(loop_ptr: *loop_mod.Loop, delta: f32) void {
                const parent = parentFromLoop(loop_ptr);
                parent.processFrame(delta) catch |err| {
                    std.log.err("event loop tick failed: {s}", .{@errorName(err)});
                    loop_ptr.stop();
                };
            }
        }.tick);
    }

    fn processFrame(self: *EventLoop, delta: f32) !void {
        try self.pumpPipedInput();
        self.animator_state.advance(delta);
        self.scheduler.run();
        if (self.root) |root_component| {
            for (self.queue.items) |event| {
                self.trackState(event);
                _ = root_component.onEvent(event);
            }
            root_component.animate(delta);
            if (self.animator_state.isActive()) {
                const phase_event = component.Event{ .custom = .{ .tag = "animation-frame" } };
                _ = root_component.onEvent(phase_event);
            }
        }
        self.queue.clearRetainingCapacity();
    }

    fn pumpPipedInput(self: *EventLoop) !void {
        if (self.input_fetcher) |fetcher| {
            while (true) {
                const maybe_event = try fetcher(self, self.input_ctx);
                if (maybe_event) |ev| {
                    try self.postEvent(ev);
                } else break;
            }
        }
    }

    fn trackState(self: *EventLoop, event: component.Event) void {
        switch (event) {
            .mouse => |mouse_event| {
                if (self.mouse) |m| {
                    if (m.active or mouse_event.kind == .press) {
                        m.capture(mouse_event.position);
                    } else {
                        m.move(mouse_event.position);
                    }
                    if (mouse_event.kind == .release) {
                        m.release();
                    }
                }
            },
            .cursor => |cursor| {
                self.cursor_visible = cursor.visible;
            },
            else => {},
        }
    }
};

fn parentFromLoop(loop_ptr: *loop_mod.Loop) *EventLoop {
    const base_addr = @intFromPtr(loop_ptr) - @offsetOf(EventLoop, "loop");
    return @alignCast(@as(*EventLoop, @ptrFromInt(base_addr)));
}

test "event loop queues events" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var loop = EventLoop.init(allocator);
    defer loop.deinit();
    try loop.postEvent(.{ .custom = .{ .tag = "ping" } });
    try std.testing.expectEqual(@as(usize, 1), loop.queue.items.len);
}

test "event loop pumps fetcher, tasks, and animation callbacks" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var counts = struct { events: usize = 0, anims: usize = 0, tasks: usize = 0 }{};
    const Handler = struct {
        fn onEvent(self: *component.ComponentBase, event: component.Event) bool {
            const stats = @as(*struct { events: usize, anims: usize, tasks: usize }, @ptrCast(@alignCast(self.user_data.?)));
            _ = event;
            stats.events += 1;
            return true;
        }

        fn animate(self: *component.ComponentBase, delta: f32) void {
            _ = delta;
            const stats = @as(*struct { events: usize, anims: usize, tasks: usize }, @ptrCast(@alignCast(self.user_data.?)));
            stats.anims += 1;
        }
    };

    const base_ptr = try allocator.create(component.ComponentBase);
    base_ptr.* = .{
        .user_data = @as(?*anyopaque, @ptrCast(&counts)),
        .eventFn = Handler.onEvent,
        .animationFn = Handler.animate,
    };
    const comp = component.Component{ .base = base_ptr };

    var loop = EventLoop.init(allocator);
    defer loop.deinit();
    loop.loop.target_frame_ms = 0;

    try loop.postEvent(.{ .custom = .{ .tag = "queued" } });

    const Fetcher = struct {
        fn fetch(_: *EventLoop, ctx: ?*anyopaque) anyerror!?component.Event {
            const seen = @as(*bool, @ptrCast(@alignCast(ctx.?)));
            if (seen.*) return null;
            seen.* = true;
            return component.Event{ .cursor = .{ .visible = false } };
        }
    };
    var fetched = false;
    loop.bindInputFetcher(Fetcher.fetch, @as(?*anyopaque, @ptrCast(&fetched)));

    const TaskRunner = struct {
        fn run(task_ptr: *task.Task, _: std.mem.Allocator) anyerror!void {
            const stats = @as(*struct { events: usize, anims: usize, tasks: usize }, @ptrCast(@alignCast(task_ptr.user_data.?)));
            stats.tasks += 1;
            task_ptr.completed = true;
        }
    };
    try loop.postTask(.{ .callback = TaskRunner.run, .user_data = @as(?*anyopaque, @ptrCast(&counts)) });

    try loop.run(comp);
    try std.testing.expectEqual(@as(usize, 2), counts.events); // queued + fetched
    try std.testing.expectEqual(@as(usize, 1), counts.tasks);
    try std.testing.expect(counts.anims >= 1);
    try std.testing.expect(!loop.cursor_visible);
}
