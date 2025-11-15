const std = @import("std");

pub const FocusPosition = enum { start, center, end };

pub const ScrollIndicator = struct {
    top: bool = false,
    bottom: bool = false,
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

const FrameCharset = struct {
    top_left: []const u8,
    top_right: []const u8,
    bottom_left: []const u8,
    bottom_right: []const u8,
    horizontal: []const u8,
    vertical: []const u8,
};

fn frameCharset(style: FrameBorderStyle) FrameCharset {
    return switch (style) {
        .single => .{
            .top_left = "\xE2\x94\x8C",
            .top_right = "\xE2\x94\x90",
            .bottom_left = "\xE2\x94\x94",
            .bottom_right = "\xE2\x94\x98",
            .horizontal = "\xE2\x94\x80",
            .vertical = "\xE2\x94\x82",
        },
        .double => .{
            .top_left = "\xE2\x95\x94",
            .top_right = "\xE2\x95\x97",
            .bottom_left = "\xE2\x95\x9A",
            .bottom_right = "\xE2\x95\x9D",
            .horizontal = "\xE2\x95\x90",
            .vertical = "\xE2\x95\x91",
        },
    };
}

fn blendColor(start: u24, end: u24, t: f32) u24 {
    const clamped = std.math.clamp(t, 0.0, 1.0);
    const sr = (start >> 16) & 0xFF;
    const sg = (start >> 8) & 0xFF;
    const sb = start & 0xFF;
    const er = (end >> 16) & 0xFF;
    const eg = (end >> 8) & 0xFF;
    const eb = end & 0xFF;
    const r = @as(u8, @intFromFloat(@as(f32, @floatFromInt(sr)) * (1.0 - clamped) + @as(f32, @floatFromInt(er)) * clamped));
    const g = @as(u8, @intFromFloat(@as(f32, @floatFromInt(sg)) * (1.0 - clamped) + @as(f32, @floatFromInt(eg)) * clamped));
    const b = @as(u8, @intFromFloat(@as(f32, @floatFromInt(sb)) * (1.0 - clamped) + @as(f32, @floatFromInt(eb)) * clamped));
    return (@as(u24, r) << 16) | (@as(u24, g) << 8) | b;
}

pub const RenderContext = struct {
    allow_hyperlinks: bool = false,
    sink: ?Sink = null,
    drawer: ?Drawer = null,
    origin_x: i32 = 0,
    origin_y: i32 = 0,
    allocator: ?std.mem.Allocator = null,
    style: StyleAttributes = .{},
};

pub const Sink = struct {
    user_data: *anyopaque,
    writeAll: *const fn (user_data: *anyopaque, data: []const u8) anyerror!void,
};

fn ctxWrite(ctx: *RenderContext, data: []const u8) !void {
    if (ctx.sink) |s| {
        try s.writeAll(s.user_data, data);
    } else {
        try std.fs.File.stdout().writeAll(data);
    }
}

fn stylesEqual(a: StyleAttributes, b: StyleAttributes) bool {
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
        a.bg_palette == b.bg_palette;
}

fn mergeStyles(base: StyleAttributes, overlay: StyleAttributes) StyleAttributes {
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
    };
}

fn applyAnsiStyle(ctx: *RenderContext, style: StyleAttributes) !void {
    if (ctx.drawer != null) return;
    try ctxWrite(ctx, "\x1b[0m");
    if (style.bold) try ctxWrite(ctx, "\x1b[1m");
    if (style.dim) try ctxWrite(ctx, "\x1b[2m");
    if (style.italic) try ctxWrite(ctx, "\x1b[3m");
    if (style.underline) try ctxWrite(ctx, "\x1b[4m");
    if (style.blink) try ctxWrite(ctx, "\x1b[5m");
    if (style.inverse) try ctxWrite(ctx, "\x1b[7m");
    if (style.strikethrough) try ctxWrite(ctx, "\x1b[9m");
    if (style.underline_double) try ctxWrite(ctx, "\x1b[21m");
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
    try ctxWrite(ctx, seq);
}

pub const Box = struct {
    origin_x: i32 = 0,
    origin_y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
};

