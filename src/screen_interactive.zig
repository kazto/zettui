const std = @import("std");
const component = @import("component.zig");
const task = @import("task.zig");
const animator = @import("animation/animator.zig");
const loop_mod = @import("loop.zig");
const captured_mouse = @import("captured_mouse.zig");

pub const EventLoop = struct {
    allocator: std.mem.Allocator,
    scheduler: task.Scheduler,
    loop: loop_mod.Loop = .{},
    queue: std.ArrayListUnmanaged(component.Event) = .{},
    mouse: ?*captured_mouse.CapturedMouse = null,
    animator_state: animator.Animator = .{ .duration = 0.25 },
    root: ?component.Component = null,

    pub fn init(allocator: std.mem.Allocator) EventLoop {
        return .{
            .allocator = allocator,
            .scheduler = task.Scheduler.init(allocator),
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

    pub fn requestAnimationFrame(self: *EventLoop) void {
        self.animator_state.reset();
    }

    pub fn run(self: *EventLoop, root: component.Component) !void {
        self.root = root;
        self.loop.run(struct {
            fn tick(loop_ptr: *loop_mod.Loop, delta: f32) void {
                const parent = parentFromLoop(loop_ptr);
                parent.processFrame(delta) catch |err| {
                    std.log.err("event loop tick failed: {s}", .{std.errorName(err)});
                    loop_ptr.stop();
                };
            }
        }.tick);
    }

    fn processFrame(self: *EventLoop, delta: f32) !void {
        self.animator_state.advance(delta);
        self.scheduler.run();
        if (self.root) |root_component| {
            for (self.queue.items) |event| {
                _ = root_component.onEvent(event);
            }
            // deliver animation pulse
            const phase_event = component.Event{ .custom = .{ .tag = "animation-frame" } };
            _ = root_component.onEvent(phase_event);
        }
        self.queue.clearRetainingCapacity();
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
