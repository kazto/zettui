pub const dom = @import("dom.zig");
pub const component = @import("component.zig");
pub const screen = @import("screen.zig");
pub const animation = @import("animation/animator.zig");
pub const task = @import("task.zig");
pub const loop = @import("loop.zig");
pub const captured_mouse = @import("captured_mouse.zig");
pub const screen_interactive = @import("screen_interactive.zig");

pub const version = "0.0.0-dev";

test "aggregate module tests" {
    _ = @import("dom/node.zig");
    _ = @import("dom/elements.zig");
    _ = @import("component/widgets.zig");
    _ = @import("screen/screen.zig");
    _ = @import("screen/color.zig");
    _ = @import("screen/strings.zig");
    _ = @import("animation/animator.zig");
    _ = @import("task.zig");
    _ = @import("loop.zig");
    _ = @import("captured_mouse.zig");
    _ = @import("screen_interactive.zig");
}