pub const Node = union(enum) {
    empty: void,
    text: Text,
    container: Container,
    custom: CustomRenderer,
    separator: Separator,
    window: WindowFrame,
    gauge: Gauge,
    spinner: Spinner,
    paragraph: Paragraph,
    graph: Graph,
    canvas: Canvas,
    gradient_text: GradientText,
    frame: Frame,
    size: Size,
    filler: Filler,
    focus: Focus,
    flexbox: Flexbox,
    dbox: Dbox,
    cursor: Cursor,
    style: StyleDecorator,

    pub fn computeRequirement(self: Node) Requirement {
        return switch (self) {
            .text => |text_node| Requirement{
                .min_width = text_node.content.len,
                .min_height = 1,
            },
            .separator => Requirement{ .min_width = 1, .min_height = 1 },
            .window => |w| Requirement{ .min_width = 2 + w.title.len, .min_height = 1 },
            .gauge => |g| Requirement{ .min_width = @max(@as(usize, 3), g.width), .min_height = 1 },
            .spinner => |s| Requirement{ .min_width = s.currentFrame().len, .min_height = 1 },
            .paragraph => |p| blk: {
                const w: usize = if (p.width == 0) 1 else p.width;
                const lines: usize = (p.content.len + w - 1) / w;
                break :blk Requirement{ .min_width = w, .min_height = if (lines == 0) 1 else lines };
            },
            .graph => |g| blkGraph: {
                const dims = g.dimensions();
                break :blkGraph Requirement{
                    .min_width = dims.width,
                    .min_height = dims.height,
                };
            },
            .canvas => |c| blkCanvas: {
                const dims = c.dimensions();
                break :blkCanvas Requirement{
                    .min_width = dims.width,
                    .min_height = dims.height,
                };
            },
            .gradient_text => |g| Requirement{
                .min_width = g.text.len,
                .min_height = if (g.text.len == 0) 0 else 1,
            },
            .size => |s| blkSize: {
                const child_req = s.child.*.computeRequirement();
                break :blkSize Requirement{
                    .min_width = @max(child_req.min_width, s.width),
                    .min_height = @max(child_req.min_height, s.height),
                };
            },
            .filler => |f| Requirement{
                .min_width = 0,
                .min_height = 0,
                .flex_grow = f.grow,
                .flex_shrink = f.shrink,
            },
            .focus => |fx| blkFocus: {
                var req = fx.child.*.computeRequirement();
                req.focus = fx.position;
                break :blkFocus req;
            },
            .flexbox => |fb| blkFlex: {
                var req = Requirement{};
                const count = fb.children.len;
                const gap_total: usize = if (count > 0) fb.gap * (count - 1) else 0;
                switch (fb.direction) {
                    .row => {
                        req.min_height = 0;
                        req.min_width = gap_total;
                        for (fb.children) |child| {
                            const cr = child.computeRequirement();
                            req.min_width += cr.min_width;
                            req.min_height = @max(req.min_height, cr.min_height);
                        }
                    },
                    .column => {
                        req.min_width = 0;
                        req.min_height = gap_total;
                        for (fb.children) |child| {
                            const cr = child.computeRequirement();
                            req.min_width = @max(req.min_width, cr.min_width);
                            req.min_height += cr.min_height;
                        }
                    },
                }
                break :blkFlex req;
            },
            .dbox => |db| blkD: {
                var req = Requirement{};
                for (db.children) |child| {
                    const cr = child.computeRequirement();
                    req.min_width = @max(req.min_width, cr.min_width);
                    req.min_height = @max(req.min_height, cr.min_height);
                }
                break :blkD req;
            },
            .cursor => |c| blkCur: {
                // Cursor decorator does not change size; inherit child's requirement
                if (c.child) |ch| break :blkCur ch.*.computeRequirement();
                break :blkCur Requirement{};
            },
            .container => |container_node| container_node.computeRequirement(),
            .frame => |f| blockFrame: {
                const child_req = f.child.computeRequirement();
                break :blockFrame Requirement{
                    .min_width = child_req.min_width + 2,
                    .min_height = child_req.min_height + 2,
                };
            },
            .style => |s| blkStyle: {
                break :blkStyle s.child.*.computeRequirement();
            },
            else => Requirement{},
        };
    }

    pub fn setBox(self: *Node, box: Box) void {
        switch (self.*) {
            .container => |*container_node| container_node.box = box,
            .flexbox => |*fb| fb.box = box,
            .dbox => |*db| db.box = box,
            else => {},
        }
    }

    pub fn check(self: Node) void {
        switch (self) {
            .container => |container_node| container_node.check(),
            else => {},
        }
    }

    pub fn render(self: Node, ctx: *RenderContext) anyerror!void {
        switch (self) {
            .text => |text_node| {
                if (ctx.drawer != null) {
                    try ctxDraw(ctx, ctx.origin_x, ctx.origin_y, text_node.content);
                } else {
                    try ctxWrite(ctx, text_node.content);
                }
            },
            .separator => {
                try ctxWrite(ctx, "---\n");
            },
            .window => |w| {
                if (ctx.drawer != null) {
                    var buf = std.array_list.Managed(u8).init(std.heap.page_allocator);
                    defer buf.deinit();
                    try buf.appendSlice("[");
                    try buf.appendSlice(w.title);
                    try buf.appendSlice("]");
                    try ctxDraw(ctx, ctx.origin_x, ctx.origin_y, buf.items);
                } else {
                    try ctxWrite(ctx, "[");
                    try ctxWrite(ctx, w.title);
                    try ctxWrite(ctx, "]");
                }
            },
            .gauge => |g| {
                const total = if (g.width < 3) 3 else g.width;
                const inner: usize = total - 2;
                const clamped = std.math.clamp(g.fraction, 0.0, 1.0);
                const filled: usize = @intFromFloat(@floor(@as(f32, @floatFromInt(inner)) * clamped + 0.0001));
                const empty: usize = inner - filled;
                if (ctx.drawer != null) {
                    var buf = std.array_list.Managed(u8).init(std.heap.page_allocator);
                    defer buf.deinit();
                    try buf.appendSlice("[");
                    var i: usize = 0;
                    while (i < filled) : (i += 1) try buf.append('#');
                    i = 0;
                    while (i < empty) : (i += 1) try buf.append('.');
                    try buf.appendSlice("]");
                    try ctxDraw(ctx, ctx.origin_x, ctx.origin_y, buf.items);
                } else {
                    try ctxWrite(ctx, "[");
                    var i: usize = 0;
                    while (i < filled) : (i += 1) try ctxWrite(ctx, "#");
                    i = 0;
                    while (i < empty) : (i += 1) try ctxWrite(ctx, ".");
                    try ctxWrite(ctx, "]");
                }
            },
            .spinner => |s| {
                try ctxWrite(ctx, s.currentFrame());
            },
            .paragraph => |p| {
                const w: usize = if (p.width == 0) 1 else p.width;
                if (ctx.drawer != null) {
                    var idx: usize = 0;
                    var row: i32 = ctx.origin_y;
                    while (idx < p.content.len) {
                        const rem = p.content.len - idx;
                        const take = if (rem < w) rem else w;
                        try ctxDraw(ctx, ctx.origin_x, row, p.content[idx .. idx + take]);
                        idx += take;
                        row += 1;
                    }
                } else {
                    var i: usize = 0;
                    while (i < p.content.len) : (i += 1) {
                        if (w > 0 and i > 0 and (i % w) == 0) {
                            try ctxWrite(ctx, "\n");
                        }
                        try ctxWrite(ctx, p.content[i .. i + 1]);
                    }
                }
            },
            .graph => |g| try g.render(ctx),
            .canvas => |c| try c.render(ctx),
            .gradient_text => |g| try g.render(ctx),
            .custom => |renderer| try @call(.auto, renderer.callback, .{ renderer.user_data, ctx }),
            .frame => |f| {
                const req = f.child.*.computeRequirement();
                const inner_w: usize = req.min_width;
                const border = frameCharset(f.border.charset);
                const top_left = border.top_left;
                const top_right = border.top_right;
                const horizontal = border.horizontal;
                const vertical = border.vertical;
                const bottom_left = border.bottom_left;
                const bottom_right = border.bottom_right;
                const saved = ctx.style;
                ctx.style = mergeStyles(ctx.style, .{ .fg = f.border.fg, .fg_palette = f.border.fg_palette });
                try frameWrite(ctx, ctx.origin_x, ctx.origin_y, top_left);
                var h: usize = 0;
                while (h < inner_w) : (h += 1) try frameWrite(ctx, ctx.origin_x + @as(i32, @intCast(h + 1)), ctx.origin_y, horizontal);
                try frameWrite(ctx, ctx.origin_x + @as(i32, @intCast(inner_w + 1)), ctx.origin_y, top_right);
                if (ctx.drawer == null) try ctxWrite(ctx, "\n");

                // middle rows: wrap known multi-line children with borders per line
                switch (f.child.*) {
                    .paragraph => |p| {
                        const w: usize = if (p.width == 0) 1 else p.width;
                        var idx: usize = 0;
                        while (idx < p.content.len) {
                            try frameWrite(ctx, ctx.origin_x, ctx.origin_y + 1 + @as(i32, @intCast(idx / w)), vertical);
                            const rem = p.content.len - idx;
                            const take = if (rem < w) rem else w;
                            if (ctx.drawer != null) {
                                var col: usize = 0;
                                while (col < take) : (col += 1) try frameWrite(ctx, ctx.origin_x + 1 + @as(i32, @intCast(col)), ctx.origin_y + 1 + @as(i32, @intCast(idx / w)), p.content[idx + col .. idx + col + 1]);
                            } else {
                                try ctxWrite(ctx, p.content[idx .. idx + take]);
                            }
                            var pad: usize = inner_w - take;
                            while (pad > 0) : (pad -= 1) try ctxWrite(ctx, " ");
                            try frameWrite(ctx, ctx.origin_x + @as(i32, @intCast(inner_w + 1)), ctx.origin_y + 1 + @as(i32, @intCast(idx / w)), vertical);
                            if (ctx.drawer == null) try ctxWrite(ctx, "\n");
                            idx += take;
                        }
                        if (p.content.len == 0) {
                            // empty content still renders one empty line inside the frame
                            try frameWrite(ctx, ctx.origin_x, ctx.origin_y + 1, vertical);
                            var j: usize = 0;
                            while (j < inner_w) : (j += 1) try ctxWrite(ctx, " ");
                            try frameWrite(ctx, ctx.origin_x + @as(i32, @intCast(inner_w + 1)), ctx.origin_y + 1, vertical);
                            if (ctx.drawer == null) try ctxWrite(ctx, "\n");
                        }
                    },
                    else => {
                        // default: single row with child rendering
                        try frameWrite(ctx, ctx.origin_x, ctx.origin_y + 1, vertical);
                        var child_ctx = ctx.*;
                        child_ctx.origin_x += 1;
                        child_ctx.origin_y += 1;
                        try f.child.*.render(&child_ctx);
                        // pad to inner width is not attempted here; assume child fits
                        try frameWrite(ctx, ctx.origin_x + @as(i32, @intCast(inner_w + 1)), ctx.origin_y + 1, vertical);
                        if (ctx.drawer == null) try ctxWrite(ctx, "\n");
                    },
                }

                // bottom border: └───┘
                try frameWrite(ctx, ctx.origin_x, ctx.origin_y + 1 + @as(i32, @intCast(req.min_height)), bottom_left);
                var bottom_col: usize = 0;
                while (bottom_col < inner_w) : (bottom_col += 1) try frameWrite(ctx, ctx.origin_x + 1 + @as(i32, @intCast(bottom_col)), ctx.origin_y + 1 + @as(i32, @intCast(req.min_height)), horizontal);
                try frameWrite(ctx, ctx.origin_x + @as(i32, @intCast(inner_w + 1)), ctx.origin_y + 1 + @as(i32, @intCast(req.min_height)), bottom_right);
                if (ctx.drawer == null) try ctxWrite(ctx, "\n");
                ctx.style = saved;
                if (ctx.drawer == null) {
                    try applyAnsiStyle(ctx, saved);
                }
            },
            .style => |s| {
                const prev = ctx.style;
                const next = mergeStyles(prev, s.attrs);
                if (!stylesEqual(prev, next) and ctx.drawer == null) {
                    try applyAnsiStyle(ctx, next);
                }
                ctx.style = next;
                errdefer {
                    ctx.style = prev;
                    if (!stylesEqual(prev, next) and ctx.drawer == null) {
                        applyAnsiStyle(ctx, prev) catch {};
                    }
                }
                try s.child.*.render(ctx);
                ctx.style = prev;
                if (!stylesEqual(prev, next) and ctx.drawer == null) {
                    try applyAnsiStyle(ctx, prev);
                }
            },
            .size => |s| {
                // Size decorator does not change rendering; it only influences requirements.
                try s.child.*.render(ctx);
            },
            .filler => |f| {
                _ = f;
                // filler renders nothing by itself
            },
            .focus => |fx| {
                _ = fx;
                // focus decorator does not affect rendering, only requirement metadata
            },
            .flexbox => |fb| {
                var i: usize = 0;
                const kids = if (fb.owned_children) |oc| oc else fb.children;
                if (ctx.drawer != null and ctx.allocator != null) {
                    const alloc = ctx.allocator.?;
                    const boxes = try fb.layout(alloc);
                    for (kids, 0..) |child, idx| {
                        if (i > 0) {
                            switch (fb.direction) {
                                .row => {
                                    var g: usize = 0;
                                    while (g < fb.gap) : (g += 1) try ctxWrite(ctx, " ");
                                },
                                .column => {
                                    var g2: usize = 0;
                                    while (g2 < fb.gap) : (g2 += 1) try ctxWrite(ctx, "\n");
                                },
                            }
                        }
                        var child_ctx = ctx.*;
                        child_ctx.origin_x = boxes[idx].origin_x;
                        child_ctx.origin_y = boxes[idx].origin_y;
                        try child.render(&child_ctx);
                        i += 1;
                    }
                } else {
                    for (kids) |child| {
                        if (i > 0) {
                            switch (fb.direction) {
                                .row => {
                                    var g: usize = 0;
                                    while (g < fb.gap) : (g += 1) try ctxWrite(ctx, " ");
                                },
                                .column => {
                                    var g2: usize = 0;
                                    while (g2 < fb.gap) : (g2 += 1) try ctxWrite(ctx, "\n");
                                },
                            }
                        }
                        try child.render(ctx);
                        i += 1;
                    }
                }
            },
            .dbox => |db| {
                const kids = if (db.owned_children) |oc| oc else db.children;
                if (ctx.drawer != null and ctx.allocator != null) {
                    const alloc = ctx.allocator.?;
                    const boxes = try db.layout(alloc);
                    for (kids, 0..) |child, idx| {
                        var child_ctx = ctx.*;
                        child_ctx.origin_x = boxes[idx].origin_x;
                        child_ctx.origin_y = boxes[idx].origin_y;
                        try child.render(&child_ctx);
                    }
                } else {
                    for (kids) |child| try child.render(ctx);
                }
            },
            .cursor => |c| {
                if (c.child) |ch| try ch.*.render(ctx);
            },
            .container => |container_node| {
                const kids = if (container_node.owned_children) |oc| oc else container_node.children;
                if (ctx.drawer != null and ctx.allocator != null) {
                    const alloc = ctx.allocator.?;
                    const boxes = try container_node.layout(alloc);
                    for (kids, 0..) |child, idx| {
                        var child_ctx = ctx.*;
                        child_ctx.origin_x = boxes[idx].origin_x;
                        child_ctx.origin_y = boxes[idx].origin_y;
                        try child.render(&child_ctx);
                    }
                } else {
                    try container_node.render(ctx);
                }
            },
            else => {},
        }
    }

    pub fn select(self: Node, selection: *Selection) void {
        switch (self) {
            .text => |text_node| {
                selection.setAccessibility(.text, text_node.content, "", text_node.content, "");
                selection.setCursor(0, 0);
            },
            .container => |container_node| {
                var mut_container = container_node;
                mut_container.select(selection);
            },
            .frame => |f| {
                f.child.*.select(selection);
                if (selection.has_focus) {
                    selection.setAccessibility(.container, "Frame", "", selection.value, selection.state);
                }
            },
            .gradient_text => |g| {
                selection.setAccessibility(.text, "Gradient Text", "", g.text, "");
                selection.setCursor(0, 0);
            },
            .style => |s| {
                s.child.*.select(selection);
            },
            .size => |s| {
                s.child.*.select(selection);
            },
            .focus => |fx| {
                fx.child.*.select(selection);
                if (selection.has_focus) {
                    selection.setFocus();
                }
            },
            .flexbox => |fb| {
                const kids = if (fb.owned_children) |oc| oc else fb.children;
                selection.setAccessibility(.container, "Flexbox", "", "", "");
                for (kids) |child| {
                    var child_selection = Selection.init();
                    child.select(&child_selection);
                    if (child_selection.has_focus) {
                        selection.* = child_selection;
                        break;
                    }
                }
            },
            .dbox => |db| {
                const kids = if (db.owned_children) |oc| oc else db.children;
                selection.setAccessibility(.container, "Dbox", "", "", "");
                for (kids) |child| {
                    var child_selection = Selection.init();
                    child.select(&child_selection);
                    if (child_selection.has_focus) {
                        selection.* = child_selection;
                        break;
                    }
                }
            },
            .cursor => |c| {
                if (c.child) |ch| {
                    ch.*.select(selection);
                    selection.setFocus();
                    selection.setCursor(c.index, 0);
                    // Update accessibility if it's a text input
                    if (selection.role == .text) {
                        selection.role = .text_input;
                    }
                } else {
                    selection.clear();
                }
            },
            .window => |w| {
                selection.setAccessibility(.container, w.title, "Window frame", "", "");
            },
            .gauge => |g| {
                const value_str = if (g.fraction > 0.0) "filled" else "empty";
                selection.setAccessibility(.none, "Gauge", "Progress indicator", "", value_str);
            },
            .spinner => |s| {
                selection.setAccessibility(.none, "Spinner", "Loading indicator", s.currentFrame(), "");
            },
            .paragraph => |p| {
                selection.setAccessibility(.text, "Paragraph", "", p.content, "");
                selection.setCursor(0, 0);
            },
            .graph => |g| {
                _ = g;
                selection.setAccessibility(.text, "Graph", "Data visualization", "", "");
                selection.setCursor(0, 0);
            },
            .canvas => |c| {
                _ = c;
                selection.setAccessibility(.text, "Canvas", "Custom drawing", "", "");
                selection.setCursor(0, 0);
            },
            .separator => {
                selection.setAccessibility(.none, "Separator", "Visual separator", "", "");
            },
            else => selection.clear(),
        }
    }

    pub fn getSelectedContent(self: Node, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self) {
            .text => |text_node| text_node.content,
            .frame => |f| try f.child.*.getSelectedContent(allocator),
            .gradient_text => |g| try allocator.dupe(u8, g.text),
            .style => |s| try s.child.*.getSelectedContent(allocator),
            .size => |s| try s.child.*.getSelectedContent(allocator),
            .focus => |fx| try fx.child.*.getSelectedContent(allocator),
            .flexbox => |fb| blkSel: {
                // Return first child's content by convention
                const kids = if (fb.owned_children) |oc| oc else fb.children;
                if (kids.len == 0) break :blkSel "";
                break :blkSel try kids[0].getSelectedContent(allocator);
            },
            .dbox => |db| blkSel2: {
                const kids = if (db.owned_children) |oc| oc else db.children;
                if (kids.len == 0) break :blkSel2 "";
                break :blkSel2 try kids[kids.len - 1].getSelectedContent(allocator);
            },
            .cursor => |c| blkSel3: {
                if (c.child) |ch| break :blkSel3 try ch.*.getSelectedContent(allocator);
                break :blkSel3 "";
            },
            else => "",
        };
    }
};

