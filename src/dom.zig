const node = @import("dom/node.zig");
const elements_mod = @import("dom/elements.zig");
const screen_mod = @import("screen.zig");

pub const Node = node.Node;
pub const Requirement = node.Requirement;
pub const Selection = node.Selection;
pub const AccessibilityRole = node.AccessibilityRole;
pub const RenderContext = node.RenderContext;
pub const StyleAttributes = node.StyleAttributes;
pub const PaletteColor = node.PaletteColor;

pub const FocusPosition = node.FocusPosition;
pub const ScrollIndicator = node.ScrollIndicator;

pub const elements = elements_mod;

pub fn styleToCellStyle(style: StyleAttributes, default_fg: u24, default_bg: u24) screen_mod.CellStyle {
    const fg_value = if (style.fg) |color| color else if (style.fg_palette) |entry| node.paletteColorValue(entry) else default_fg;
    const bg_value = if (style.bg) |color| color else if (style.bg_palette) |entry| node.paletteColorValue(entry) else default_bg;
    return .{
        .fg = fg_value,
        .bg = bg_value,
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
