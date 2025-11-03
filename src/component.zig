const base = @import("component/base.zig");
const widgets_mod = @import("component/widgets.zig");
const options = @import("component/options.zig");
const events = @import("component/events.zig");

pub const Component = base.Component;
pub const ComponentBase = base.ComponentBase;
pub const ComponentDecorator = base.ComponentDecorator;

pub const ButtonOptions = options.ButtonOptions;
pub const MenuOptions = options.MenuOptions;
pub const InputOptions = options.InputOptions;
pub const SliderOptions = options.SliderOptions;
pub const WindowOptions = options.WindowOptions;

pub const Event = events.Event;
pub const Mouse = events.Mouse;

pub const widgets = widgets_mod;