pub const Text = struct {
    content: []const u8,
};

pub const CustomRenderer = struct {
    callback: *const fn (user_data: ?*anyopaque, ctx: *RenderContext) anyerror!void,
    user_data: ?*anyopaque = null,
};

pub const Orientation = enum { vertical, horizontal };

pub const Separator = struct {
    orientation: Orientation = .horizontal,
};

pub const WindowFrame = struct {
    title: []const u8 = "",
};

pub const Gauge = struct {
    fraction: f32 = 0.0,
    width: usize = 10,
};

pub const Spinner = struct {
    frames: []const []const u8 = &[_][]const u8{ "-", "\\", "|", "/" },
    index: usize = 0,

    pub fn currentFrame(self: Spinner) []const u8 {
        if (self.frames.len == 0) return "";
        return self.frames[self.index % self.frames.len];
    }

    pub fn advance(self: *Spinner) void {
        self.index +%= 1;
    }
};

pub const Paragraph = struct {
    content: []const u8,
    width: usize = 40,
};

pub const Graph = struct {
    values: []const f32 = &[_]f32{},
    width: usize = 0,
    height: usize = 4,
    min_value: ?f32 = null,
    max_value: ?f32 = null,
    fill_char: u8 = '#',
    empty_char: u8 = ' ',

    const Dimensions = struct { width: usize, height: usize };
    const Extents = struct { min: f32, max: f32 };

    pub fn dimensions(self: Graph) Dimensions {
        const raw_width = if (self.width > 0) self.width else self.values.len;
        const width = if (raw_width == 0) 1 else raw_width;
        const height = if (self.height == 0) 1 else self.height;
        return .{ .width = width, .height = height };
    }

    fn extents(self: Graph) Extents {
        var min_val: f32 = if (self.values.len > 0) self.values[0] else 0.0;
        var max_val: f32 = min_val;
        if (self.values.len > 0) {
            for (self.values[1..]) |val| {
                min_val = @min(min_val, val);
                max_val = @max(max_val, val);
            }
        }
        if (self.min_value) |mv| min_val = mv;
        if (self.max_value) |mv| max_val = mv;
        if (max_val <= min_val) {
            max_val = min_val + 1.0;
        }
        return .{ .min = min_val, .max = max_val };
    }

    fn sampleValue(self: Graph, column: usize, width: usize) f32 {
        if (self.values.len == 0) return 0.0;
        if (self.values.len == width) {
            return self.values[@min(column, self.values.len - 1)];
        }
        const scaled = column * self.values.len;
        const idx = @min(self.values.len - 1, scaled / width);
        return self.values[idx];
    }

    pub fn render(self: Graph, ctx: *RenderContext) anyerror!void {
        const dims = self.dimensions();
        const width = dims.width;
        const height = dims.height;
        const ext = self.extents();
        const range = ext.max - ext.min;
        var row: usize = 0;
        while (row < height) : (row += 1) {
            var col: usize = 0;
            while (col < width) : (col += 1) {
                const value = self.sampleValue(col, width);
                const normalized = if (range <= 0.0)
                    0.0
                else
                    std.math.clamp((value - ext.min) / range, 0.0, 1.0);
                var filled_rows: usize = @intFromFloat(@round(normalized * @as(f32, @floatFromInt(height))));
                if (filled_rows > height) filled_rows = height;
                const threshold = height - row;
                const draw_fill = filled_rows >= threshold and filled_rows > 0;
                const ch = if (draw_fill) self.fill_char else self.empty_char;
                if (ctx.drawer != null) {
                    const cell = [1]u8{ch};
                    try ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(col)), ctx.origin_y + @as(i32, @intCast(row)), cell[0..]);
                } else {
                    const cell = [1]u8{ch};
                    try ctxWrite(ctx, cell[0..]);
                }
            }
            if (ctx.drawer == null) {
                try ctxWrite(ctx, "\n");
            }
        }
    }
};

