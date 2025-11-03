pub const Event = union(enum) {
    key: KeyEvent,
    mouse: MouseEvent,
    custom: CustomEvent,
};

pub const KeyEvent = struct {
    codepoint: u21,
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
