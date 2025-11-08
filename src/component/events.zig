pub const Event = union(enum) {
    key: KeyEvent,
    mouse: MouseEvent,
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

pub const KeyEvent = struct {
    codepoint: ?u21 = null,
    function_key: ?FunctionKey = null,
    arrow_key: ?ArrowKey = null,
    ctrl: bool = false,
    alt: bool = false,
    shift: bool = false,
};

pub const MouseEvent = struct {
    position: MousePosition,
    buttons: MouseButtons = .{},
};

pub const CustomEvent = struct {
    tag: []const u8 = "",
};

pub const MousePosition = struct {
    x: i32 = 0,
    y: i32 = 0,
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