pub const GradientText = struct {
    text: []const u8,
    start_color: u24,
    end_color: u24,

    fn render(self: GradientText, ctx: *RenderContext) !void {
        if (self.text.len == 0) return;
        const saved = ctx.style;
        const total = self.text.len;
        var idx: usize = 0;
        while (idx < total) : (idx += 1) {
            const ratio = if (total <= 1) 0 else @as(f32, @floatFromInt(idx)) / @as(f32, @floatFromInt(total - 1));
            const blended = blendColor(self.start_color, self.end_color, ratio);
            const next_style = mergeStyles(saved, .{ .fg = blended });
            ctx.style = next_style;
            if (ctx.drawer != null) {
                try ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(idx)), ctx.origin_y, self.text[idx .. idx + 1]);
            } else {
                try applyAnsiStyle(ctx, next_style);
                try ctxWrite(ctx, self.text[idx .. idx + 1]);
            }
        }
        ctx.style = saved;
        if (ctx.drawer == null) {
            try applyAnsiStyle(ctx, saved);
        }
    }
};

pub const Canvas = struct {
    rows: []const []const u8 = &[_][]const u8{},
    width: usize = 0,
    height: usize = 0,
    fill_char: u8 = ' ',

    const Dimensions = struct { width: usize, height: usize };

    pub fn dimensions(self: Canvas) Dimensions {
        var width = self.width;
        for (self.rows) |row| {
            width = @max(width, row.len);
        }
        const height = if (self.height > 0) self.height else self.rows.len;
        return .{ .width = width, .height = height };
    }

    pub fn render(self: Canvas, ctx: *RenderContext) anyerror!void {
        const dims = self.dimensions();
        if (dims.height == 0 and dims.width == 0) return;
        var row_idx: usize = 0;
        while (row_idx < dims.height) : (row_idx += 1) {
            const row_data = if (row_idx < self.rows.len) self.rows[row_idx] else "";
            if (ctx.drawer != null) {
                var col: usize = 0;
                while (col < dims.width) : (col += 1) {
                    const ch = if (col < row_data.len) row_data[col] else self.fill_char;
                    const cell = [1]u8{ch};
                    try ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(col)), ctx.origin_y + @as(i32, @intCast(row_idx)), cell[0..]);
                }
            } else {
                if (dims.width == 0) {
                    try ctxWrite(ctx, "\n");
                    continue;
                }
                var col: usize = 0;
                while (col < dims.width) : (col += 1) {
                    const ch = if (col < row_data.len) row_data[col] else self.fill_char;
                    const cell = [1]u8{ch};
                    try ctxWrite(ctx, cell[0..]);
                }
                try ctxWrite(ctx, "\n");
            }
        }
    }
};

