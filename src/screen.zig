const image = @import("screen/image.zig");
const surface = @import("screen/screen.zig");
const color = @import("screen/color.zig");
const terminal = @import("screen/terminal.zig");
const strings = @import("screen/strings.zig");
const interactive = @import("screen/interactive.zig");

pub const Image = image.Image;
pub const Screen = surface.Screen;
pub const Pixel = surface.Pixel;
pub const Box = surface.Box;
pub const TextStyle = surface.TextStyle;
pub const CellStyle = surface.CellStyle;

pub const Color = color.Color;
pub const ColorInfo = color.ColorInfo;
pub const Gradient = color.Gradient;
pub const GradientStop = color.GradientStop;

pub const TerminalInfo = terminal.TerminalInfo;
pub const Terminal = terminal.Terminal;

pub const utf8 = strings;

pub const ScreenInteractive = interactive.ScreenInteractive;
pub const LoopEvent = interactive.LoopEvent;
pub const TickEvent = interactive.TickEvent;
pub const ResizeEvent = interactive.ResizeEvent;
pub const CustomEvent = interactive.CustomEvent;
pub const EventHandler = interactive.EventHandler;
pub const FetchFn = interactive.FetchFn;
pub const AnimationCallback = interactive.AnimationCallback;
pub const MouseReleaseFn = interactive.MouseReleaseFn;
pub const RestoreFn = interactive.RestoreFn;
pub const CapturedMouse = interactive.CapturedMouse;
pub const NestedScreenGuard = interactive.NestedScreenGuard;
pub const RestoredIoGuard = interactive.RestoredIoGuard;
pub const AnimationHandle = interactive.AnimationHandle;
pub const CustomLoop = interactive.CustomLoop;

pub const customLoop = interactive.customLoop;
