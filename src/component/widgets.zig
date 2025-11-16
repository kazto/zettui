const std = @import("std");
const base = @import("base.zig");
const options = @import("options.zig");
const events = @import("events.zig");

const ButtonState = struct {
    label: []const u8,
    visual: options.ButtonVisual,
    frame: options.ButtonFrameStyle,
    is_default: bool,
    animated: bool,
    underline: ?options.UnderlineOption,
    animation: ?options.AnimatedColorOption,
    phase: f32 = 0.0,
};

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
    prefix: []const u8,
    suffix: []const u8,
    bordered: bool,
    placeholder_style: []const u8,
    visible_lines: usize,
    cursor: usize = 0,
    scroll_line: usize = 0,
    max_length: usize,
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

const DropdownState = struct {
    items: []const []const u8,
    selected_index: ?usize,
    is_open: bool,
    placeholder: []const u8,
    allocator: std.mem.Allocator,
    custom_renderer: ?options.DropdownRenderFn = null,

    fn ensureSelection(self: *DropdownState) void {
        if (self.selected_index == null and self.items.len > 0) {
            self.selected_index = 0;
        } else if (self.items.len == 0) {
            self.selected_index = null;
        } else if (self.selected_index) |idx| {
            if (idx >= self.items.len) {
                self.selected_index = self.items.len - 1;
            }
        }
    }

    fn currentLabel(self: DropdownState) []const u8 {
        if (self.selected_index) |idx| {
            return self.items[idx];
        }
        return self.placeholder;
    }
};

const MenuState = struct {
    items: []const []const u8,
    selected_index: usize,
    loop_navigation: bool,
    highlight_color: u24,
    animation_enabled: bool,
    phase: f32 = 0.0,
    multi_select: bool,
    selections: []bool,
    underline_gallery: bool,
    custom_renderer: ?options.MenuRenderFn = null,
};

const TabsState = struct {
    labels: []const []const u8,
    selected_index: usize,
    orientation: options.TabsOrientation,
};

const ScrollbarState = struct {
    content_length: usize,
    viewport_length: usize,
    position: usize,
    orientation: options.ScrollbarOrientation,
};

const SplitState = struct {
    children: []base.Component,
    ratio: f32,
    min_ratio: f32,
    max_ratio: f32,
    orientation: options.SplitOrientation,
    handle: []const u8,
};

const ModalState = struct {
    child: base.Component,
    title: []const u8,
    is_open: bool,
    dismissible: bool,
    width: usize,
};

const CollapsibleState = struct {
    child: base.Component,
    label: []const u8,
    expanded: bool,
    indicator_open: []const u8,
    indicator_closed: []const u8,
};

const HoverState = struct {
    child: base.Component,
    hovered: bool = false,
    hover_text: []const u8,
    idle_text: []const u8,
};

const WindowState = struct {
    child: base.Component,
    title: []const u8,
    border: bool,
};

