const std = @import("std");

pub const Event = union(enum) {
    key: KeyEvent,
    mouse: MouseEvent,
    cursor: CursorEvent,
    custom: CustomEvent,
};

pub const FunctionKey = enum {
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
};

pub const ArrowKey = enum {
    up,
    down,
    left,
    right,
};

pub const SpecialKey = enum {
    enter,
    escape,
    backspace,
    tab,
    delete,
    insert,
    home,
    end,
    page_up,
    page_down,
};

pub const KeyEvent = struct {
    codepoint: ?u21 = null,
    function_key: ?FunctionKey = null,
    arrow_key: ?ArrowKey = null,
    special: ?SpecialKey = null,
    ctrl: bool = false,
    alt: bool = false,
    shift: bool = false,
};

pub const MouseEventKind = enum {
    move,
    press,
    release,
    scroll,
};

pub const MouseEvent = struct {
    position: MousePosition,
    buttons: MouseButtons = .{},
    kind: MouseEventKind = .move,
    scroll: MouseScroll = .{},
    ctrl: bool = false,
    alt: bool = false,
    shift: bool = false,
};

pub const CustomEvent = struct {
    tag: []const u8 = "",
};

pub const MousePosition = struct {
    x: i32 = 0,
    y: i32 = 0,
};

pub const MouseScroll = struct {
    dx: i32 = 0,
    dy: i32 = 0,
};

pub const MouseButtons = struct {
    left: bool = false,
    right: bool = false,
    middle: bool = false,
};

pub const Mouse = struct {
    position: MousePosition = .{},
    buttons: MouseButtons = .{},
};

pub const CursorEvent = struct {
    visible: bool = true,
    position: ?MousePosition = null,
};

test "special keys remain distinct from codepoints" {
    const ev = Event{ .key = .{ .special = .enter, .codepoint = null } };
    try std.testing.expect(ev.key.codepoint == null);
    try std.testing.expect(ev.key.special.? == .enter);
}

test "mouse scroll defaults keep position and delta" {
    const ev = Event{ .mouse = .{ .position = .{ .x = 4, .y = 2 }, .kind = .scroll, .scroll = .{ .dy = -1 } } };
    try std.testing.expectEqual(@as(i32, 4), ev.mouse.position.x);
    try std.testing.expectEqual(@as(i32, -1), ev.mouse.scroll.dy);
    try std.testing.expect(ev.mouse.kind == .scroll);
}

test "cursor event toggles visibility" {
    const hide = Event{ .cursor = .{ .visible = false } };
    try std.testing.expect(!hide.cursor.visible);
}
