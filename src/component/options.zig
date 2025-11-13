pub const ButtonOptions = struct {
    label: []const u8 = "",
    is_default: bool = false,
};

pub const MenuOptions = struct {
    items: []const []const u8 = &[_][]const u8{},
    selected_index: usize = 0,
    loop_navigation: bool = true,
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

pub const SplitOrientation = enum { horizontal, vertical };

pub const SplitOptions = struct {
    orientation: SplitOrientation = .horizontal,
    ratio: f32 = 0.5,
    min_ratio: f32 = 0.1,
    max_ratio: f32 = 0.9,
    handle: []const u8 = "====",
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

pub const DropdownOptions = struct {
    items: []const []const u8 = &[_][]const u8{},
    selected_index: usize = 0,
    placeholder: []const u8 = "",
    is_open: bool = false,
};

pub const ModalOptions = struct {
    title: []const u8 = "Modal",
    is_open: bool = true,
    dismissible: bool = true,
    width: usize = 32,
};

pub const CollapsibleOptions = struct {
    label: []const u8 = "Section",
    expanded: bool = false,
    indicator_open: []const u8 = "[-]",
    indicator_closed: []const u8 = "[+]",
};

pub const HoverOptions = struct {
    hover_text: []const u8 = "(hovering)",
    idle_text: []const u8 = "",
};