pub fn button(allocator: std.mem.Allocator, opts: options.ButtonOptions) !base.Component {
    const owned_label = try allocator.dupe(u8, opts.label);
    const state_ptr = try allocator.create(ButtonState);
    state_ptr.* = .{
        .label = owned_label,
        .visual = opts.visual,
        .frame = opts.frame,
        .is_default = opts.is_default,
        .animated = opts.animated or (opts.animation != null),
        .underline = opts.underline,
        .animation = opts.animation,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = owned_label,
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = buttonRender,
        .eventFn = buttonEvent,
        .animationFn = if (state_ptr.animated) buttonAnimate else null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

pub fn buttonStyled(allocator: std.mem.Allocator, label_text: []const u8, visual: options.ButtonVisual) !base.Component {
    return button(allocator, .{ .label = label_text, .visual = visual });
}

pub fn buttonAnimated(allocator: std.mem.Allocator, label_text: []const u8, animation: options.AnimatedColorOption) !base.Component {
    return button(allocator, .{ .label = label_text, .animated = true, .animation = animation });
}

pub fn buttonInFrame(allocator: std.mem.Allocator, label_text: []const u8, frame_opts: options.FrameOptions) !base.Component {
    const inner = try button(allocator, .{ .label = label_text, .frame = .inline_frame });
    return frameDecorator(allocator, inner, frame_opts);
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
    const state = @as(*ButtonState, @ptrCast(@alignCast(self.user_data.?)));
    switch (state.frame) {
        .none => {
            try stdout.writeAll("[");
            try buttonWriteBody(stdout, state);
            try stdout.writeAll("]");
        },
        .inline_frame => {
            try stdout.writeAll("< ");
            try buttonWriteBody(stdout, state);
            try stdout.writeAll(" >");
        },
        .panel => {
            const width = buttonVisualLength(state) + 2;
            try stdout.writeAll("+");
            try writeRepeating(stdout, '=', width);
            try stdout.writeAll("+\n| ");
            try buttonWriteBody(stdout, state);
            try stdout.writeAll(" |\n+");
            try writeRepeating(stdout, '=', width);
            try stdout.writeAll("+");
        },
    }
    if (state.underline) |under| {
        try stdout.writeAll("\n");
        const underline_char: u8 = if (under.thickness >= 2) '=' else '-';
        try writeRepeating(stdout, underline_char, buttonVisualLength(state));
    }
    if (state.animation) |anim| {
        var buf: [96]u8 = undefined;
        const msg = try std.fmt.bufPrint(&buf, "\nanim 0x{X:0>6}->0x{X:0>6} ({d}ms)", .{ anim.start_color, anim.end_color, anim.duration_ms });
        try stdout.writeAll(msg);
    }
}

fn buttonEvent(self: *base.ComponentBase, event: events.Event) bool {
    _ = self;
    _ = event;
    return false;
}

fn buttonAnimate(self: *base.ComponentBase, delta_time: f32) void {
    const state = @as(*ButtonState, @ptrCast(@alignCast(self.user_data.?)));
    state.phase += delta_time;
    if (state.phase >= 1.0) {
        state.phase -= std.math.floor(state.phase);
    }
}

fn buttonWriteBody(file: std.fs.File, state: *ButtonState) !void {
    if (state.animated) {
        const marker = if (state.phase > 0.5) "~" else "-";
        try file.writeAll(marker);
        try file.writeAll(" ");
    }
    const prefix = buttonVisualPrefix(state.visual);
    const suffix = buttonVisualSuffix(state.visual);
    if (prefix.len > 0) try file.writeAll(prefix);
    if (state.is_default) try file.writeAll("*");
    try file.writeAll(state.label);
    if (state.is_default) try file.writeAll("*");
    if (suffix.len > 0) try file.writeAll(suffix);
    if (state.animated) {
        try file.writeAll(" ");
        try file.writeAll(if (state.phase > 0.5) "~" else "-");
    }
}

fn buttonVisualLength(state: *ButtonState) usize {
    var len = state.label.len;
    if (state.is_default) len += 2;
    len += buttonVisualPrefix(state.visual).len + buttonVisualSuffix(state.visual).len;
    if (state.animated) len += 4;
    return len;
}

fn buttonVisualPrefix(style: options.ButtonVisual) []const u8 {
    return switch (style) {
        .plain => "",
        .primary => ">> ",
        .success => "+ ",
        .danger => "! ",
    };
}

fn buttonVisualSuffix(style: options.ButtonVisual) []const u8 {
    return switch (style) {
        .plain => "",
        .primary => " <<",
        .success => "",
        .danger => " !",
    };
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
        .prefix = try allocator.dupe(u8, opts.prefix),
        .suffix = try allocator.dupe(u8, opts.suffix),
        .bordered = opts.bordered,
        .placeholder_style = try allocator.dupe(u8, opts.placeholder_style),
        .visible_lines = if (opts.multiline) @max(opts.visible_lines, 1) else 1,
        .max_length = opts.max_length,
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

pub fn textArea(allocator: std.mem.Allocator, opts: options.InputOptions) !base.Component {
    var derived = opts;
    derived.multiline = true;
    if (derived.visible_lines <= 1) {
        derived.visible_lines = 4;
    }
    if (!derived.bordered) {
        derived.bordered = true;
    }
    return textInput(allocator, derived);
}

fn inputRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const st = @as(*InputState, @ptrCast(@alignCast(self.user_data.?)));
    inputEnsureCursorVisible(st);
    const region = inputVisibleRegion(st);

    if (st.bordered) {
        try inputRenderBorder(stdout, st, region.slice.len, true);
        try stdout.writeAll("\n");
    }
    if (st.prefix.len > 0) {
        try stdout.writeAll(st.prefix);
    }

    if (region.slice.len == 0 and st.placeholder.len > 0) {
        if (st.placeholder_style.len > 0) {
            var buf: [128]u8 = undefined;
            const text = try std.fmt.bufPrint(&buf, "<{s}:{s}>", .{ st.placeholder_style, st.placeholder });
            try stdout.writeAll(text);
        } else {
            try stdout.writeAll(st.placeholder);
        }
    } else {
        try inputWriteSlice(stdout, st, region);
    }

    if (st.suffix.len > 0) {
        try stdout.writeAll(st.suffix);
    }

    if (st.bordered) {
        try stdout.writeAll("\n");
        try inputRenderBorder(stdout, st, region.slice.len, false);
    }

    try stdout.writeAll("\n");
    try inputWriteStatus(stdout, st);
}

fn inputEvent(self: *base.ComponentBase, event: events.Event) bool {
    const st = @as(*InputState, @ptrCast(@alignCast(self.user_data.?)));
    var consumed = false;
    switch (event) {
        .key => |k| {
            if (k.arrow_key) |arrow| consumed = inputHandleArrow(st, arrow);
            if (!consumed) {
                if (k.codepoint) |cp| {
                    consumed = inputHandleCodepoint(st, cp);
                }
            }
        },
        else => {},
    }
    if (consumed) {
        inputEnsureCursorVisible(st);
    }
    return consumed;
}

const VisibleRegion = struct {
    slice: []const u8,
    start: usize,
};

fn inputVisibleRegion(st: *InputState) VisibleRegion {
    if (!st.multiline or st.visible_lines <= 1) {
        return .{ .slice = st.buf.items, .start = 0 };
    }
    const start = inputLineStart(st.buf.items, st.scroll_line);
    var end = start;
    var lines_remaining = st.visible_lines;
    if (lines_remaining == 0) lines_remaining = 1;
    var newline_hits: usize = 0;
    while (end < st.buf.items.len) : (end += 1) {
        if (st.buf.items[end] == '\n') {
            newline_hits += 1;
            if (newline_hits >= lines_remaining) {
                end += 1;
                break;
            }
        }
    }
    return .{ .slice = st.buf.items[start..end], .start = start };
}

fn inputRenderBorder(stdout: std.fs.File, st: *InputState, visible_len: usize, top: bool) !void {
    const base_width = st.prefix.len + st.suffix.len + visible_len + 2;
    const width = @max(base_width, st.placeholder.len + 2);
    _ = top; // same glyphs for now
    try stdout.writeAll("+");
    try writeRepeating(stdout, '-', width);
    try stdout.writeAll("+");
}

fn inputWriteSlice(stdout: std.fs.File, st: *InputState, region: VisibleRegion) !void {
    if (st.is_password) {
        var i: usize = 0;
        while (i < region.slice.len) : (i += 1) {
            if (region.slice[i] == '\n') {
                try stdout.writeAll("\n");
            } else {
                try stdout.writeAll("*");
            }
        }
        return;
    }
    try stdout.writeAll(region.slice);
}

fn inputWriteStatus(stdout: std.fs.File, st: *InputState) !void {
    const cursor_line = inputLineNumber(st.buf.items, st.cursor);
    const line_start = inputLineStart(st.buf.items, cursor_line);
    const col = st.cursor - line_start;
    var buf: [128]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "cursor line {d} col {d} / {d} chars", .{
        cursor_line + 1,
        col + 1,
        st.buf.items.len,
    });
    try stdout.writeAll(msg);
}

fn inputEnsureCursorVisible(st: *InputState) void {
    if (!st.multiline or st.visible_lines == 0) return;
    const cursor_line = inputLineNumber(st.buf.items, st.cursor);
    if (cursor_line < st.scroll_line) {
        st.scroll_line = cursor_line;
    }
    const last_visible = st.scroll_line + st.visible_lines - 1;
    if (cursor_line > last_visible) {
        st.scroll_line = cursor_line - (st.visible_lines - 1);
    }
}

fn inputHandleArrow(st: *InputState, arrow: events.ArrowKey) bool {
    switch (arrow) {
        .left => {
            if (st.cursor > 0) {
                st.cursor -= 1;
                return true;
            }
        },
        .right => {
            if (st.cursor < st.buf.items.len) {
                st.cursor += 1;
                return true;
            }
        },
        .up => {
            return inputMoveCursorVertical(st, true);
        },
        .down => {
            return inputMoveCursorVertical(st, false);
        },
    }
    return false;
}

fn inputHandleCodepoint(st: *InputState, cp: u21) bool {
    switch (cp) {
        8 => return inputBackspace(st),
        127 => return inputDelete(st),
        '\n' => {
            if (st.multiline) {
                return inputInsert(st, '\n');
            }
            return false;
        },
        else => {
            if (cp < 32 or cp > 126) return false;
            return inputInsert(st, @as(u8, @intCast(cp)));
        },
    }
}

fn inputMoveCursorVertical(st: *InputState, up: bool) bool {
    if (!st.multiline) return false;
    const cursor_line = inputLineNumber(st.buf.items, st.cursor);
    const total_lines = inputLineNumber(st.buf.items, st.buf.items.len) + 1;
    if (up and cursor_line == 0) return false;
    if (!up and cursor_line + 1 >= total_lines) return false;
    const target_line: usize = if (up) cursor_line - 1 else cursor_line + 1;
    const current_col = st.cursor - inputLineStart(st.buf.items, cursor_line);
    const target_start = inputLineStart(st.buf.items, target_line);
    const target_end = inputLineEnd(st.buf.items, target_start);
    st.cursor = target_start + @min(current_col, target_end - target_start);
    return true;
}

fn inputInsert(st: *InputState, byte: u8) bool {
    if (st.max_length != 0 and st.buf.items.len >= st.max_length) return false;
    st.buf.insert(st.gpa, st.cursor, byte) catch return false;
    st.cursor += 1;
    return true;
}

fn inputBackspace(st: *InputState) bool {
    if (st.cursor == 0) return false;
    _ = st.buf.orderedRemove(st.cursor - 1);
    st.cursor -= 1;
    return true;
}

fn inputDelete(st: *InputState) bool {
    if (st.cursor >= st.buf.items.len) return false;
    _ = st.buf.orderedRemove(st.cursor);
    return true;
}

fn inputLineNumber(buf: []const u8, index: usize) usize {
    var i: usize = 0;
    var line: usize = 0;
    const capped = @min(index, buf.len);
    while (i < capped) : (i += 1) {
        if (buf[i] == '\n') line += 1;
    }
    return line;
}

fn inputLineStart(buf: []const u8, target_line: usize) usize {
    var line: usize = 0;
    var idx: usize = 0;
    while (idx < buf.len and line < target_line) : (idx += 1) {
        if (buf[idx] == '\n') {
            line += 1;
            if (line == target_line) {
                idx += 1;
                break;
            }
        }
    }
    if (line < target_line) return buf.len;
    return idx;
}

fn inputLineEnd(buf: []const u8, start: usize) usize {
    var idx = @min(start, buf.len);
    while (idx < buf.len and buf[idx] != '\n') : (idx += 1) {}
    return idx;
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

pub fn checkboxFramed(allocator: std.mem.Allocator, opts: options.CheckboxOptions, frame_opts: options.FrameOptions) !base.Component {
    const inner = try checkbox(allocator, opts);
    return frameDecorator(allocator, inner, frame_opts);
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

pub fn toggleFramed(allocator: std.mem.Allocator, opts: options.ToggleOptions, frame_opts: options.FrameOptions) !base.Component {
    const inner = try toggle(allocator, opts);
    return frameDecorator(allocator, inner, frame_opts);
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

pub fn radioGroupFramed(allocator: std.mem.Allocator, opts: options.RadioOptions, frame_opts: options.FrameOptions) !base.Component {
    const inner = try radioGroup(allocator, opts);
    return frameDecorator(allocator, inner, frame_opts);
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

pub fn dropdown(allocator: std.mem.Allocator, opts: options.DropdownOptions) !base.Component {
    const items_copy = try allocator.alloc([]const u8, opts.items.len);
    for (opts.items, 0..) |item_text, i| {
        items_copy[i] = try allocator.dupe(u8, item_text);
    }

    const placeholder_copy = try allocator.dupe(u8, opts.placeholder);
    const initial_index: ?usize = if (opts.items.len == 0) null else @min(opts.selected_index, opts.items.len - 1);
    const state_ptr = try allocator.create(DropdownState);
    state_ptr.* = .{
        .items = items_copy,
        .selected_index = initial_index,
        .is_open = opts.is_open and opts.items.len > 0,
        .placeholder = placeholder_copy,
        .allocator = allocator,
        .custom_renderer = opts.custom_renderer,
    };
    state_ptr.ensureSelection();

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = dropdownRender,
        .eventFn = dropdownEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = state_ptr.selected_index orelse 0,
    };
    return .{ .base = component_ptr };
}

pub fn dropdownCustom(allocator: std.mem.Allocator, opts: options.DropdownOptions, renderer_fn: options.DropdownRenderFn) !base.Component {
    var derived = opts;
    derived.custom_renderer = renderer_fn;
    return dropdown(allocator, derived);
}

pub fn tabHorizontal(allocator: std.mem.Allocator, opts: options.TabsOptions) !base.Component {
    var derived = opts;
    derived.orientation = .horizontal;
    return tabs(allocator, derived);
}

pub fn tabVertical(allocator: std.mem.Allocator, opts: options.TabsOptions) !base.Component {
    var derived = opts;
    derived.orientation = .vertical;
    return tabs(allocator, derived);
}

fn tabs(allocator: std.mem.Allocator, opts: options.TabsOptions) !base.Component {
    const labels_copy = try allocator.alloc([]const u8, opts.labels.len);
    for (opts.labels, 0..) |tab_label, idx| {
        labels_copy[idx] = try allocator.dupe(u8, tab_label);
    }
    const selected = if (opts.labels.len == 0) 0 else @min(opts.selected_index, opts.labels.len - 1);
    const state_ptr = try allocator.create(TabsState);
    state_ptr.* = .{
        .labels = labels_copy,
        .selected_index = selected,
        .orientation = opts.orientation,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = tabsRender,
        .eventFn = tabsEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = selected,
    };
    return .{ .base = component_ptr };
}

fn tabsRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*TabsState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.labels.len == 0) {
        try stdout.writeAll("(tabs unavailable)\n");
        return;
    }
    switch (state.orientation) {
        .horizontal => {
            for (state.labels, 0..) |tab_label, idx| {
                if (idx > 0) try stdout.writeAll("|");
                if (idx == state.selected_index) {
                    var buf: [96]u8 = undefined;
                    const msg = try std.fmt.bufPrint(&buf, "[{s}]", .{tab_label});
                    try stdout.writeAll(msg);
                } else {
                    var buf: [96]u8 = undefined;
                    const msg = try std.fmt.bufPrint(&buf, "  {s}  ", .{tab_label});
                    try stdout.writeAll(msg);
                }
            }
            try stdout.writeAll("\n");
        },
        .vertical => {
            for (state.labels, 0..) |tab_label, idx| {
                const marker = if (idx == state.selected_index) ">" else " ";
                var buf: [96]u8 = undefined;
                const msg = try std.fmt.bufPrint(&buf, "{s} {s}\n", .{ marker, tab_label });
                try stdout.writeAll(msg);
            }
        },
    }
}

fn tabsEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*TabsState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (k.arrow_key) |arrow| {
                switch (state.orientation) {
                    .horizontal => {
                        if (arrow == .left and state.selected_index > 0) {
                            state.selected_index -= 1;
                            self.focus_index = state.selected_index;
                            return true;
                        }
                        if (arrow == .right and state.selected_index + 1 < state.labels.len) {
                            state.selected_index += 1;
                            self.focus_index = state.selected_index;
                            return true;
                        }
                    },
                    .vertical => {
                        if (arrow == .up and state.selected_index > 0) {
                            state.selected_index -= 1;
                            self.focus_index = state.selected_index;
                            return true;
                        }
                        if (arrow == .down and state.selected_index + 1 < state.labels.len) {
                            state.selected_index += 1;
                            self.focus_index = state.selected_index;
                            return true;
                        }
                    },
                }
            }
        },
        .custom => |c| {
            if (std.mem.eql(u8, c.tag, "tabs:next")) {
                if (state.selected_index + 1 < state.labels.len) {
                    state.selected_index += 1;
                    return true;
                }
            } else if (std.mem.eql(u8, c.tag, "tabs:prev")) {
                if (state.selected_index > 0) {
                    state.selected_index -= 1;
                    return true;
                }
            }
        },
        else => {},
    }
    return false;
}

