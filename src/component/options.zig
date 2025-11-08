pub const ButtonOptions = struct {
    label: []const u8 = "",
    is_default: bool = false,
};

pub const MenuOptions = struct {
    highlight_color: u24 = 0xFFFFFF,
    animation_enabled: bool = true,
};

pub const InputOptions = struct {
    placeholder: []const u8 = "",
    is_password: bool = false,
    multiline: bool = false,
};

pub const SliderOptions = struct {
    min: f32 = 0,
    max: f32 = 1,
    step: f32 = 0.1,
    horizontal: bool = true,
};

pub const WindowOptions = struct {
    title: []const u8 = "",
    border: bool = true,
};

pub const UnderlineOption = struct {
    thickness: f32 = 1,
};

pub const AnimatedColorOption = struct {
    start_color: u24 = 0x000000,
    end_color: u24 = 0xFFFFFF,
    duration_ms: u32 = 150,
};

pub const CheckboxOptions = struct {
    label: []const u8 = "",
    checked: bool = false,
};

pub const ToggleOptions = struct {
    on_label: []const u8 = "ON",
    off_label: []const u8 = "OFF",
    on: bool = false,
};

pub const RadioOptions = struct {
    labels: []const []const u8 = &[_][]const u8{},
    selected_index: usize = 0,
};
