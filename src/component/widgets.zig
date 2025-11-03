const std = @import("std");
const base = @import("base.zig");
const options = @import("options.zig");
const events = @import("events.zig");

pub fn button(allocator: std.mem.Allocator, opts: options.ButtonOptions) !base.Component {
    const owned_label = try allocator.dupe(u8, opts.label);
    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = owned_label,
        .user_data = null,
        .renderFn = buttonRender,
        .eventFn = buttonEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

pub fn label(allocator: std.mem.Allocator, text: []const u8) !base.Component {
    const owned_text = try allocator.dupe(u8, text);
    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = owned_text,
        .user_data = null,
        .renderFn = labelRender,
        .eventFn = null,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

pub fn container(allocator: std.mem.Allocator, children: []const base.Component) !base.Component {
    const owned_children = try allocator.dupe(base.Component, children);
    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = null,
        .renderFn = containerRender,
        .eventFn = containerEvent,
        .animationFn = containerAnimate,
        .children = owned_children,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn buttonRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    if (self.text_cache.len > 0) {
        try stdout.writeAll("[");
        try stdout.writeAll(self.text_cache);
        try stdout.writeAll("]");
    } else {
        try stdout.writeAll("[button]");
    }
}

fn buttonEvent(self: *base.ComponentBase, event: events.Event) bool {
    _ = self;
    _ = event;
    return false;
}

fn labelRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    if (self.text_cache.len > 0) {
        try stdout.writeAll(self.text_cache);
    }
}

fn containerRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    for (self.children) |child| {
        try child.render();
        try stdout.writeAll("\n");
    }
}

fn containerEvent(self: *base.ComponentBase, event: events.Event) bool {
    for (self.children) |child| {
        if (child.onEvent(event)) {
            return true;
        }
    }
    return false;
}

fn containerAnimate(self: *base.ComponentBase, delta_time: f32) void {
    for (self.children) |child| {
        child.base.animate(delta_time);
    }
}

test "button stores label in text cache" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const component = try button(arena.allocator(), .{ .label = "OK" });
    try std.testing.expectEqualStrings("OK", component.base.text_cache);
}

test "container animate forwards to children" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var triggered = false;
    const child_ptr = try allocator.create(base.ComponentBase);
    child_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(&triggered)),
        .renderFn = null,
        .eventFn = null,
        .animationFn = struct {
            fn animate(self: *base.ComponentBase, _: f32) void {
                const flag_ptr = @as(*bool, @ptrCast(self.user_data.?));
                flag_ptr.* = true;
            }
        }.animate,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };

    const child_component = base.Component{ .base = child_ptr };
    const container_component = try container(allocator, &[_]base.Component{child_component});

    container_component.base.animate(0.1);
    try std.testing.expect(triggered);
}