pub fn scrollbar(allocator: std.mem.Allocator, opts: options.ScrollbarOptions) !base.Component {
    const state_ptr = try allocator.create(ScrollbarState);
    state_ptr.* = .{
        .content_length = opts.content_length,
        .viewport_length = opts.viewport_length,
        .position = opts.position,
        .orientation = opts.orientation,
    };
    scrollbarClamp(state_ptr);

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = scrollbarRender,
        .eventFn = scrollbarEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn scrollbarRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*ScrollbarState, @ptrCast(@alignCast(self.user_data.?)));
    const track_len: usize = if (state.orientation == .horizontal) 20 else 10;
    const knob = scrollbarKnob(state, track_len);
    if (state.orientation == .horizontal) {
        var idx: usize = 0;
        while (idx < track_len) : (idx += 1) {
            if (idx >= knob.start and idx < knob.end) {
                try stdout.writeAll("#");
            } else {
                try stdout.writeAll("-");
            }
        }
        try stdout.writeAll("\n");
    } else {
        var idx: usize = 0;
        while (idx < track_len) : (idx += 1) {
            if (idx >= knob.start and idx < knob.end) {
                try stdout.writeAll("|\n");
            } else {
                try stdout.writeAll(".\n");
            }
        }
    }
}

fn scrollbarEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*ScrollbarState, @ptrCast(@alignCast(self.user_data.?)));
    var consumed = false;
    switch (event) {
        .key => |k| {
            if (k.arrow_key) |arrow| {
                consumed = scrollbarHandleArrow(state, arrow);
            }
        },
        .custom => |c| {
            if (std.mem.eql(u8, c.tag, "scroll:start")) {
                state.position = 0;
                consumed = true;
            } else if (std.mem.eql(u8, c.tag, "scroll:end")) {
                state.position = scrollbarMaxPosition(state);
                consumed = true;
            }
        },
        else => {},
    }
    if (consumed) scrollbarClamp(state);
    return consumed;
}

