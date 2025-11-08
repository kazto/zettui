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

const InputState = struct {
    buf: std.ArrayList(u8),
    gpa: std.mem.Allocator,
    placeholder: []const u8,
    is_password: bool,
    multiline: bool,
};

const SliderState = struct {
    value: f32,
    min: f32,
    max: f32,
    step: f32,
    horizontal: bool,
};

const RadioGroupState = struct {
    labels: []const []const u8,
    selected_index: usize,
    allocator: std.mem.Allocator,
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

pub fn textInput(allocator: std.mem.Allocator, opts: options.InputOptions) !base.Component {
    const state_ptr = try allocator.create(InputState);
    state_ptr.* = .{
        .buf = try std.ArrayList(u8).initCapacity(allocator, 16),
        .gpa = allocator,
        .placeholder = try allocator.dupe(u8, opts.placeholder),
        .is_password = opts.is_password,
        .multiline = opts.multiline,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = inputRender,
        .eventFn = inputEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn inputRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const st = @as(*InputState, @ptrCast(@alignCast(self.user_data.?)));
    if (st.buf.items.len == 0 and st.placeholder.len > 0) {
        try stdout.writeAll(st.placeholder);
        return;
    }
    if (st.is_password) {
        var i: usize = 0;
        while (i < st.buf.items.len) : (i += 1) try stdout.writeAll("*");
    } else {
        try stdout.writeAll(st.buf.items);
    }
}

fn inputEvent(self: *base.ComponentBase, event: events.Event) bool {
    const st = @as(*InputState, @ptrCast(@alignCast(self.user_data.?)));
    const allocator = st.gpa;
    switch (event) {
        .key => |k| {
            if (k.codepoint) |cp| {
                // backspace (8) or delete (127)
                if (cp == 8 or cp == 127) {
                    if (st.buf.items.len > 0) _ = st.buf.pop();
                    return true;
                }
                // newline
                if (cp == '\n') {
                    if (st.multiline) {
                        st.buf.append(allocator, '\n') catch return false;
                        return true;
                    }
                    return false;
                }
                // append ASCII subset (simple demo)
                if (cp >= 32 and cp <= 126) {
                    st.buf.append(allocator, @as(u8, @intCast(cp))) catch return false;
                    return true;
                }
            }
        },
        else => {},
    }
    return false;
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
            if (k.codepoint) |cp| {
                if (cp == ' ' or cp == '\n') {
                    const state = @as(*CheckboxState, @ptrCast(self.user_data.?));
                    state.checked = !state.checked;
                    return true;
                }
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
            if (k.codepoint) |cp| {
                if (cp == ' ' or cp == '\n') {
                    const payload = @as(*TogglePayload, @ptrCast(@alignCast(self.user_data.?)));
                    payload.store.on = !payload.store.on;
                    return true;
                }
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

test "key event with function key" {
    const ev = events.Event{ .key = .{ .function_key = .f1 } };
    try std.testing.expect(ev.key.function_key == .f1);
    try std.testing.expect(ev.key.codepoint == null);
}

test "key event with arrow key" {
    const ev = events.Event{ .key = .{ .arrow_key = .up } };
    try std.testing.expect(ev.key.arrow_key == .up);
    try std.testing.expect(ev.key.codepoint == null);
}

test "text input appends and backspaces" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const ti = try textInput(allocator, .{ .placeholder = "Name" });
    _ = ti.onEvent(.{ .key = .{ .codepoint = 'a' } });
    _ = ti.onEvent(.{ .key = .{ .codepoint = 'b' } });
    _ = ti.onEvent(.{ .key = .{ .codepoint = 8 } }); // backspace

    const st = @as(*InputState, @ptrCast(@alignCast(ti.base.user_data.?)));
    try std.testing.expectEqual(@as(usize, 1), st.buf.items.len);
    try std.testing.expectEqual(@as(u8, 'a'), st.buf.items[0]);
}

pub fn slider(allocator: std.mem.Allocator, opts: options.SliderOptions) !base.Component {
    const initial_value = std.math.clamp(0.5 * (opts.min + opts.max), opts.min, opts.max);
    const state_ptr = try allocator.create(SliderState);
    state_ptr.* = .{
        .value = initial_value,
        .min = opts.min,
        .max = opts.max,
        .step = opts.step,
        .horizontal = opts.horizontal,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = sliderRender,
        .eventFn = sliderEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn sliderRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*SliderState, @ptrCast(@alignCast(self.user_data.?)));
    const width: usize = 20;
    const fraction = (state.value - state.min) / (state.max - state.min);
    const clamped_fraction = std.math.clamp(fraction, 0.0, 1.0);
    const filled: usize = @intFromFloat(@floor(@as(f32, @floatFromInt(width - 2)) * clamped_fraction + 0.5));
    const empty: usize = width - 2 - filled;

    if (state.horizontal) {
        try stdout.writeAll("[");
        var i: usize = 0;
        while (i < filled) : (i += 1) try stdout.writeAll("=");
        try stdout.writeAll(">");
        i = 0;
        while (i < empty) : (i += 1) try stdout.writeAll(" ");
        try stdout.writeAll("]");
    } else {
        // Vertical slider: render top to bottom
        try stdout.writeAll("^");
        try stdout.writeAll("\n");
        var row: usize = 0;
        while (row < width - 2) : (row += 1) {
            const row_fraction = @as(f32, @floatFromInt(row)) / @as(f32, @floatFromInt(width - 2));
            if (row_fraction <= 1.0 - clamped_fraction) {
                try stdout.writeAll("|");
            } else {
                try stdout.writeAll(":");
            }
            try stdout.writeAll("\n");
        }
        try stdout.writeAll("v");
    }
}

fn sliderEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*SliderState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (k.arrow_key) |arrow| {
                const direction: f32 = switch (arrow) {
                    .left, .down => -1.0,
                    .right, .up => 1.0,
                };
                const actual_direction = if (state.horizontal) (if (arrow == .left or arrow == .right) direction else 0.0) else (if (arrow == .up or arrow == .down) -direction else 0.0);
                if (actual_direction != 0.0) {
                    var new_value = state.value + actual_direction * state.step;
                    new_value = std.math.clamp(new_value, state.min, state.max);
                    // Snap to step
                    const steps = @round((new_value - state.min) / state.step);
                    state.value = state.min + steps * state.step;
                    state.value = std.math.clamp(state.value, state.min, state.max);
                    return true;
                }
            }
            // Also support +/- keys
            if (k.codepoint) |cp| {
                const direction: f32 = switch (cp) {
                    '-', '_' => -1.0,
                    '+', '=' => 1.0,
                    else => 0.0,
                };
                if (direction != 0.0) {
                    var new_value = state.value + direction * state.step;
                    new_value = std.math.clamp(new_value, state.min, state.max);
                    const steps = @round((new_value - state.min) / state.step);
                    state.value = state.min + steps * state.step;
                    state.value = std.math.clamp(state.value, state.min, state.max);
                    return true;
                }
            }
        },
        .mouse => |m| {
            // Mouse events could be handled here for click-to-set functionality
            _ = m;
        },
        else => {},
    }
    return false;
}

test "slider initializes with default value" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sl = try slider(allocator, .{ .min = 0, .max = 100, .step = 1 });
    const state = @as(*SliderState, @ptrCast(@alignCast(sl.base.user_data.?)));
    try std.testing.expect(state.value >= state.min);
    try std.testing.expect(state.value <= state.max);
}

