const std = @import("std");

pub const Box = struct {
    origin_x: i32 = 0,
    origin_y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
};

pub const FocusPosition = enum { start, center, end };

pub const ScrollIndicator = struct {
    top: bool = false,
    bottom: bool = false,
};

pub const Axis = enum { horizontal, vertical };
pub const Orientation = enum { vertical, horizontal };

pub const Constraint = union(enum) {
    none,
    exact: usize,
    at_least: usize,
    at_most: usize,
    range: struct { min: usize, max: usize },

    pub fn clamp(self: Constraint, value: usize) usize {
        return switch (self) {
            .none => value,
            .exact => |v| v,
            .at_least => |min| if (value < min) min else value,
            .at_most => |max| if (value > max) max else value,
            .range => |r| blk: {
                const hi = if (r.max < r.min) r.min else r.max;
                const lo = @min(r.min, hi);
                break :blk std.math.clamp(value, lo, hi);
            },
        };
    }
};

pub const Requirement = struct {
    min_width: usize = 0,
    min_height: usize = 0,
    flex_grow: f32 = 0,
    flex_shrink: f32 = 1,
    focus: ?FocusPosition = null,
};

pub const AccessibilityRole = enum {
    button,
    checkbox,
    text_input,
    slider,
    radio_group,
    link,
    text,
    heading,
    list,
    list_item,
    table,
    table_cell,
    container,
    none,
};

pub const Selection = struct {
    // Focus state
    has_focus: bool = false,

    // Cursor state
    cursor_index: usize = 0, // Character index in text content
    cursor_line: usize = 0, // Line number (for multi-line text)
    selection_start: ?usize = null, // Start of text selection (if any)
    selection_end: ?usize = null, // End of text selection (if any)

    // Accessibility information
    role: AccessibilityRole = .none,
    label: []const u8 = "", // Accessible label/name
    description: []const u8 = "", // Additional description
    value: []const u8 = "", // Current value (for inputs, sliders, etc.)
    state: []const u8 = "", // State description (e.g., "checked", "expanded")

    // Position information
    box: ?Box = null, // Bounding box of selected element

    pub fn init() Selection {
        return .{};
    }

    pub fn clear(self: *Selection) void {
        self.* = .{};
    }

    pub fn setFocus(self: *Selection) void {
        self.has_focus = true;
    }

    pub fn clearFocus(self: *Selection) void {
        self.has_focus = false;
    }

    pub fn setCursor(self: *Selection, index: usize, line: usize) void {
        self.cursor_index = index;
        self.cursor_line = line;
    }

    pub fn setSelection(self: *Selection, start: usize, end: usize) void {
        self.selection_start = start;
        self.selection_end = end;
    }

    pub fn clearSelection(self: *Selection) void {
        self.selection_start = null;
        self.selection_end = null;
    }

    pub fn setAccessibility(self: *Selection, role: AccessibilityRole, label: []const u8, description: []const u8, value: []const u8, state: []const u8) void {
        self.role = role;
        self.label = label;
        self.description = description;
        self.value = value;
        self.state = state;
    }

    pub fn getAccessibilityDescription(self: Selection, allocator: std.mem.Allocator) ![]const u8 {
        var buf = std.ArrayList(u8).initCapacity(allocator, 256) catch |e| return e;
        errdefer buf.deinit(allocator);

        if (self.label.len > 0) {
            try buf.appendSlice(allocator, self.label);
        }

        if (self.state.len > 0) {
            if (buf.items.len > 0) try buf.appendSlice(allocator, ", ");
            try buf.appendSlice(allocator, self.state);
        }

        if (self.value.len > 0) {
            if (buf.items.len > 0) try buf.appendSlice(allocator, ", ");
            try buf.appendSlice(allocator, self.value);
        }

        if (self.description.len > 0) {
            if (buf.items.len > 0) try buf.appendSlice(allocator, ". ");
            try buf.appendSlice(allocator, self.description);
        }

        return try buf.toOwnedSlice(allocator);
    }
};

pub const PaletteColor = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    bright_black,
    bright_red,
    bright_green,
    bright_yellow,
    bright_blue,
    bright_magenta,
    bright_cyan,
    bright_white,
};

