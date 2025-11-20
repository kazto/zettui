const std = @import("std");
const base = @import("base.zig");
const events = @import("events.zig");
const options = @import("options.zig");

pub const RenderBridgeFn = *const fn (?*anyopaque, std.fs.File.Writer) anyerror!void;
pub const RenderBridgeEventFn = *const fn (?*anyopaque, events.Event) bool;

const MaybeState = struct {
    child: base.Component,
    active: bool,
};

fn maybeRender(self: *base.ComponentBase) anyerror!void {
    const state = @as(*MaybeState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.active) try state.child.render();
}

fn maybeEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*MaybeState, @ptrCast(@alignCast(self.user_data.?)));
    if (!state.active) return false;
    return state.child.onEvent(event);
}

pub fn maybe(allocator: std.mem.Allocator, child: base.Component, active: bool) !base.Component {
    const state_ptr = try allocator.create(MaybeState);
    state_ptr.* = .{ .child = child, .active = active };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = maybeRender,
        .eventFn = maybeEvent,
        .animationFn = null,
        .children = &[_]base.Component{child},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

pub fn maybeSetActive(component: base.Component, active: bool) void {
    const state = @as(*MaybeState, @ptrCast(@alignCast(component.base.user_data.?)));
    state.active = active;
}

const RendererBridgeState = struct {
    callback: RenderBridgeFn,
    event_callback: ?RenderBridgeEventFn = null,
    user_data: ?*anyopaque = null,
};

fn rendererBridgeRender(self: *base.ComponentBase) anyerror!void {
    const state = @as(*RendererBridgeState, @ptrCast(@alignCast(self.user_data.?)));
    const writer = std.fs.File.stdout().writer();
    try state.callback(state.user_data, writer);
}

fn rendererBridgeEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*RendererBridgeState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.event_callback) |cb| {
        return cb(state.user_data, event);
    }
    return false;
}

pub fn rendererBridge(
    allocator: std.mem.Allocator,
    callback: RenderBridgeFn,
    user_data: ?*anyopaque,
    event_callback: ?RenderBridgeEventFn,
) !base.Component {
    const state_ptr = try allocator.create(RendererBridgeState);
    state_ptr.* = .{ .callback = callback, .event_callback = event_callback, .user_data = user_data };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = rendererBridgeRender,
        .eventFn = rendererBridgeEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

const UnderlineState = struct {
    child: base.Component,
    option: options.UnderlineOption,
};

fn underlineRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*UnderlineState, @ptrCast(@alignCast(self.user_data.?)));
    try state.child.render();
    const raw = std.math.ceil(state.option.thickness);
    const thickness = @max(@as(usize, 1), @as(usize, @intFromFloat(raw)));
    var line: usize = 0;
    while (line < thickness) : (line += 1) {
        try stdout.writeAll("\n");
        try stdout.writeAll("~~~~~~~~");
    }
}

fn underlineEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*UnderlineState, @ptrCast(@alignCast(self.user_data.?)));
    return state.child.onEvent(event);
}

pub fn underlineDecorator(allocator: std.mem.Allocator, child: base.Component, option: options.UnderlineOption) !base.Component {
    const state_ptr = try allocator.create(UnderlineState);
    state_ptr.* = .{ .child = child, .option = option };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = underlineRender,
        .eventFn = underlineEvent,
        .animationFn = null,
        .children = &[_]base.Component{child},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

const AnimatedLabelState = struct {
    text: []const u8,
    options: options.AnimatedColorOption,
    elapsed_ms: f32 = 0,

    fn currentColor(self: AnimatedLabelState) u24 {
        const t = if (self.options.duration_ms == 0) 1.0 else std.math.min(self.elapsed_ms / @as(f32, @floatFromInt(self.options.duration_ms)), 1.0);
        const start = self.options.start_color;
        const end = self.options.end_color;
        const r0: f32 = @floatFromInt((start >> 16) & 0xFF);
        const g0: f32 = @floatFromInt((start >> 8) & 0xFF);
        const b0: f32 = @floatFromInt(start & 0xFF);
        const r1: f32 = @floatFromInt((end >> 16) & 0xFF);
        const g1: f32 = @floatFromInt((end >> 8) & 0xFF);
        const b1: f32 = @floatFromInt(end & 0xFF);
        const r = @as(u24, @intFromFloat(r0 + (r1 - r0) * t)) << 16;
        const g = @as(u24, @intFromFloat(g0 + (g1 - g0) * t)) << 8;
        const b = @as(u24, @intFromFloat(b0 + (b1 - b0) * t));
        return r | g | b;
    }
};

fn animatedLabelRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*AnimatedLabelState, @ptrCast(@alignCast(self.user_data.?)));
    var buf: [64]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "[0x{X:0>6}] {s}", .{ state.currentColor(), state.text });
    try stdout.writeAll(msg);
}