test "slider responds to arrow keys" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sl = try slider(allocator, .{ .min = 0, .max = 100, .step = 10, .horizontal = true });
    const state = @as(*SliderState, @ptrCast(@alignCast(sl.base.user_data.?)));
    const initial_value = state.value;

    _ = sl.onEvent(.{ .key = .{ .arrow_key = .right } });
    try std.testing.expect(state.value > initial_value);

    _ = sl.onEvent(.{ .key = .{ .arrow_key = .left } });
    try std.testing.expect(state.value == initial_value);
}

test "slider vertical orientation responds to up/down arrows" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sl = try slider(allocator, .{ .min = 0, .max = 100, .step = 10, .horizontal = false });
    const state = @as(*SliderState, @ptrCast(@alignCast(sl.base.user_data.?)));
    const initial_value = state.value;

    // Vertical slider: up decreases value, down increases value (opposite of horizontal)
    _ = sl.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expect(state.value > initial_value);

    _ = sl.onEvent(.{ .key = .{ .arrow_key = .up } });
    try std.testing.expect(state.value == initial_value);
}

test "slider responds to plus minus keys" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sl = try slider(allocator, .{ .min = 0, .max = 100, .step = 5, .horizontal = true });
    const state = @as(*SliderState, @ptrCast(@alignCast(sl.base.user_data.?)));
    const initial_value = state.value;

    _ = sl.onEvent(.{ .key = .{ .codepoint = '+' } });
    try std.testing.expect(state.value > initial_value);

    _ = sl.onEvent(.{ .key = .{ .codepoint = '-' } });
    try std.testing.expect(state.value == initial_value);
}