pub const FrameBorderStyle = enum { single, double };

pub const FrameBorder = struct {
    charset: FrameBorderStyle = .single,
    fg: ?u24 = null,
    fg_palette: ?PaletteColor = null,
};

pub const Frame = struct {
    child: *const Node,
    border: FrameBorder = .{},
};

pub const StyleDecorator = struct {
    child: *const Node,
    attrs: StyleAttributes = .{},
};

pub const Size = struct {
    child: *const Node,
    width: usize = 0,
    height: usize = 0,
};

pub const Filler = struct {
    grow: f32 = 1,
    shrink: f32 = 1,
};

pub const Focus = struct {
    child: *const Node,
    position: FocusPosition = .center,
};

pub const FlexDirection = enum { row, column };

pub const Flexbox = struct {
    children: []const Node = &[_]Node{},
    direction: FlexDirection = .row,
    gap: usize = 0,
    box: Box = .{},
    owned_children: ?[]Node = null,

    pub fn layout(self: Flexbox, allocator: std.mem.Allocator) ![]Box {
        const boxes = try allocator.alloc(Box, self.children.len);
        var x: i32 = self.box.origin_x;
        var y: i32 = self.box.origin_y;
        var i: usize = 0;
        switch (self.direction) {
            .row => {
                while (i < self.children.len) : (i += 1) {
                    const cr = self.children[i].computeRequirement();
                    boxes[i] = .{ .origin_x = x, .origin_y = y, .width = @intCast(cr.min_width), .height = @intCast(@min(@as(usize, self.box.height), cr.min_height)) };
                    x += @as(i32, @intCast(cr.min_width + self.gap));
                }
            },
            .column => {
                while (i < self.children.len) : (i += 1) {
                    const cr = self.children[i].computeRequirement();
                    boxes[i] = .{ .origin_x = x, .origin_y = y, .width = @intCast(@min(@as(usize, self.box.width), cr.min_width)), .height = @intCast(cr.min_height) };
                    y += @as(i32, @intCast(cr.min_height + self.gap));
                }
            },
        }
        return boxes;
    }

    pub fn applyLayout(self: *Flexbox, allocator: std.mem.Allocator) !void {
        const boxes = try self.layout(allocator);
        const owned = try allocator.dupe(Node, self.children);
        for (owned, 0..) |*child, i| child.setBox(boxes[i]);
        self.owned_children = owned;
    }
};

pub const Dbox = struct {
    children: []const Node = &[_]Node{},
    box: Box = .{},
    owned_children: ?[]Node = null,

    pub fn layout(self: Dbox, allocator: std.mem.Allocator) ![]Box {
        const boxes = try allocator.alloc(Box, self.children.len);
        for (boxes) |*b| b.* = self.box;
        return boxes;
    }

    pub fn applyLayout(self: *Dbox, allocator: std.mem.Allocator) !void {
        const boxes = try self.layout(allocator);
        const owned = try allocator.dupe(Node, self.children);
        for (owned, 0..) |*child, i| child.setBox(boxes[i]);
        self.owned_children = owned;
    }
};

pub const Cursor = struct {
    child: ?*const Node = null,
    index: usize = 0,
};