fn scrollbarHandleArrow(state: *ScrollbarState, arrow: events.ArrowKey) bool {
    switch (state.orientation) {
        .horizontal => {
            if (arrow == .left) return scrollbarAdvance(state, -1);
            if (arrow == .right) return scrollbarAdvance(state, 1);
        },
        .vertical => {
            if (arrow == .up) return scrollbarAdvance(state, -1);
            if (arrow == .down) return scrollbarAdvance(state, 1);
        },
    }
    return false;
}

fn scrollbarAdvance(state: *ScrollbarState, delta: i32) bool {
    const max_pos = scrollbarMaxPosition(state);
    const current = @as(i32, @intCast(state.position));
    var next = current + delta;
    if (next < 0) next = 0;
    if (next > @as(i32, @intCast(max_pos))) next = @as(i32, @intCast(max_pos));
    if (next == current) return false;
    state.position = @as(usize, @intCast(next));
    return true;
}

fn scrollbarClamp(state: *ScrollbarState) void {
    if (state.viewport_length > state.content_length) {
        state.viewport_length = state.content_length;
    }
    const max_pos = scrollbarMaxPosition(state);
    if (state.position > max_pos) {
        state.position = max_pos;
    }
}

fn scrollbarMaxPosition(state: *ScrollbarState) usize {
    if (state.content_length == 0 or state.viewport_length >= state.content_length) return 0;
    return state.content_length - state.viewport_length;
}

const ScrollbarKnob = struct { start: usize, end: usize };

fn scrollbarKnob(state: *ScrollbarState, track_len: usize) ScrollbarKnob {
    if (track_len == 0 or state.content_length == 0) return .{ .start = 0, .end = track_len };
    const total = if (state.content_length == 0) 1 else state.content_length;
    const knob_len = @max(@as(usize, 1), (state.viewport_length * track_len) / @max(total, 1));
    const max_offset = scrollbarMaxPosition(state);
    const ratio = if (max_offset == 0) 0 else @as(f32, @floatFromInt(state.position)) / @as(f32, @floatFromInt(max_offset));
    const range = if (track_len > knob_len) track_len - knob_len else 0;
    const start = @as(usize, @intFromFloat(@floor(@as(f32, @floatFromInt(range)) * ratio)));
    return .{ .start = start, .end = @min(track_len, start + knob_len) };
}

fn dropdownRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*DropdownState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.custom_renderer) |hook| {
        try hook(.{
            .items = state.items,
            .selected_index = state.selected_index,
            .is_open = state.is_open,
            .placeholder = state.placeholder,
        });
        return;
    }
    const display_label = state.currentLabel();

    try stdout.writeAll("[");
    if (display_label.len > 0) {
        try stdout.writeAll(display_label);
    } else if (state.placeholder.len > 0) {
        try stdout.writeAll(state.placeholder);
    } else {
        try stdout.writeAll("(none)");
    }
    if (state.is_open) {
        try stdout.writeAll(" ^]");
    } else {
        try stdout.writeAll(" v]");
    }

    if (!state.is_open) return;

    if (state.items.len == 0) {
        try stdout.writeAll("\n  (no items)");
        return;
    }

    for (state.items, 0..) |item_text, i| {
        try stdout.writeAll("\n");
        if (state.selected_index != null and state.selected_index.? == i) {
            try stdout.writeAll("> ");
        } else {
            try stdout.writeAll("  ");
        }
        try stdout.writeAll(item_text);
    }
}

fn dropdownEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*DropdownState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (k.arrow_key) |arrow| {
                if (state.is_open and state.items.len > 0) {
                    const delta: i32 = switch (arrow) {
                        .up => -1,
                        .down => 1,
                        .left, .right => 0,
                    };
                    if (delta != 0 and dropdownMove(state, delta)) {
                        self.focus_index = state.selected_index orelse 0;
                        return true;
                    }
                }
            }
            if (k.codepoint) |cp| {
                switch (cp) {
                    ' ', '\n' => {
                        dropdownToggle(state);
                        self.focus_index = state.selected_index orelse 0;
                        return true;
                    },
                    27 => { // escape closes menu
                        if (state.is_open) {
                            state.is_open = false;
                            return true;
                        }
                    },
                    else => {},
                }
            }
        },
        else => {},
    }
    return false;
}

fn dropdownMove(state: *DropdownState, delta: i32) bool {
    state.ensureSelection();
    if (state.selected_index == null or state.items.len == 0) return false;
    const current = state.selected_index.?;
    if (delta > 0) {
        if (current >= state.items.len - 1) return false;
        state.selected_index = current + 1;
        return true;
    } else if (delta < 0) {
        if (current == 0) return false;
        state.selected_index = current - 1;
        return true;
    }
    return false;
}

fn dropdownToggle(state: *DropdownState) void {
    if (state.items.len == 0) {
        state.is_open = false;
        state.selected_index = null;
        return;
    }
    state.is_open = !state.is_open;
    if (state.is_open) {
        state.ensureSelection();
    }
}

pub fn menu(allocator: std.mem.Allocator, opts: options.MenuOptions) !base.Component {
    const items_copy = try allocator.alloc([]const u8, opts.items.len);
    for (opts.items, 0..) |item, idx| {
        items_copy[idx] = try allocator.dupe(u8, item);
    }
    const selected = if (opts.items.len == 0) 0 else @min(opts.selected_index, opts.items.len - 1);
    const selections = try allocator.alloc(bool, if (opts.multi_select) opts.items.len else 0);
    if (opts.multi_select) {
        if (opts.selected_flags) |flags| {
            for (selections, 0..) |*sel, idx| {
                sel.* = if (idx < flags.len) flags[idx] else false;
            }
        } else {
            @memset(selections, false);
        }
    }
    const state_ptr = try allocator.create(MenuState);
    state_ptr.* = .{
        .items = items_copy,
        .selected_index = selected,
        .loop_navigation = opts.loop_navigation,
        .highlight_color = opts.highlight_color,
        .animation_enabled = opts.animation_enabled,
        .multi_select = opts.multi_select,
        .selections = selections,
        .underline_gallery = opts.underline_gallery,
        .custom_renderer = opts.custom_renderer,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = menuRender,
        .eventFn = menuEvent,
        .animationFn = menuAnimate,
        .children = &[_]base.Component{},
        .focus_index = selected,
    };
    return .{ .base = component_ptr };
}

pub fn menuCustom(allocator: std.mem.Allocator, opts: options.MenuOptions, renderer_fn: options.MenuRenderFn) !base.Component {
    var derived = opts;
    derived.custom_renderer = renderer_fn;
    return menu(allocator, derived);
}

