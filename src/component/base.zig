const events = @import("events.zig");

pub const RenderFn = *const fn (*ComponentBase) anyerror!void;
pub const EventFn = *const fn (*ComponentBase, events.Event) bool;
pub const AnimationFn = *const fn (*ComponentBase, f32) void;

pub const ComponentBase = struct {
    text_cache: []const u8 = "",
    user_data: ?*anyopaque = null,
    renderFn: ?RenderFn = null,
    eventFn: ?EventFn = null,
    animationFn: ?AnimationFn = null,
    children: []Component = &[_]Component{},
    focus_index: usize = 0,

    pub fn render(self: *ComponentBase) !void {
        if (self.renderFn) |callback| {
            try callback(self);
        }
    }

    pub fn onEvent(self: *ComponentBase, event: events.Event) bool {
        if (self.eventFn) |callback| {
            return callback(self, event);
        }
        return false;
    }

    pub fn animate(self: *ComponentBase, delta_time: f32) void {
        if (self.animationFn) |callback| {
            callback(self, delta_time);
        }
    }
};

pub const Component = struct {
    base: *ComponentBase,

    pub fn render(self: Component) !void {
        try self.base.render();
    }

    pub fn onEvent(self: Component, event: events.Event) bool {
        return self.base.onEvent(event);
    }
};

pub const ComponentDecorator = fn (Component) Component;