pub const Container = struct {
    children: []const Node = &[_]Node{},
    box: Box = .{},
    orientation: Orientation = .vertical,
    owned_children: ?[]Node = null,

    pub fn computeRequirement(self: Container) Requirement {
        var req = Requirement{};
        switch (self.orientation) {
            .vertical => {
                for (self.children) |child| {
                    const child_req = child.computeRequirement();
                    req.min_width = @max(req.min_width, child_req.min_width);
                    req.min_height += child_req.min_height;
                }
            },
            .horizontal => {
                for (self.children) |child| {
                    const child_req = child.computeRequirement();
                    req.min_width += child_req.min_width;
                    req.min_height = @max(req.min_height, child_req.min_height);
                }
            },
        }
        return req;
    }

    pub fn render(self: Container, ctx: *RenderContext) anyerror!void {
        const kids = if (self.owned_children) |oc| oc else self.children;
        for (kids) |child| try child.render(ctx);
    }

    pub fn layout(self: Container, allocator: std.mem.Allocator) ![]Box {
        const boxes = try allocator.alloc(Box, self.children.len);
        var x: i32 = self.box.origin_x;
        var y: i32 = self.box.origin_y;
        var i: usize = 0;
        switch (self.orientation) {
            .vertical => {
                while (i < self.children.len) : (i += 1) {
                    const cr = self.children[i].computeRequirement();
                    boxes[i] = .{ .origin_x = x, .origin_y = y, .width = self.box.width, .height = @intCast(cr.min_height) };
                    y += @as(i32, @intCast(cr.min_height));
                }
            },
            .horizontal => {
                while (i < self.children.len) : (i += 1) {
                    const cr = self.children[i].computeRequirement();
                    boxes[i] = .{ .origin_x = x, .origin_y = y, .width = @intCast(cr.min_width), .height = self.box.height };
                    x += @as(i32, @intCast(cr.min_width));
                }
            },
        }
        return boxes;
    }

    pub fn applyLayout(self: *Container, allocator: std.mem.Allocator) !void {
        const boxes = try self.layout(allocator);
        const owned = try allocator.dupe(Node, self.children);
        for (owned, 0..) |*child, i| {
            child.setBox(boxes[i]);
        }
        self.owned_children = owned;
    }

    pub fn select(self: *Container, selection: *Selection) void {
        const kids = if (self.owned_children) |oc| oc else self.children;
        selection.setAccessibility(.container, "Container", "", "", "");
        for (kids) |child| {
            var tmp = child;
            var child_selection = Selection.init();
            tmp.select(&child_selection);
            if (child_selection.has_focus) {
                selection.* = child_selection;
                break;
            }
        }
    }

    pub fn check(self: Container) void {
        const kids = if (self.owned_children) |oc| oc else self.children;
        for (kids) |child| child.check();
    }
};

test "text node requirement uses content length" {
    const node = Node{ .text = .{ .content = "hello" } };
    const req = node.computeRequirement();
    try std.testing.expectEqual(@as(usize, 5), req.min_width);
    try std.testing.expectEqual(@as(usize, 1), req.min_height);
}

test "container aggregates child requirements" {
    const node = Node{
        .container = .{
            .children = &[_]Node{
                .{ .text = .{ .content = "abc" } },
                .{ .text = .{ .content = "toolong" } },
            },
        },
    };
    const req = node.computeRequirement();
    try std.testing.expectEqual(@as(usize, 7), req.min_width);
    try std.testing.expectEqual(@as(usize, 2), req.min_height);
}

test "hbox aggregates horizontally (sum widths, max height)" {
    const node = Node{
        .container = .{
            .orientation = .horizontal,
            .children = &[_]Node{
                .{ .text = .{ .content = "abc" } }, // 3x1
                .{ .text = .{ .content = "toolong" } }, // 7x1
            },
        },
    };
    const req = node.computeRequirement();
    try std.testing.expectEqual(@as(usize, 10), req.min_width);
    try std.testing.expectEqual(@as(usize, 1), req.min_height);
}

test "setBox updates container dimensions" {
    var node = Node{ .container = .{ .children = &[_]Node{} } };
    const expected_box = Box{ .origin_x = 1, .origin_y = 2, .width = 10, .height = 3 };
    node.setBox(expected_box);
    const observed_box = switch (node) {
        .container => |container| container.box,
        else => unreachable,
    };
    try std.testing.expectEqual(expected_box, observed_box);
}

test "getSelectedContent returns textual content" {
    const text_node = Node{ .text = .{ .content = "zettui" } };
    const selected = try text_node.getSelectedContent(std.testing.allocator);
    try std.testing.expectEqualStrings("zettui", selected);
}

test "separator requirement is at least 1x1" {
    const sep = Node{ .separator = .{} };
    const req = sep.computeRequirement();
    try std.testing.expectEqual(@as(usize, 1), req.min_width);
    try std.testing.expectEqual(@as(usize, 1), req.min_height);
}

test "window requirement accounts for title length" {
    const wnd = Node{ .window = .{ .title = "hi" } };
    const req = wnd.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), req.min_width); // '[' + 'hi' + ']'
    try std.testing.expectEqual(@as(usize, 1), req.min_height);
}

test "gauge default width is 10" {
    const g = Node{ .gauge = .{ .fraction = 0.5 } };
    const req = g.computeRequirement();
    try std.testing.expectEqual(@as(usize, 10), req.min_width);
    try std.testing.expectEqual(@as(usize, 1), req.min_height);
}

test "spinner width equals current frame length" {
    const s = Node{ .spinner = .{} };
    const req = s.computeRequirement();
    try std.testing.expectEqual(@as(usize, 1), req.min_width);
}

test "spinner advance cycles frames" {
    var n = Node{ .spinner = .{} };
    const before = switch (n) {
        .spinner => |s| s.currentFrame(),
        else => unreachable,
    };
    switch (n) {
        .spinner => |*s| s.advance(),
        else => unreachable,
    }
    const after = switch (n) {
        .spinner => |s| s.currentFrame(),
        else => unreachable,
    };
    try std.testing.expect(!std.mem.eql(u8, before, after));
}

test "paragraph requirement uses width and line count" {
    const p = Node{ .paragraph = .{ .content = "hello world", .width = 5 } };
    const req = p.computeRequirement();
    try std.testing.expectEqual(@as(usize, 5), req.min_width);
    try std.testing.expectEqual(@as(usize, 3), req.min_height);
}

test "graph requirement uses explicit overrides" {
    const g = Node{ .graph = .{ .values = &[_]f32{ 0.25, 0.5 }, .width = 4, .height = 3 } };
    const req = g.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), req.min_width);
    try std.testing.expectEqual(@as(usize, 3), req.min_height);
}

test "graph render outputs ascii sparkline" {
    var managed = std.array_list.Managed(u8).init(std.testing.allocator);
    defer managed.deinit();
    const Adapter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };
    var ctx: RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&managed)), .writeAll = Adapter.write },
    };
    const node = Node{ .graph = .{
        .values = &[_]f32{ 0.0, 0.5, 1.0 },
        .height = 2,
        .empty_char = '.',
        .fill_char = '#',
    } };
    try node.render(&ctx);
    try std.testing.expectEqualStrings("..#\n.##\n", managed.items);
}

test "gradient text requirement uses length" {
    const node = Node{ .gradient_text = .{
        .text = "grad",
        .start_color = 0x000000,
        .end_color = 0xFFFFFF,
    } };
    const req = node.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), req.min_width);
    try std.testing.expectEqual(@as(usize, 1), req.min_height);
}