fn menuRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*MenuState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.custom_renderer) |hook| {
        try hook(.{
            .items = state.items,
            .selected_index = state.selected_index,
            .selected_flags = if (state.multi_select) state.selections else null,
            .underline_gallery = state.underline_gallery,
            .highlight_color = state.highlight_color,
            .phase = state.phase,
        });
        return;
    }
    if (state.items.len == 0) {
        try stdout.writeAll("(empty menu)\n");
        return;
    }
    for (state.items, 0..) |item, idx| {
        const active = idx == state.selected_index;
        const pulse = if (state.animation_enabled and active and state.phase > 0.5) "*" else ">";
        if (state.multi_select) {
            const chosen = if (idx < state.selections.len) state.selections[idx] else false;
            const box = if (chosen) "[x]" else "[ ]";
            var buf_multi: [128]u8 = undefined;
            const msg_multi = try std.fmt.bufPrint(&buf_multi, "{s} {s} {s}\n", .{ pulse, box, item });
            try stdout.writeAll(msg_multi);
        } else if (active) {
            var buf: [96]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buf, "{s} {s} (0x{X:0>6})\n", .{ pulse, item, state.highlight_color });
            try stdout.writeAll(msg);
        } else {
            try stdout.writeAll("  ");
            try stdout.writeAll(item);
            try stdout.writeAll("\n");
        }
        if (state.underline_gallery) {
            const underline_char: u8 = if (state.phase > 0.5) '=' else '-';
            try stdout.writeAll("   ");
            try writeRepeating(stdout, underline_char, item.len);
            try stdout.writeAll("\n");
        }
    }
}

fn menuEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*MenuState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (state.items.len == 0) return false;
            if (k.arrow_key) |arrow| {
                const delta: i32 = switch (arrow) {
                    .up => -1,
                    .down => 1,
                    .left, .right => 0,
                };
                if (delta != 0 and menuMove(state, delta)) {
                    self.focus_index = state.selected_index;
                    return true;
                }
            }
            if (k.codepoint) |cp| {
                if (cp == '\n') {
                    return true;
                }
                if (cp == ' ' and state.multi_select) {
                    if (state.selected_index < state.selections.len) {
                        state.selections[state.selected_index] = !state.selections[state.selected_index];
                        return true;
                    }
                }
            }
        },
        .custom => |c| {
            if (std.mem.eql(u8, c.tag, "menu:select_all") and state.multi_select) {
                for (state.selections) |*flag| flag.* = true;
                return true;
            }
            if (std.mem.eql(u8, c.tag, "menu:clear") and state.multi_select) {
                for (state.selections) |*flag| flag.* = false;
                return true;
            }
        },
        else => {},
    }
    return false;
}

fn menuMove(state: *MenuState, delta: i32) bool {
    if (state.items.len == 0) return false;
    const count_i32 = @as(i32, @intCast(state.items.len));
    var next = @as(i32, @intCast(state.selected_index)) + delta;
    if (state.loop_navigation and count_i32 > 0) {
        next = @mod(next + count_i32, count_i32);
    } else {
        next = @max(0, @min(next, count_i32 - 1));
    }
    const new_index = @as(usize, @intCast(next));
    if (new_index == state.selected_index) return false;
    state.selected_index = new_index;
    return true;
}

fn menuAnimate(self: *base.ComponentBase, delta_time: f32) void {
    const state = @as(*MenuState, @ptrCast(@alignCast(self.user_data.?)));
    if (!state.animation_enabled) return;
    state.phase += delta_time * 2.0;
    if (state.phase >= 1.0) {
        state.phase -= std.math.floor(state.phase);
    }
}

pub fn split(allocator: std.mem.Allocator, first: base.Component, second: base.Component, opts: options.SplitOptions) !base.Component {
    const children = try allocator.alloc(base.Component, 2);
    children[0] = first;
    children[1] = second;
    const clamped_ratio = std.math.clamp(opts.ratio, opts.min_ratio, opts.max_ratio);
    const state_ptr = try allocator.create(SplitState);
    state_ptr.* = .{
        .children = children,
        .ratio = clamped_ratio,
        .min_ratio = opts.min_ratio,
        .max_ratio = opts.max_ratio,
        .orientation = opts.orientation,
        .handle = try allocator.dupe(u8, opts.handle),
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = splitRender,
        .eventFn = splitEvent,
        .animationFn = null,
        .children = children,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn splitRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*SplitState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.children.len < 2) return;
    try state.children[0].render();
    try stdout.writeAll("\n");
    var buf: [64]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "{s} ratio={d:.2}", .{ state.handle, state.ratio });
    try stdout.writeAll(msg);
    try stdout.writeAll("\n");
    try state.children[1].render();
}

fn splitEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*SplitState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (k.arrow_key) |arrow| {
                const delta: f32 = switch (state.orientation) {
                    .horizontal => switch (arrow) {
                        .left => -0.05,
                        .right => 0.05,
                        else => 0.0,
                    },
                    .vertical => switch (arrow) {
                        .up => -0.05,
                        .down => 0.05,
                        else => 0.0,
                    },
                };
                if (delta != 0.0) {
                    return splitAdjust(state, delta);
                }
            }
        },
        .custom => |c| {
            if (std.mem.eql(u8, c.tag, "split:clamp:min")) {
                state.ratio = state.min_ratio;
                return true;
            }
            if (std.mem.eql(u8, c.tag, "split:clamp:max")) {
                state.ratio = state.max_ratio;
                return true;
            }
            if (std.mem.eql(u8, c.tag, "split:center")) {
                state.ratio = (state.min_ratio + state.max_ratio) / 2.0;
                return true;
            }
        },
        else => {},
    }
    return false;
}

fn splitAdjust(state: *SplitState, delta: f32) bool {
    const next = std.math.clamp(state.ratio + delta, state.min_ratio, state.max_ratio);
    if (next == state.ratio) return false;
    state.ratio = next;
    return true;
}

pub fn splitWithClampIndicator(allocator: std.mem.Allocator, first: base.Component, second: base.Component, opts: options.SplitOptions) !base.Component {
    const core = try split(allocator, first, second, opts);
    var buf: [96]u8 = undefined;
    const caption = try std.fmt.bufPrint(&buf, "split {d:.2}-{d:.2}", .{ opts.min_ratio, opts.max_ratio });
    return frameDecorator(allocator, core, .{ .title = caption, .charset = .double });
}

pub fn windowComposition(allocator: std.mem.Allocator, windows: []const base.Component, title: []const u8) !base.Component {
    const layout = try container(allocator, windows);
    return frameDecorator(allocator, layout, .{ .title = title, .charset = .single });
}

pub fn homescreen(allocator: std.mem.Allocator, header: []const u8, sections: []const []const u8, windows: []const base.Component) !base.Component {
    const window_copy = try allocator.dupe(base.Component, windows);
    const sections_copy = try allocator.alloc([]const u8, sections.len);
    for (sections, 0..) |entry, idx| {
        sections_copy[idx] = try allocator.dupe(u8, entry);
    }
    const header_copy = try allocator.dupe(u8, header);
    const state_ptr = try allocator.create(HomescreenState);
    state_ptr.* = .{ .sections = sections_copy, .windows = window_copy, .header = header_copy };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = homescreenRender,
        .eventFn = homescreenEvent,
        .animationFn = null,
        .children = window_copy,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn homescreenRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*HomescreenState, @ptrCast(@alignCast(self.user_data.?)));
    try stdout.writeAll(state.header);
    try stdout.writeAll("\n");
    for (state.windows, 0..) |win, idx| {
        try stdout.writeAll("-- window ");
        var buf: [32]u8 = undefined;
        const line = try std.fmt.bufPrint(&buf, "#{d}\n", .{idx + 1});
        try stdout.writeAll(line);
        try win.render();
        try stdout.writeAll("\n");
    }
    if (state.sections.len > 0) {
        try stdout.writeAll("Sections:\n");
        for (state.sections, 0..) |entry, idx| {
            var buf: [128]u8 = undefined;
            const msg = try std.fmt.bufPrint(&buf, "  {d}. {s}\n", .{ idx + 1, entry });
            try stdout.writeAll(msg);
        }
    }
}

