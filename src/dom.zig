const node = @import("dom/node.zig");
const elements_mod = @import("dom/elements.zig");
const screen_mod = @import("screen.zig");

pub const Node = node.Node;
pub const Requirement = node.Requirement;
pub const Selection = node.Selection;
pub const AccessibilityRole = node.AccessibilityRole;
pub const RenderContext = node.RenderContext;
pub const StyleAttributes = node.StyleAttributes;

pub const FocusPosition = node.FocusPosition;
pub const ScrollIndicator = node.ScrollIndicator;

pub const elements = elements_mod;

pub fn styleToCellStyle(style: StyleAttributes, default_fg: u24, default_bg: u24) screen_mod.CellStyle {
    return .{
        .fg = style.fg orelse default_fg,
        .bg = style.bg orelse default_bg,
        .style = .{
            .bold = style.bold,
            .italic = style.italic,
            .underline = style.underline,
            .underline_double = style.underline_double,
            .strikethrough = style.strikethrough,
            .dim = style.dim,
            .blink = style.blink,
            .inverse = style.inverse,
        },
    };
}