pub const StyleAttributes = struct {
    bold: bool = false,
    italic: bool = false,
    underline: bool = false,
    underline_double: bool = false,
    strikethrough: bool = false,
    dim: bool = false,
    blink: bool = false,
    inverse: bool = false,
    fg: ?u24 = null,
    bg: ?u24 = null,
    fg_palette: ?PaletteColor = null,
    bg_palette: ?PaletteColor = null,
    hyperlink: ?[]const u8 = null,
};

pub fn paletteColorValue(color: PaletteColor) u24 {
    return switch (color) {
        .black => 0x000000,
        .red => 0xAA0000,
        .green => 0x008800,
        .yellow => 0xAA5500,
        .blue => 0x0000AA,
        .magenta => 0xAA00AA,
        .cyan => 0x00AAAA,
        .white => 0xAAAAAA,
        .bright_black => 0x555555,
        .bright_red => 0xFF5555,
        .bright_green => 0x55FF55,
        .bright_yellow => 0xFFFF55,
        .bright_blue => 0x5555FF,
        .bright_magenta => 0xFF55FF,
        .bright_cyan => 0x55FFFF,
        .bright_white => 0xFFFFFF,
    };
}

fn resolveColor(explicit: ?u24, palette: ?PaletteColor, default_color: u24) u24 {
    if (explicit) |c| return c;
    if (palette) |entry| return paletteColorValue(entry);
    return default_color;
}

pub const Sink = struct {
    user_data: *anyopaque,
    writeAll: *const fn (user_data: *anyopaque, data: []const u8) anyerror!void,
};

pub const Drawer = struct {
    user_data: *anyopaque,
    drawText: *const fn (
        user_data: *anyopaque,
        x: i32,
        y: i32,
        text: []const u8,
        style: StyleAttributes,
    ) anyerror!void,
};

pub const RenderContext = struct {
    allow_hyperlinks: bool = false,
    sink: ?Sink = null,
    drawer: ?Drawer = null,
    origin_x: i32 = 0,
    origin_y: i32 = 0,
    allocator: ?std.mem.Allocator = null,
    style: StyleAttributes = .{},
    current_hyperlink: ?[]const u8 = null,
};

pub fn ctxWrite(ctx: *RenderContext, data: []const u8) !void {
    if (ctx.allow_hyperlinks) {
        if (ctx.current_hyperlink) |target| {
            const esc_open = "\x1b]8;;";
            const esc_close = "\x1b]8;;\x1b\\";
            try ctxWriteRaw(ctx, esc_open);
            try ctxWriteRaw(ctx, target);
            try ctxWriteRaw(ctx, "\x1b\\");
            try ctxWriteRaw(ctx, data);
            try ctxWriteRaw(ctx, esc_close);
            return;
        }
    }
    try ctxWriteRaw(ctx, data);
}

pub fn ctxWriteRaw(ctx: *RenderContext, data: []const u8) !void {
    if (ctx.sink) |s| {
        try s.writeAll(s.user_data, data);
    } else {
        try std.fs.File.stdout().writeAll(data);
    }
}

pub fn stylesEqual(a: StyleAttributes, b: StyleAttributes) bool {
    const hyperlinks_equal = if (a.hyperlink) |h1| blk: {
        if (b.hyperlink) |h2| break :blk std.mem.eql(u8, h1, h2);
        break :blk false;
    } else b.hyperlink == null;
    return a.bold == b.bold and
        a.italic == b.italic and
        a.underline == b.underline and
        a.underline_double == b.underline_double and
        a.strikethrough == b.strikethrough and
        a.dim == b.dim and
        a.blink == b.blink and
        a.inverse == b.inverse and
        a.fg == b.fg and
        a.bg == b.bg and
        a.fg_palette == b.fg_palette and
        a.bg_palette == b.bg_palette and
        hyperlinks_equal;
}