fn homescreenEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*HomescreenState, @ptrCast(@alignCast(self.user_data.?)));
    for (state.windows) |child| {
        if (child.onEvent(event)) return true;
    }
    return false;
}

pub fn visualGallery(allocator: std.mem.Allocator, caption: []const u8) !base.Component {
    const state_ptr = try allocator.create(GalleryState);
    state_ptr.* = .{ .caption = try allocator.dupe(u8, caption), .canvas_demo = try allocator.dupe(u8, "canvas demo\n+---+\n|***|\n+---+"), .gradient_demo = try allocator.dupe(u8, "gradient demo\n>>>>====<<<<"), .hover_demo = try allocator.dupe(u8, "hover gallery\n[hover to highlight]"), .focus_demo = try allocator.dupe(u8, "focus gallery\n(cursor jumps)") };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = galleryRender,
        .eventFn = galleryEvent,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn galleryRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*GalleryState, @ptrCast(@alignCast(self.user_data.?)));
    try stdout.writeAll(state.caption);
    try stdout.writeAll("\n====\n");
    try stdout.writeAll(state.canvas_demo);
    try stdout.writeAll("\n----\n");
    try stdout.writeAll(state.gradient_demo);
    try stdout.writeAll("\n----\n");
    try stdout.writeAll(state.hover_demo);
    try stdout.writeAll("\n----\n");
    try stdout.writeAll(state.focus_demo);
    try stdout.writeAll("\n");
}

fn galleryEvent(self: *base.ComponentBase, event: events.Event) bool {
    _ = self;
    _ = event;
    return false;
}

pub fn modal(allocator: std.mem.Allocator, child: base.Component, opts: options.ModalOptions) !base.Component {
    const child_list = try allocator.alloc(base.Component, 1);
    child_list[0] = child;
    const title_copy = try allocator.dupe(u8, opts.title);
    const state_ptr = try allocator.create(ModalState);
    state_ptr.* = .{
        .child = child,
        .title = title_copy,
        .is_open = opts.is_open,
        .dismissible = opts.dismissible,
        .width = opts.width,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = modalRender,
        .eventFn = modalEvent,
        .animationFn = null,
        .children = child_list,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn modalRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*ModalState, @ptrCast(@alignCast(self.user_data.?)));
    if (!state.is_open) return;
    const min_width: usize = state.title.len + 4;
    const width = @max(state.width, min_width);

    try stdout.writeAll("+");
    try writeRepeating(stdout, '-', width - 2);
    try stdout.writeAll("+\n");

    try stdout.writeAll("| ");
    try stdout.writeAll(state.title);
    if (width > state.title.len + 3) {
        try writeRepeating(stdout, ' ', width - state.title.len - 3);
    }
    try stdout.writeAll("|\n");

    try state.child.render();

    try stdout.writeAll("+");
    try writeRepeating(stdout, '-', width - 2);
    try stdout.writeAll("+\n");
}

fn writeRepeating(file: std.fs.File, ch: u8, count: usize) !void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        try file.writeAll(&[_]u8{ch});
    }
}

fn modalEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*ModalState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (state.is_open) {
                if (k.codepoint) |cp| {
                    if (cp == 27 and state.dismissible) {
                        state.is_open = false;
                        return true;
                    }
                }
            } else {
                if (k.codepoint) |cp| {
                    if (cp == '\n' or cp == ' ') {
                        state.is_open = true;
                        return true;
                    }
                }
            }
        },
        else => {},
    }
    if (state.is_open) {
        return state.child.onEvent(event);
    }
    return false;
}

pub fn collapsible(allocator: std.mem.Allocator, child: base.Component, opts: options.CollapsibleOptions) !base.Component {
    const child_list = try allocator.alloc(base.Component, 1);
    child_list[0] = child;
    const label_copy = try allocator.dupe(u8, opts.label);
    const indicator_open = try allocator.dupe(u8, opts.indicator_open);
    const indicator_closed = try allocator.dupe(u8, opts.indicator_closed);
    const state_ptr = try allocator.create(CollapsibleState);
    state_ptr.* = .{
        .child = child,
        .label = label_copy,
        .expanded = opts.expanded,
        .indicator_open = indicator_open,
        .indicator_closed = indicator_closed,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = collapsibleRender,
        .eventFn = collapsibleEvent,
        .animationFn = null,
        .children = child_list,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn collapsibleRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*CollapsibleState, @ptrCast(@alignCast(self.user_data.?)));
    const indicator = if (state.expanded) state.indicator_open else state.indicator_closed;
    var buf: [128]u8 = undefined;
    const line = try std.fmt.bufPrint(&buf, "{s} {s}\n", .{ indicator, state.label });
    try stdout.writeAll(line);
    if (state.expanded) {
        try state.child.render();
    }
}

fn collapsibleEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*CollapsibleState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (k.codepoint) |cp| {
                if (cp == ' ' or cp == '\n') {
                    state.expanded = !state.expanded;
                    return true;
                }
            }
        },
        else => {},
    }
    if (state.expanded) {
        return state.child.onEvent(event);
    }
    return false;
}

pub fn hoverWrapper(allocator: std.mem.Allocator, child: base.Component, opts: options.HoverOptions) !base.Component {
    const child_list = try allocator.alloc(base.Component, 1);
    child_list[0] = child;
    const hover_copy = try allocator.dupe(u8, opts.hover_text);
    const idle_copy = try allocator.dupe(u8, opts.idle_text);
    const state_ptr = try allocator.create(HoverState);
    state_ptr.* = .{
        .child = child,
        .hover_text = hover_copy,
        .idle_text = idle_copy,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = hoverRender,
        .eventFn = hoverEvent,
        .animationFn = null,
        .children = child_list,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn hoverRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*HoverState, @ptrCast(@alignCast(self.user_data.?)));
    try state.child.render();
    const suffix = if (state.hovered) state.hover_text else state.idle_text;
    if (suffix.len > 0) {
        try stdout.writeAll("\n");
        try stdout.writeAll(suffix);
        try stdout.writeAll("\n");
    } else {
        try stdout.writeAll("\n");
    }
}

fn hoverEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*HoverState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .mouse => {
            state.hovered = true;
            _ = state.child.onEvent(event);
            return true;
        },
        .custom => |c| {
            if (std.mem.eql(u8, c.tag, "hover:leave")) {
                state.hovered = false;
                return true;
            }
        },
        else => {},
    }
    if (state.hovered) {
        return state.child.onEvent(event);
    }
    return false;
}

pub fn window(allocator: std.mem.Allocator, child: base.Component, opts: options.WindowOptions) !base.Component {
    const child_list = try allocator.alloc(base.Component, 1);
    child_list[0] = child;
    const title_copy = try allocator.dupe(u8, opts.title);
    const state_ptr = try allocator.create(WindowState);
    state_ptr.* = .{
        .child = child,
        .title = title_copy,
        .border = opts.border,
    };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = windowRender,
        .eventFn = windowEvent,
        .animationFn = null,
        .children = child_list,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn windowRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*WindowState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.border) {
        try stdout.writeAll("+ ");
        try stdout.writeAll(state.title);
        try stdout.writeAll(" +\n");
    } else {
        try stdout.writeAll("[");
        try stdout.writeAll(state.title);
        try stdout.writeAll("]\n");
    }
    try state.child.render();
    if (state.border) {
        try stdout.writeAll("+-----+\n");
    }
}