fn animatedLabelAnimate(self: *base.ComponentBase, delta_time: f32) void {
    const state = @as(*AnimatedLabelState, @ptrCast(@alignCast(self.user_data.?)));
    state.elapsed_ms += delta_time * 1000.0;
    if (state.elapsed_ms > @as(f32, @floatFromInt(state.options.duration_ms))) {
        state.elapsed_ms = 0;
    }
}

pub fn animatedLabel(allocator: std.mem.Allocator, text: []const u8, option: options.AnimatedColorOption) !base.Component {
    const owned_text = try allocator.dupe(u8, text);
    const state_ptr = try allocator.create(AnimatedLabelState);
    state_ptr.* = .{ .text = owned_text, .options = option };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = owned_text,
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = animatedLabelRender,
        .eventFn = null,
        .animationFn = animatedLabelAnimate,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

const DebugWrapperState = struct {
    child: base.Component,
};

fn debugRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*DebugWrapperState, @ptrCast(@alignCast(self.user_data.?)));
    try stdout.writeAll("[debug]\n");
    try state.child.render();
}

fn debugEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*DebugWrapperState, @ptrCast(@alignCast(self.user_data.?)));
    return state.child.onEvent(event);
}

fn debugDecoratorImpl(component: base.Component) base.Component {
    const allocator = std.heap.page_allocator;
    const state_ptr = allocator.create(DebugWrapperState) catch unreachable;
    state_ptr.* = .{ .child = component };

    const component_ptr = allocator.create(base.ComponentBase) catch unreachable;
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = debugRender,
        .eventFn = debugEvent,
        .animationFn = null,
        .children = &[_]base.Component{component},
        .focus_index = component.base.focus_index,
    };
    return .{ .base = component_ptr };
}

pub const debugDecorator: base.ComponentDecorator = debugDecoratorImpl;

const TestRenderState = struct {
    count: usize = 0,
};

test "maybe toggles child activation" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var state = TestRenderState{};
    const child_ptr = try allocator.create(base.ComponentBase);
    child_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(&state)),
        .renderFn = struct {
            fn render(self: *base.ComponentBase) anyerror!void {
                const st = @as(*TestRenderState, @ptrCast(self.user_data.?));
                st.count += 1;
            }
        }.render,
        .eventFn = null,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    const child = base.Component{ .base = child_ptr };

    var maybe_component = try maybe(allocator, child, false);
    try maybe_component.render();
    try std.testing.expectEqual(@as(usize, 0), state.count);

    maybeSetActive(maybe_component, true);
    try maybe_component.render();
    try std.testing.expectEqual(@as(usize, 1), state.count);
}

test "renderer bridge invokes callback" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var invoked: bool = false;
    const component = try rendererBridge(allocator, struct {
        fn run(user_data: ?*anyopaque, writer: std.fs.File.Writer) anyerror!void {
            _ = writer;
            if (user_data) |flag| {
                const flag_ptr = @as(*bool, @ptrCast(flag));
                flag_ptr.* = true;
            }
        }
    }.run, @as(*anyopaque, @ptrCast(&invoked)), null);

    try component.render();
    try std.testing.expect(invoked);
}

test "animated label cycles color" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const option = options.AnimatedColorOption{ .start_color = 0x000000, .end_color = 0xFFFFFF, .duration_ms = 100 };
    const label = try animatedLabel(allocator, "hello", option);
    const state = @as(*AnimatedLabelState, @ptrCast(@alignCast(label.base.user_data.?)));
    try std.testing.expectEqual(@as(u24, 0x000000), state.currentColor());
    label.base.animate(0.1);
    try std.testing.expect(state.currentColor() != 0x000000);
}
