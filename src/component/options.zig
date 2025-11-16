pub const ButtonVisual = enum { plain, primary, success, danger };

pub const ButtonFrameStyle = enum { none, inline_frame, panel };

pub const ButtonOptions = struct {
    label: []const u8 = "",
    is_default: bool = false,
    visual: ButtonVisual = .plain,
    frame: ButtonFrameStyle = .none,
    animated: bool = false,
    underline: ?UnderlineOption = null,
    animation: ?AnimatedColorOption = null,
};

pub const MenuOptions = struct {
    items: []const []const u8 = &[_][]const u8{},
    selected_index: usize = 0,
    loop_navigation: bool = true,
    highlight_color: u24 = 0xFFFFFF,
    animation_enabled: bool = true,
    multi_select: bool = false,
    selected_flags: ?[]const bool = null,
    underline_gallery: bool = false,
    custom_renderer: ?MenuRenderFn = null,
};

pub const InputOptions = struct {
    placeholder: []const u8 = "",
    is_password: bool = false,
    multiline: bool = false,
    prefix: []const u8 = "",
    suffix: []const u8 = "",
    bordered: bool = false,
    placeholder_style: []const u8 = "",
    visible_lines: usize = 1,
    max_length: usize = 0,
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

pub const TabsOrientation = enum { horizontal, vertical };

pub const TabsOptions = struct {
    labels: []const []const u8 = &[_][]const u8{},
    selected_index: usize = 0,
    orientation: TabsOrientation = .horizontal,
};

pub const ScrollbarOrientation = enum { horizontal, vertical };

pub const ScrollbarOptions = struct {
    content_length: usize = 0,
    viewport_length: usize = 0,
    position: usize = 0,
    orientation: ScrollbarOrientation = .vertical,
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
    custom_renderer: ?DropdownRenderFn = null,
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

pub const FrameCharset = enum { single, double };

pub const FrameOptions = struct {
    title: []const u8 = "",
    charset: FrameCharset = .single,
};

pub const MenuRenderPayload = struct {
    items: []const []const u8,
    selected_index: usize,
    selected_flags: ?[]const bool = null,
    underline_gallery: bool = false,
    highlight_color: u24,
    phase: f32,
};

pub const MenuRenderFn = *const fn (MenuRenderPayload) anyerror!void;

pub const DropdownRenderPayload = struct {
    items: []const []const u8,
    selected_index: ?usize,
    is_open: bool,
    placeholder: []const u8,
};

pub const DropdownRenderFn = *const fn (DropdownRenderPayload) anyerror!void;