fn windowEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*WindowState, @ptrCast(@alignCast(self.user_data.?)));
    return state.child.onEvent(event);
}

fn frameDecorator(allocator: std.mem.Allocator, child: base.Component, opts: options.FrameOptions) !base.Component {
    const child_list = try allocator.alloc(base.Component, 1);
    child_list[0] = child;
    const title_copy = try allocator.dupe(u8, opts.title);
    const state_ptr = try allocator.create(FrameWrapperState);
    state_ptr.* = .{ .child = child, .options = .{ .title = title_copy, .charset = opts.charset } };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = frameDecoratorRender,
        .eventFn = frameDecoratorEvent,
        .animationFn = null,
        .children = child_list,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn frameDecoratorRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*FrameWrapperState, @ptrCast(@alignCast(self.user_data.?)));
    const glyphs = frameGlyphs(state.options.charset);
    const min_width: usize = @max(state.options.title.len + 4, 12);
    try stdout.writeAll(&[_]u8{glyphs.corner});
    try writeRepeating(stdout, glyphs.horiz, min_width);
    try stdout.writeAll(&[_]u8{glyphs.corner});
    try stdout.writeAll("\n");
    if (state.options.title.len > 0) {
        try stdout.writeAll(&[_]u8{glyphs.vert});
        try stdout.writeAll(" ");
        try stdout.writeAll(state.options.title);
        if (min_width + 1 > state.options.title.len + 1) {
            try writeRepeating(stdout, ' ', min_width - state.options.title.len);
        }
        try stdout.writeAll(" ");
        try stdout.writeAll(&[_]u8{glyphs.vert});
        try stdout.writeAll("\n");
    }
    try state.child.render();
    try stdout.writeAll(&[_]u8{glyphs.corner});
    try writeRepeating(stdout, glyphs.horiz, min_width);
    try stdout.writeAll(&[_]u8{glyphs.corner});
    try stdout.writeAll("\n");
}

fn frameDecoratorEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*FrameWrapperState, @ptrCast(@alignCast(self.user_data.?)));
    return state.child.onEvent(event);
}

const FrameGlyphs = struct {
    horiz: u8,
    vert: u8,
    corner: u8,
};

fn frameGlyphs(charset: options.FrameCharset) FrameGlyphs {
    return switch (charset) {
        .single => .{ .horiz = '-', .vert = '|', .corner = '+' },
        .double => .{ .horiz = '=', .vert = '#', .corner = '*' },
    };
}

pub fn renderer(allocator: std.mem.Allocator, child: base.Component, render_fn: RendererFn) !base.Component {
    const child_list = try allocator.alloc(base.Component, 1);
    child_list[0] = child;
    const state_ptr = try allocator.create(RendererDecoratorState);
    state_ptr.* = .{ .child = child, .renderFn = render_fn, .show_child = false };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = rendererDecoratorRender,
        .eventFn = rendererDecoratorEvent,
        .animationFn = null,
        .children = child_list,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn rendererDecoratorRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*RendererDecoratorState, @ptrCast(@alignCast(self.user_data.?)));
    try state.renderFn(.{ .stdout = stdout, .child = state.child });
    if (state.show_child) {
        try stdout.writeAll("\n");
        try state.child.render();
    }
}

fn rendererDecoratorEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*RendererDecoratorState, @ptrCast(@alignCast(self.user_data.?)));
    return state.child.onEvent(event);
}

pub fn maybe(allocator: std.mem.Allocator, child: base.Component, visible: bool) !base.Component {
    const child_list = try allocator.alloc(base.Component, 1);
    child_list[0] = child;
    const state_ptr = try allocator.create(MaybeState);
    state_ptr.* = .{ .child = child, .visible = visible };

    const component_ptr = try allocator.create(base.ComponentBase);
    component_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(state_ptr)),
        .renderFn = maybeRender,
        .eventFn = maybeEvent,
        .animationFn = null,
        .children = child_list,
        .focus_index = 0,
    };
    return .{ .base = component_ptr };
}

fn maybeRender(self: *base.ComponentBase) anyerror!void {
    const stdout = std.fs.File.stdout();
    const state = @as(*MaybeState, @ptrCast(@alignCast(self.user_data.?)));
    if (state.visible) {
        try state.child.render();
    } else {
        try stdout.writeAll("(hidden component)\n");
    }
}

fn maybeEvent(self: *base.ComponentBase, event: events.Event) bool {
    const state = @as(*MaybeState, @ptrCast(@alignCast(self.user_data.?)));
    switch (event) {
        .key => |k| {
            if (k.codepoint) |cp| {
                if (cp == ' ') {
                    state.visible = !state.visible;
                    return true;
                }
            }
        },
        .custom => |c| {
            if (std.mem.eql(u8, c.tag, "maybe:show")) {
                state.visible = true;
                return true;
            }
            if (std.mem.eql(u8, c.tag, "maybe:hide")) {
                state.visible = false;
                return true;
            }
        },
        else => {},
    }
    if (state.visible) {
        return state.child.onEvent(event);
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

test "dropdown toggles open state and closes with escape" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const items = [_][]const u8{ "Alpha", "Beta" };
    const dd = try dropdown(allocator, .{ .items = &items, .placeholder = "Select" });
    const state = @as(*DropdownState, @ptrCast(@alignCast(dd.base.user_data.?)));

    try std.testing.expect(!state.is_open);
    const toggled = dd.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try std.testing.expect(toggled);
    try std.testing.expect(state.is_open);

    const closed = dd.onEvent(.{ .key = .{ .codepoint = 27 } });
    try std.testing.expect(closed);
    try std.testing.expect(!state.is_open);
}

test "dropdown arrow navigation only works when open" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const items = [_][]const u8{ "Alpha", "Beta", "Gamma" };
    const dd = try dropdown(allocator, .{ .items = &items, .selected_index = 0 });
    const state = @as(*DropdownState, @ptrCast(@alignCast(dd.base.user_data.?)));

    // Closed state should ignore arrows
    const ignored = dd.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expect(!ignored);
    try std.testing.expectEqual(@as(usize, 0), state.selected_index.?);

    _ = dd.onEvent(.{ .key = .{ .codepoint = '\n' } }); // open
    _ = dd.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 1), state.selected_index.?);
    _ = dd.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 2), state.selected_index.?);

    // Should clamp at last item
    const clamped = dd.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expect(!clamped);
    try std.testing.expectEqual(@as(usize, 2), state.selected_index.?);
}

test "dropdown handles empty item list with placeholder" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const dd = try dropdown(allocator, .{ .items = &[_][]const u8{}, .placeholder = "None" });
    const state = @as(*DropdownState, @ptrCast(@alignCast(dd.base.user_data.?)));

    try std.testing.expect(state.selected_index == null);
    try std.testing.expectEqualStrings("None", state.placeholder);

    const toggled = dd.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try std.testing.expect(!state.is_open);
    try std.testing.expect(toggled); // still consumed even if no items (closes immediately)
}

test "menu navigation loops and animates" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const items = [_][]const u8{ "One", "Two" };
    const menu_component = try menu(allocator, .{ .items = &items, .selected_index = 0 });
    const state = @as(*MenuState, @ptrCast(@alignCast(menu_component.base.user_data.?)));

    try std.testing.expectEqual(@as(usize, 0), state.selected_index);
    _ = menu_component.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 1), state.selected_index);
    _ = menu_component.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 0), state.selected_index);

    menu_component.base.animate(0.3);
    try std.testing.expect(state.phase > 0);
}