test "slider respects min and max boundaries" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sl = try slider(allocator, .{ .min = 10, .max = 20, .step = 1, .horizontal = true });
    const state = @as(*SliderState, @ptrCast(@alignCast(sl.base.user_data.?)));

    // Set to max
    while (state.value < state.max) {
        _ = sl.onEvent(.{ .key = .{ .arrow_key = .right } });
    }
    try std.testing.expect(state.value <= state.max);

    // Try to go beyond max
    _ = sl.onEvent(.{ .key = .{ .arrow_key = .right } });
    try std.testing.expect(state.value <= state.max);

    // Set to min
    while (state.value > state.min) {
        _ = sl.onEvent(.{ .key = .{ .arrow_key = .left } });
    }
    try std.testing.expect(state.value >= state.min);

    // Try to go beyond min
    _ = sl.onEvent(.{ .key = .{ .arrow_key = .left } });
    try std.testing.expect(state.value >= state.min);
}

test "slider snaps to step values" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sl = try slider(allocator, .{ .min = 0, .max = 100, .step = 5, .horizontal = true });
    const state = @as(*SliderState, @ptrCast(@alignCast(sl.base.user_data.?)));

    // Move slider
    _ = sl.onEvent(.{ .key = .{ .arrow_key = .right } });
    _ = sl.onEvent(.{ .key = .{ .arrow_key = .right } });

    // Value should be a multiple of step (with small floating point tolerance)
    const normalized_value = state.value - state.min;
    const steps = @round(normalized_value / state.step);
    const expected_value = state.min + steps * state.step;
    const diff = @abs(state.value - expected_value);
    try std.testing.expect(diff < 0.001);
}

pub fn radioGroup(allocator: std.mem.Allocator, opts: options.RadioOptions) !base.Component {
    // Copy labels
    const labels_copy = try allocator.alloc([]const u8, opts.labels.len);
    for (opts.labels, 0..) |label_text, i| {
        labels_copy[i] = try allocator.dupe(u8, label_text);
    }

    const selected_index = if (opts.selected_index < opts.labels.len) opts.selected_index else 0;
    const state_ptr = try allocator.create(RadioGroupState);
    state_ptr.* = .{
        .labels = labels_copy,
        .selected_index = selected_index,
        .allocator = allocator,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = radioGroupRender,
        .eventFn = radioGroupEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = selected_index,
    };
    return .{ .base = component_ptr };
}

fn radioGroupRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*RadioGroupState, @ptrCast(@alignCast(self.user_data.?)));
    for (state.labels, 0..) |label_text, i| {
        if (i == state.selected_index) {
            try stdout.writeAll("(o) ");
        } else {
            try stdout.writeAll("( ) ");
        }
        try stdout.writeAll(label_text);
        if (i < state.labels.len - 1) {
            try stdout.writeAll("\n");
        }
    }
}