test "gradient text render emits ansi color ramp" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const node = Node{ .gradient_text = .{
        .text = "ab",
        .start_color = 0xFF0000,
        .end_color = 0x0000FF,
    } };

    var buffer = std.array_list.Managed(u8).init(alloc);
    defer buffer.deinit();
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };
    var ctx = RenderContext{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&buffer)), .writeAll = SinkWriter.write },
    };
    try node.render(&ctx);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[38;2;255;0;0m") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[38;2;0;0;255m") != null);
}

test "canvas requirement tracks widest row" {
    const node = Node{ .canvas = .{ .rows = &[_][]const u8{ "x", "wide" } } };
    const req = node.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), req.min_width);
    try std.testing.expectEqual(@as(usize, 2), req.min_height);
}

test "canvas render pads missing cells" {
    var managed = std.array_list.Managed(u8).init(std.testing.allocator);
    defer managed.deinit();
    const Adapter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };
    var ctx: RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&managed)), .writeAll = Adapter.write },
    };
    const node = Node{ .canvas = .{
        .rows = &[_][]const u8{ "xo", "ox" },
        .width = 3,
        .height = 3,
        .fill_char = '.',
    } };
    try node.render(&ctx);
    try std.testing.expectEqualStrings("xo.\nox.\n...\n", managed.items);
}

test "style decorator emits ansi sequences when rendering" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const child_ptr = try alloc.create(Node);
    child_ptr.* = Node{ .text = .{ .content = "hi" } };
    const styled = Node{
        .style = .{ .child = child_ptr, .attrs = .{ .bold = true, .fg = 0x112233 } },
    };

    var buffer = std.array_list.Managed(u8).init(alloc);
    defer buffer.deinit();
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };

    var ctx = RenderContext{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&buffer)), .writeAll = SinkWriter.write },
    };
    try styled.render(&ctx);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[1m") != null);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[38;2;17;34;51m") != null);
    try std.testing.expect(std.mem.endsWith(u8, buffer.items, "\x1b[0m"));
}

test "style decorator supports palette colors" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const child_ptr = try alloc.create(Node);
    child_ptr.* = Node{ .text = .{ .content = "pal" } };
    const styled = Node{
        .style = .{ .child = child_ptr, .attrs = .{ .fg_palette = .bright_red } },
    };

    var buffer = std.array_list.Managed(u8).init(alloc);
    defer buffer.deinit();
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };

    var ctx = RenderContext{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&buffer)), .writeAll = SinkWriter.write },
    };
    try styled.render(&ctx);
    try std.testing.expect(std.mem.indexOf(u8, buffer.items, "\x1b[38;2;255;85;85m") != null);
}

test "frame requirement adds borders" {
    const child = Node{ .text = .{ .content = "hi" } };
    const n = Node{ .frame = .{ .child = &child } };
    const req = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), req.min_width);
    try std.testing.expectEqual(@as(usize, 3), req.min_height);
}

test "frame renders paragraph with per-line borders and padding" {
    var managed = std.array_list.Managed(u8).init(std.testing.allocator);
    defer managed.deinit();
    const Adapter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };
    var ctx: RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&managed)), .writeAll = Adapter.write },
    };

    const para = Node{ .paragraph = .{ .content = "hello", .width = 4 } };
    const n = Node{ .frame = .{ .child = &para } };
    try n.render(&ctx);

    const expected =
        "\xE2\x94\x8C\xE2\x94\x80\xE2\x94\x80\xE2\x94\x80\xE2\x94\x80\xE2\x94\x90\n" ++
        "\xE2\x94\x82hell\xE2\x94\x82\n" ++
        "\xE2\x94\x82o   \xE2\x94\x82\n" ++
        "\xE2\x94\x94\xE2\x94\x80\xE2\x94\x80\xE2\x94\x80\xE2\x94\x80\xE2\x94\x98\n" ++
        "\x1b[0m";
    try std.testing.expectEqualStrings(expected, managed.items);
}

test "frame supports double border charset" {
    var managed = std.array_list.Managed(u8).init(std.testing.allocator);
    defer managed.deinit();
    const Adapter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };
    var ctx: RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&managed)), .writeAll = Adapter.write },
    };

    const child = Node{ .text = .{ .content = "x" } };
    const node = Node{ .frame = .{ .child = &child, .border = .{ .charset = .double } } };
    try node.render(&ctx);
    try std.testing.expect(std.mem.indexOf(u8, managed.items, "\xE2\x95\x94") != null); // double top-left
}

test "size requirement is at least given dims" {
    const child = Node{ .text = .{ .content = "abc" } }; // 3x1
    const n1 = Node{ .size = .{ .child = &child, .width = 10, .height = 2 } };
    const r1 = n1.computeRequirement();
    try std.testing.expectEqual(@as(usize, 10), r1.min_width);
    try std.testing.expectEqual(@as(usize, 2), r1.min_height);

    const n2 = Node{ .size = .{ .child = &child, .width = 2, .height = 0 } };
    const r2 = n2.computeRequirement();
    // width clamps to child's 3, height clamps to child's 1
    try std.testing.expectEqual(@as(usize, 3), r2.min_width);
    try std.testing.expectEqual(@as(usize, 1), r2.min_height);
}

test "filler has zero min size and positive grow" {
    const n = Node{ .filler = .{ .grow = 2, .shrink = 0.5 } };
    const r = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 0), r.min_width);
    try std.testing.expectEqual(@as(usize, 0), r.min_height);
    try std.testing.expectApproxEqRel(@as(f32, 2.0), r.flex_grow, 0.0001);
}

test "focus decorator sets requirement focus" {
    const child = Node{ .text = .{ .content = "hi" } };
    const n = Node{ .focus = .{ .child = &child, .position = .end } };
    const r = n.computeRequirement();
    try std.testing.expect(r.focus != null);
    try std.testing.expectEqual(FocusPosition.end, r.focus.?);
}

test "flexbox row aggregates widths plus gap" {
    const n = Node{ .flexbox = .{
        .direction = .row,
        .gap = 1,
        .children = &[_]Node{
            .{ .text = .{ .content = "ab" } },
            .{ .text = .{ .content = "tool" } },
        },
    } };
    const r = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 7), r.min_width); // 2 + 1 + 4
    try std.testing.expectEqual(@as(usize, 1), r.min_height);
}

test "flexbox column aggregates heights plus gap" {
    const n = Node{ .flexbox = .{
        .direction = .column,
        .gap = 2,
        .children = &[_]Node{
            .{ .text = .{ .content = "ab" } },
            .{ .text = .{ .content = "tool" } },
        },
    } };
    const r = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), r.min_width);
    try std.testing.expectEqual(@as(usize, 4), r.min_height); // 1 + 2 + 1
}

test "dbox aggregates by max width/height" {
    const n = Node{
        .dbox = .{
            .children = &[_]Node{
                .{ .text = .{ .content = "abc" } }, // 3x1
                .{ .text = .{ .content = "toolong" } }, // 7x1
            },
        },
    };
    const r = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 7), r.min_width);
    try std.testing.expectEqual(@as(usize, 1), r.min_height);
}