test "split adjusts ratio with orientation aware arrows" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const left = try label(allocator, "Left");
    const right = try label(allocator, "Right");
    const split_component = try split(allocator, left, right, .{ .ratio = 0.4 });
    const state = @as(*SplitState, @ptrCast(@alignCast(split_component.base.user_data.?)));
    const initial = state.ratio;
    _ = split_component.onEvent(.{ .key = .{ .arrow_key = .right } });
    try std.testing.expect(state.ratio > initial);
}

test "modal closes on escape and reopens on enter" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const body = try label(allocator, "Body");
    const modal_component = try modal(allocator, body, .{ .title = "Modal", .is_open = true });
    const state = @as(*ModalState, @ptrCast(@alignCast(modal_component.base.user_data.?)));

    const closed = modal_component.onEvent(.{ .key = .{ .codepoint = 27 } });
    try std.testing.expect(closed);
    try std.testing.expect(!state.is_open);

    const reopened = modal_component.onEvent(.{ .key = .{ .codepoint = '\n' } });
    try std.testing.expect(reopened);
    try std.testing.expect(state.is_open);
}

test "collapsible toggles expansion with space" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const child = try label(allocator, "Details");
    const coll = try collapsible(allocator, child, .{ .label = "Info" });
    const state = @as(*CollapsibleState, @ptrCast(@alignCast(coll.base.user_data.?)));
    try std.testing.expect(!state.expanded);
    _ = coll.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try std.testing.expect(state.expanded);
}

test "hover wrapper tracks mouse enter and custom leave" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const child = try label(allocator, "Hover me");
    const hover = try hoverWrapper(allocator, child, .{ .hover_text = "hovering" });
    const state = @as(*HoverState, @ptrCast(@alignCast(hover.base.user_data.?)));

    const entered = hover.onEvent(.{ .mouse = .{ .position = .{}, .buttons = .{} } });
    try std.testing.expect(entered);
    try std.testing.expect(state.hovered);

    const left = hover.onEvent(.{ .custom = .{ .tag = "hover:leave" } });
    try std.testing.expect(left);
    try std.testing.expect(!state.hovered);
}

test "window forwards events to child" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var triggered = false;
    const child_ptr = try allocator.create(base.ComponentBase);
    child_ptr.* = base.ComponentBase{
        .text_cache = "",
        .user_data = @as(*anyopaque, @ptrCast(&triggered)),
        .renderFn = null,
        .eventFn = struct {
            fn handle(self: *base.ComponentBase, _: events.Event) bool {
                const flag_ptr = @as(*bool, @ptrCast(self.user_data.?));
                flag_ptr.* = true;
                return true;
            }
        }.handle,
        .animationFn = null,
        .children = &[_]base.Component{},
        .focus_index = 0,
    };
    const child_component = base.Component{ .base = child_ptr };
    const window_component = try window(allocator, child_component, .{ .title = "Window" });

    const consumed = window_component.onEvent(.{ .key = .{ .codepoint = 'x' } });
    try std.testing.expect(consumed);
    try std.testing.expect(triggered);
}

test "button animated registers animation callback" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const comp = try buttonAnimated(allocator, "Glow", .{});
    try std.testing.expect(comp.base.animationFn != null);
}

test "text area tracks multiline cursor" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const area = try textArea(allocator, .{ .placeholder = "Notes" });
    const st = @as(*InputState, @ptrCast(@alignCast(area.base.user_data.?)));
    try std.testing.expect(st.multiline);
    try std.testing.expect(st.visible_lines > 1);
}

test "menu multi select toggles with space" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const items = [_][]const u8{ "One", "Two" };
    const menu_component = try menu(allocator, .{ .items = &items, .multi_select = true });
    const state = @as(*MenuState, @ptrCast(@alignCast(menu_component.base.user_data.?)));
    try std.testing.expect(state.selections.len == items.len);
    _ = menu_component.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try std.testing.expect(state.selections[0]);
}

test "tabs respond to arrow keys" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const tabs_component = try tabVertical(allocator, .{ .labels = &[_][]const u8{ "A", "B" } });
    const state = @as(*TabsState, @ptrCast(@alignCast(tabs_component.base.user_data.?)));
    _ = tabs_component.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expectEqual(@as(usize, 1), state.selected_index);
}

test "scrollbar arrow adjusts position" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const bar = try scrollbar(allocator, .{ .content_length = 100, .viewport_length = 10 });
    const state = @as(*ScrollbarState, @ptrCast(@alignCast(bar.base.user_data.?)));
    _ = bar.onEvent(.{ .key = .{ .arrow_key = .down } });
    try std.testing.expect(state.position > 0);
}

test "split custom clamp events set ratio" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const a = try label(allocator, "A");
    const b = try label(allocator, "B");
    const comp = try split(allocator, a, b, .{ .ratio = 0.4, .min_ratio = 0.3, .max_ratio = 0.8 });
    const state = @as(*SplitState, @ptrCast(@alignCast(comp.base.user_data.?)));
    _ = comp.onEvent(.{ .custom = .{ .tag = "split:clamp:max" } });
    try std.testing.expectEqual(@as(f32, 0.8), state.ratio);
}

fn dropdownNoopRenderer(payload: options.DropdownRenderPayload) anyerror!void {
    _ = payload;
}

test "dropdown custom renderer is stored" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const dd = try dropdownCustom(allocator, .{ .items = &[_][]const u8{"X"} }, dropdownNoopRenderer);
    const state = @as(*DropdownState, @ptrCast(@alignCast(dd.base.user_data.?)));
    try std.testing.expect(state.custom_renderer != null);
}

test "maybe decorator toggles visibility" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const child = try label(allocator, "Hidden");
    const maybe_component = try maybe(allocator, child, false);
    const state = @as(*MaybeState, @ptrCast(@alignCast(maybe_component.base.user_data.?)));
    try std.testing.expect(!state.visible);
    _ = maybe_component.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try std.testing.expect(state.visible);
}

test "homescreen stores sections" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const windows = [_]base.Component{try label(allocator, "Pane")};
    const comp = try homescreen(allocator, "Home", &[_][]const u8{"Inbox"}, &windows);
    const state = @as(*HomescreenState, @ptrCast(@alignCast(comp.base.user_data.?)));
    try std.testing.expectEqual(@as(usize, 1), state.sections.len);
}

test "visual gallery duplicates caption" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const gallery = try visualGallery(allocator, "Gallery");
    const state = @as(*GalleryState, @ptrCast(@alignCast(gallery.base.user_data.?)));
    try std.testing.expectEqualStrings("Gallery", state.caption);
}
const FrameWrapperState = struct {
    child: base.Component,
    options: options.FrameOptions,
};

const RendererContext = struct {
    stdout: std.fs.File,
    child: base.Component,
};

const RendererFn = *const fn (RendererContext) anyerror!void;

const RendererDecoratorState = struct {
    child: base.Component,
    renderFn: RendererFn,
    show_child: bool,
};

const MaybeState = struct {
    child: base.Component,
    visible: bool,
};

const HomescreenState = struct {
    sections: []const []const u8,
    windows: []base.Component,
    header: []const u8,
};

const GalleryState = struct {
    caption: []const u8,
    canvas_demo: []const u8,
    gradient_demo: []const u8,
    hover_demo: []const u8,
    focus_demo: []const u8,
};