fn radioGroupEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*RadioGroupState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (k.arrow_key) |arrow| {
                switch (arrow) {
                    .up => {
                        if (state.selected_index > 0) {
                            state.selected_index -= 1;
                            self.focus_index = state.selected_index;
                            return true;
                        }
                    },
                    .down => {
                        if (state.selected_index < state.labels.len - 1) {
                            state.selected_index += 1;
                            self.focus_index = state.selected_index;
                            return true;
                        }
                    },
                    .left, .right => {},
                }
            }
            // Space or Enter to select (though navigation already selects)
            if (k.codepoint) |cp| {
                if (cp == ' ' or cp == '\n') {
                    // Already selected via navigation, just acknowledge
                    return true;
                }
                // Number keys to select by index (1-9)
                if (cp >= '1' and cp <= '9') {
                    const index = @as(usize, @intCast(cp - '1'));
                    if (index < state.labels.len) {
                        state.selected_index = index;
                        self.focus_index = index;
                        return true;
                    }
                }
            }
        },
        else => {},
    }
    return false;
}

test "radio group initializes with selected index" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const labels = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const rg = try radioGroup(allocator, .{ .labels = &labels, .selected_index = 1 });
    const state = @as(*RadioGroupState, @ptrCast(@alignCast(rg.base.user_data.?)));
    try std.testing.expectEqual(@as(usize, 1), state.selected_index);
    try std.testing.expectEqual(@as(usize, 3), state.labels.len);
}

test "radio group navigates with arrow keys" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const labels = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const rg = try radioGroup(allocator, .{ .labels = &labels, .selected_index = 0 });
    const state = @as(*RadioGroupState, @ptrCast(@alignCast(rg.base.user_data.?)));

    _ = rg.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 1), state.selected_index);

    _ = rg.onEvent(.{ .key = .{ .arrow_key = .up } });
    try std.testing.expectEqual(@as(usize, 0), state.selected_index);

    _ = rg.onEvent(.{ .key = .{ .arrow_key = .down } });
    _ = rg.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 2), state.selected_index);

    // Should not go beyond bounds
    _ = rg.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 2), state.selected_index);
}

test "radio group selects with number keys" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const labels = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const rg = try radioGroup(allocator, .{ .labels = &labels, .selected_index = 0 });
    const state = @as(*RadioGroupState, @ptrCast(@alignCast(rg.base.user_data.?)));

    _ = rg.onEvent(.{ .key = .{ .codepoint = '3' } });
    try std.testing.expectEqual(@as(usize, 2), state.selected_index); // '3' selects index 2 (0-based from '1')

    _ = rg.onEvent(.{ .key = .{ .codepoint = '1' } });
    try std.testing.expectEqual(@as(usize, 0), state.selected_index);
}

test "radio group ignores invalid number keys" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const labels = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const rg = try radioGroup(allocator, .{ .labels = &labels, .selected_index = 1 });
    const state = @as(*RadioGroupState, @ptrCast(@alignCast(rg.base.user_data.?)));

    const initial_index = state.selected_index;

    // Try invalid number keys (out of range)
    _ = rg.onEvent(.{ .key = .{ .codepoint = '5' } });
    try std.testing.expectEqual(initial_index, state.selected_index);

    _ = rg.onEvent(.{ .key = .{ .codepoint = '9' } });
    try std.testing.expectEqual(initial_index, state.selected_index);
}

test "radio group handles space and enter keys" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const labels = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const rg = try radioGroup(allocator, .{ .labels = &labels, .selected_index = 1 });
    const state = @as(*RadioGroupState, @ptrCast(@alignCast(rg.base.user_data.?)));

    const initial_index = state.selected_index;

    // Space key should be handled (consumed)
    const space_consumed = rg.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try std.testing.expect(space_consumed);
    try std.testing.expectEqual(initial_index, state.selected_index);

    // Enter key should be handled (consumed)
    const enter_consumed = rg.onEvent(.{ .key = .{ .codepoint = '\n' } });
    try std.testing.expect(enter_consumed);
    try std.testing.expectEqual(initial_index, state.selected_index);
}