test "cursor decorator sets selection index and focus" {
    const child = Node{ .text = .{ .content = "abc" } };
    var n = Node{ .cursor = .{ .child = &child, .index = 2 } };
    var sel = Selection.init();
    n.select(&sel);
    try std.testing.expect(sel.has_focus);
    try std.testing.expectEqual(@as(usize, 2), sel.cursor_index);
}

test "selection accessibility information for text node" {
    const text_node = Node{ .text = .{ .content = "Hello" } };
    var sel = Selection.init();
    var mut_text = text_node;
    mut_text.select(&sel);
    try std.testing.expectEqual(AccessibilityRole.text, sel.role);
    try std.testing.expectEqualStrings("Hello", sel.label);
}

test "selection accessibility information for window" {
    const window_node = Node{ .window = .{ .title = "Test Window" } };
    var sel = Selection.init();
    var mut_window = window_node;
    mut_window.select(&sel);
    try std.testing.expectEqual(AccessibilityRole.container, sel.role);
    try std.testing.expectEqualStrings("Test Window", sel.label);
    try std.testing.expectEqualStrings("Window frame", sel.description);
}

test "selection cursor position tracking" {
    const child = Node{ .text = .{ .content = "Hello\nWorld" } };
    var n = Node{ .cursor = .{ .child = &child, .index = 7 } };
    var sel = Selection.init();
    n.select(&sel);
    try std.testing.expect(sel.has_focus);
    try std.testing.expectEqual(@as(usize, 7), sel.cursor_index);
    try std.testing.expectEqual(AccessibilityRole.text_input, sel.role);
}

test "selection text selection range" {
    var sel = Selection.init();
    sel.setSelection(2, 5);
    try std.testing.expect(sel.selection_start != null);
    try std.testing.expect(sel.selection_end != null);
    try std.testing.expectEqual(@as(usize, 2), sel.selection_start.?);
    try std.testing.expectEqual(@as(usize, 5), sel.selection_end.?);

    sel.clearSelection();
    try std.testing.expect(sel.selection_start == null);
    try std.testing.expect(sel.selection_end == null);
}

test "selection accessibility description generation" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var sel = Selection.init();
    sel.setAccessibility(.button, "Submit", "Click to submit form", "", "enabled");
    const desc = try sel.getAccessibilityDescription(allocator);
    defer allocator.free(desc);

    try std.testing.expect(std.mem.indexOf(u8, desc, "Submit") != null);
    try std.testing.expect(std.mem.indexOf(u8, desc, "enabled") != null);
    try std.testing.expect(std.mem.indexOf(u8, desc, "Click to submit form") != null);
}

test "selection focus management" {
    var sel = Selection.init();
    try std.testing.expect(!sel.has_focus);

    sel.setFocus();
    try std.testing.expect(sel.has_focus);

    sel.clearFocus();
    try std.testing.expect(!sel.has_focus);
}

test "selection container finds focused child" {
    const text_node = Node{ .text = .{ .content = "focused" } };
    const focused_child = Node{ .cursor = .{ .child = &text_node, .index = 0 } };
    const other_child = Node{ .text = .{ .content = "other" } };
    var container_node = Node{ .container = .{
        .children = &[_]Node{ other_child, focused_child },
    } };
    var sel = Selection.init();
    container_node.select(&sel);
    // Container should find and return the focused child's selection
    try std.testing.expect(sel.has_focus);
}

test "flexbox setBox updates own box" {
    var n = Node{ .flexbox = .{ .children = &[_]Node{} } };
    const b = Box{ .origin_x = 0, .origin_y = 0, .width = 20, .height = 3 };
    n.setBox(b);
    const observed = switch (n) {
        .flexbox => |fb| fb.box,
        else => unreachable,
    };
    try std.testing.expectEqual(b, observed);
}

test "dbox setBox updates own box" {
    var n = Node{ .dbox = .{ .children = &[_]Node{} } };
    const b = Box{ .origin_x = 1, .origin_y = 1, .width = 5, .height = 5 };
    n.setBox(b);
    const observed = switch (n) {
        .dbox => |db| db.box,
        else => unreachable,
    };
    try std.testing.expectEqual(b, observed);
}

test "container vertical layout assigns stacked boxes" {
    var node = Node{ .container = .{
        .orientation = .vertical,
        .children = &[_]Node{
            .{ .text = .{ .content = "aa" } },
            .{ .text = .{ .content = "bbbb" } },
        },
    } };
    node.setBox(.{ .origin_x = 0, .origin_y = 0, .width = 10, .height = 5 });
    const cont = switch (node) {
        .container => |c| c,
        else => unreachable,
    };
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const boxes = try cont.layout(arena.allocator());
    try std.testing.expectEqual(@as(usize, 2), boxes.len);
    try std.testing.expectEqual(@as(u32, 10), boxes[0].width);
    try std.testing.expectEqual(@as(u32, 1), boxes[0].height);
    try std.testing.expectEqual(@as(i32, 1), boxes[1].origin_y);
    try std.testing.expectEqual(@as(u32, 1), boxes[1].height);
}

test "flexbox row layout assigns consecutive boxes with gaps" {
    var node = Node{ .flexbox = .{
        .direction = .row,
        .gap = 1,
        .children = &[_]Node{
            .{ .text = .{ .content = "a" } },
            .{ .text = .{ .content = "bc" } },
        },
    } };
    node.setBox(.{ .origin_x = 0, .origin_y = 0, .width = 10, .height = 2 });
    const fb = switch (node) {
        .flexbox => |f| f,
        else => unreachable,
    };
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const boxes = try fb.layout(arena.allocator());
    try std.testing.expectEqual(@as(usize, 2), boxes.len);
    try std.testing.expectEqual(@as(i32, 0), boxes[0].origin_x);
    try std.testing.expectEqual(@as(i32, 2), boxes[1].origin_x); // 1 width + 1 gap
}

test "container applyLayout sets owned child boxes" {
    var node = Node{ .container = .{
        .orientation = .horizontal,
        .children = &[_]Node{
            .{ .text = .{ .content = "aaa" } },
            .{ .text = .{ .content = "bb" } },
        },
    } };
    node.setBox(.{ .origin_x = 0, .origin_y = 0, .width = 10, .height = 2 });
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var cont_ptr: *Container = switch (node) {
        .container => |*c| c,
        else => unreachable,
    };
    try cont_ptr.applyLayout(arena.allocator());
    const kids = cont_ptr.owned_children.?;
    try std.testing.expectEqual(@as(usize, 2), kids.len);
}
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

fn ctxDraw(ctx: *RenderContext, x: i32, y: i32, text: []const u8) !void {
    if (ctx.drawer) |d| {
        try d.drawText(d.user_data, x, y, text, ctx.style);
    } else {
        try ctxWrite(ctx, text);
    }
}
fn frameWrite(ctx: *RenderContext, x: i32, y: i32, text: []const u8) !void {
    if (ctx.drawer != null) {
        try ctxDraw(ctx, x, y, text);
    } else {
        try ctxWrite(ctx, text);
    }
}
