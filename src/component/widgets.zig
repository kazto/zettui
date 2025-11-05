const std = @import("std");
const base = @import("base.zig");
const options = @import("options.zig");
const events = @import("events.zig");

const CheckboxState = struct { checked: bool };
const ToggleState = struct { on: bool };
const TogglePayload = struct {
    store: ToggleState,
    on_label: []const u8,
    off_label: []const u8,
};

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

pub fn checkbox(allocator: std.mem.Allocator, opts: options.CheckboxOptions) !base.Component {
    const label_copy = try allocator.dupe(u8, opts.label);
    const state_ptr = try allocator.create(CheckboxState);
    state_ptr.* = .{ .checked = opts.checked };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = label_copy,
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = checkboxRender,
        .eventFn = checkboxEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn checkboxRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*CheckboxState, @ptrCast(self.user_data.?));
    if (state.checked) {
        try stdout.writeAll("[x] ");
    } else {
        try stdout.writeAll("[ ] ");
    }
    try stdout.writeAll(self.text_cache);
}

fn checkboxEvent(self: *base.ComponentBase, event: events.Event) bool {
    switch (event) {
        .key => |k| {
            if (k.codepoint == ' ' or k.codepoint == '\n') {
                const state = @as(*CheckboxState, @ptrCast(self.user_data.?));
                state.checked = !state.checked;
                return true;
            }
        },
        else => {},
    }
    return false;
}

pub fn toggle(allocator: std.mem.Allocator, opts: options.ToggleOptions) !base.Component {
    const on_copy = try allocator.dupe(u8, opts.on_label);
    const off_copy = try allocator.dupe(u8, opts.off_label);
    const payload = try allocator.create(TogglePayload);
    payload.* = .{ .store = .{ .on = opts.on }, .on_label = on_copy, .off_label = off_copy };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(payload)),
        .renderFn = toggleRender,
        .eventFn = toggleEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn toggleRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const payload = @as(*TogglePayload, @ptrCast(@alignCast(self.user_data.?)));
    if (payload.store.on) {
        try stdout.writeAll(payload.on_label);
    } else {
        try stdout.writeAll(payload.off_label);
    }
}

fn toggleEvent(self: *base.ComponentBase, event: events.Event) bool {
    switch (event) {
        .key => |k| {
            if (k.codepoint == ' ' or k.codepoint == '\n') {
                const payload = @as(*TogglePayload, @ptrCast(@alignCast(self.user_data.?)));
                payload.store.on = !payload.store.on;
                return true;
            }
        },
        else => {},
    }
    return false;
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

test "checkbox toggles on space key" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const cmp = try checkbox(allocator, .{ .label = "Accept", .checked = false });
    const ev = events.Event{ .key = .{ .codepoint = ' ' } };
    const consumed = cmp.onEvent(ev);
    try std.testing.expect(consumed);

    const state = @as(*CheckboxState, @ptrCast(cmp.base.user_data.?));
    try std.testing.expect(state.checked);
}