pub fn mergeStyles(base: StyleAttributes, overlay: StyleAttributes) StyleAttributes {
    return .{
        .bold = base.bold or overlay.bold,
        .italic = base.italic or overlay.italic,
        .underline = base.underline or overlay.underline,
        .underline_double = base.underline_double or overlay.underline_double,
        .strikethrough = base.strikethrough or overlay.strikethrough,
        .dim = base.dim or overlay.dim,
        .blink = base.blink or overlay.blink,
        .inverse = base.inverse or overlay.inverse,
        .fg = overlay.fg orelse base.fg,
        .bg = overlay.bg orelse base.bg,
        .fg_palette = overlay.fg_palette orelse base.fg_palette,
        .bg_palette = overlay.bg_palette orelse base.bg_palette,
        .hyperlink = overlay.hyperlink orelse base.hyperlink,
    };
}

pub fn applyAnsiStyle(ctx: *RenderContext, style: StyleAttributes) !void {
    if (ctx.drawer != null) return;
    try ctxWriteRaw(ctx, "\x1b[0m");
    if (style.bold) try ctxWriteRaw(ctx, "\x1b[1m");
    if (style.dim) try ctxWriteRaw(ctx, "\x1b[2m");
    if (style.italic) try ctxWriteRaw(ctx, "\x1b[3m");
    if (style.underline) try ctxWriteRaw(ctx, "\x1b[4m");
    if (style.blink) try ctxWriteRaw(ctx, "\x1b[5m");
    if (style.inverse) try ctxWriteRaw(ctx, "\x1b[7m");
    if (style.strikethrough) try ctxWriteRaw(ctx, "\x1b[9m");
    if (style.underline_double) try ctxWriteRaw(ctx, "\x1b[21m");
    const fg_value = resolveColor(style.fg, style.fg_palette, 0xFFFFFF);
    const bg_value = resolveColor(style.bg, style.bg_palette, 0x000000);
    if (style.fg != null or style.fg_palette != null) try writeRgb(ctx, fg_value, true);
    if (style.bg != null or style.bg_palette != null) try writeRgb(ctx, bg_value, false);
}

fn writeRgb(ctx: *RenderContext, color: u24, is_fg: bool) !void {
    if (ctx.drawer != null) return;
    var buf: [32]u8 = undefined;
    const r = @as(u8, @intCast((color >> 16) & 0xFF));
    const g = @as(u8, @intCast((color >> 8) & 0xFF));
    const b = @as(u8, @intCast(color & 0xFF));
    const prefix: u8 = if (is_fg) 38 else 48;
    const seq = try std.fmt.bufPrint(&buf, "\x1b[{d};2;{d};{d};{d}m", .{ prefix, r, g, b });
    try ctxWriteRaw(ctx, seq);
}

pub fn ctxDraw(ctx: *RenderContext, x: i32, y: i32, text: []const u8) !void {
    if (ctx.drawer) |d| {
        try d.drawText(d.user_data, x, y, text, ctx.style);
    } else {
        try ctxWrite(ctx, text);
    }
}

pub fn frameWrite(ctx: *RenderContext, x: i32, y: i32, text: []const u8) !void {
    if (ctx.drawer != null) {
        try ctxDraw(ctx, x, y, text);
    } else {
        try ctxWrite(ctx, text);
    }
}

fn absDiff(a: i32, b: i32) i32 {
    return if (a >= b) a - b else b - a;
}

pub fn setPixelSigned(rows: [][]u8, x: i32, y: i32, ch: u8) void {
    if (x < 0 or y < 0) return;
    const ux: usize = @intCast(x);
    const uy: usize = @intCast(y);
    if (uy >= rows.len) return;
    if (ux >= rows[uy].len) return;
    rows[uy][ux] = ch;
}

pub fn drawLineSigned(rows: [][]u8, start_x: i32, start_y: i32, end_x: i32, end_y: i32, ch: u8) void {
    var x0 = start_x;
    var y0 = start_y;
    const x1 = end_x;
    const y1 = end_y;

    const dx = absDiff(x1, x0);
    const sx: i32 = if (x0 < x1) 1 else -1;
    const dy = -absDiff(y1, y0);
    const sy: i32 = if (y0 < y1) 1 else -1;
    var err = dx + dy;

    while (true) {
        setPixelSigned(rows, x0, y0, ch);
        if (x0 == x1 and y0 == y1) break;
        const e2 = err * 2;
        if (e2 >= dy) {
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx) {
            err += dx;
            y0 += sy;
        }
    }
}
