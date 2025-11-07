pub const dom = @import("dom.zig");
pub const component = @import("component.zig");
pub const screen = @import("screen.zig");

pub const version = "0.0.0-dev";

test "aggregate module tests" {
    _ = @import("dom/node.zig");
    _ = @import("dom/elements.zig");
    _ = @import("component/widgets.zig");
    _ = @import("screen/screen.zig");
    _ = @import("screen/color.zig");
    _ = @import("screen/strings.zig");
}
