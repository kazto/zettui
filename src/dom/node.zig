const std = @import("std");

const common = @import("node/common.zig");
pub const Text = @import("node/text.zig").Text;
const container_mod = @import("node/container.zig");
pub const CustomRenderer = @import("node/custom_renderer.zig").CustomRenderer;
pub const Separator = @import("node/separator.zig").Separator;
pub const WindowFrame = @import("node/window_frame.zig").WindowFrame;
pub const Gauge = @import("node/gauge.zig").Gauge;
pub const GaugeOrientation = @import("node/gauge.zig").GaugeOrientation;
pub const Spinner = @import("node/spinner.zig").Spinner;
pub const Paragraph = @import("node/paragraph.zig").Paragraph;
pub const Graph = @import("node/graph.zig").Graph;
pub const Canvas = @import("node/canvas.zig").Canvas;
pub const CanvasAnimation = @import("node/canvas_animation.zig").CanvasAnimation;
pub const GradientText = @import("node/gradient_text.zig").GradientText;
pub const SeparatorStyle = @import("node/separator.zig").SeparatorStyle;
const gridbox_mod = @import("node/gridbox.zig");
const frame_mod = @import("node/frame.zig");
const size_mod = @import("node/size.zig");
pub const Filler = @import("node/filler.zig").Filler;
const focus_mod = @import("node/focus.zig");
const flexbox_mod = @import("node/flexbox.zig");
const ContainerType = container_mod.Container;
const GridBoxType = gridbox_mod.GridBox;
const FrameType = frame_mod.Frame;
const SizeType = size_mod.Size;
const FocusType = focus_mod.Focus;
const FlexboxType = flexbox_mod.Flexbox;

pub const FocusPosition = common.FocusPosition;
pub const ScrollIndicator = common.ScrollIndicator;
pub const Orientation = common.Orientation;
pub const Axis = common.Axis;
pub const Constraint = common.Constraint;
pub const Requirement = common.Requirement;
pub const AccessibilityRole = common.AccessibilityRole;
pub const Selection = common.Selection;
pub const PaletteColor = common.PaletteColor;
pub const StyleAttributes = common.StyleAttributes;
pub const Box = common.Box;
pub const RenderContext = common.RenderContext;
pub const Drawer = common.Drawer;
pub const Sink = common.Sink;
pub const paletteColorValue = common.paletteColorValue;
pub const FrameBorder = frame_mod.FrameBorder;
pub const FrameBorderStyle = frame_mod.FrameBorderStyle;
pub const FlexboxConfig = flexbox_mod.FlexboxConfig;
pub const FlexDirection = flexbox_mod.FlexDirection;
pub const Container = ContainerType(Node);
pub const GridBox = GridBoxType(Node);
pub const Frame = FrameType(Node);
pub const Size = SizeType(Node);
pub const Focus = FocusType(Node);
pub const Flexbox = FlexboxType(Node);

const ctxWrite = common.ctxWrite;
const ctxDraw = common.ctxDraw;
const applyAnsiStyle = common.applyAnsiStyle;
const mergeStyles = common.mergeStyles;
const frameWrite = common.frameWrite;

pub const Node = union(enum) {
    const Self = @This();

    empty: void,
    text: Text,
    container: ContainerType(Self),
    custom: CustomRenderer,
    separator: Separator,
    window: WindowFrame,
    gauge: Gauge,
    spinner: Spinner,
    paragraph: Paragraph,
    graph: Graph,
    canvas: Canvas,
    canvas_animation: CanvasAnimation,
    gradient_text: GradientText,
    gridbox: GridBoxType(Self),
    frame: FrameType(Self),
    size: SizeType(Self),
    filler: Filler,
    focus: FocusType(Self),
    flexbox: FlexboxType(Self),
    dbox: Dbox,
    cursor: Cursor,
    style: StyleDecorator,
    table: Table,
    automerge: Automerge,
    scroll: ScrollDecorator,
    center: Center,

    pub fn computeRequirement(self: Node) Requirement {
        return switch (self) {
            .text => |text_node| Requirement{ .min_width = text_node.content.len, .min_height = 1 },
            .separator => |sep| sep.requirement(),
            .window => |w| w.requirement(),
            .gauge => |g| g.requirement(),
            .spinner => |s| s.requirement(),
            .paragraph => |p| p.requirement(),
            .graph => |g| g.requirement(),
            .canvas => |c| c.requirement(),
            .canvas_animation => |anim| anim.requirement(),
            .gradient_text => |g| g.requirement(),
            .gridbox => |g| g.requirement(),
            .size => |s| s.requirement(),
            .filler => |f| f.requirement(),
            .focus => |fx| fx.requirement(),
            .flexbox => |fb| fb.requirement(),
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
                if (c.child) |ch| break :blkCur ch.*.computeRequirement();
                break :blkCur Requirement{};
            },
            .container => |container_node| container_node.computeRequirement(),
            .frame => |f| f.requirement(),
            .style => |s| blkStyle: {
                break :blkStyle s.child.*.computeRequirement();
            },
            .table => |t| blkTable: {
                const dims = t.bounds();
                break :blkTable Requirement{
                    .min_width = dims.width,
                    .min_height = dims.height,
                };
            },
            .automerge => |a| blkAuto: {
                const dims = a.dimensions();
                break :blkAuto Requirement{
                    .min_width = dims.width,
                    .min_height = dims.height,
                };
            },
            .scroll => |s| blkScroll: {
                var req = Requirement{};
                if (s.child) |child| {
                    req = child.*.computeRequirement();
                }
                req.min_height += if (s.indicator.top) 1 else 0;
                req.min_height += if (s.indicator.bottom) 1 else 0;
                req.min_width = @max(req.min_width, 1);
                break :blkScroll req;
            },
            .center => |c| blkCenter: {
                const child_req = c.child.*.computeRequirement();
                break :blkCenter Requirement{
                    .min_width = @max(child_req.min_width, c.width),
                    .min_height = child_req.min_height,
                };
            },
            else => Requirement{},
        };
    }

    pub fn setBox(self: *Node, box: Box) void {
        switch (self.*) {
            .container => |*container_node| container_node.box = box,
            .flexbox => |*fb| fb.box = box,
            .dbox => |*db| db.box = box,
            .center => |*c| {
                const child = @constCast(c.child);
                child.*.setBox(box);
            },
            .scroll => |*s| if (s.child) |child| {
                const child_mut = @constCast(child);
                child_mut.*.setBox(box);
            },
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
            .empty => {},
            .text => |text_node| {
                if (ctx.drawer != null) {
                    try ctxDraw(ctx, ctx.origin_x, ctx.origin_y, text_node.content);
                } else {
                    try ctxWrite(ctx, text_node.content);
                }
            },
            .paragraph => |p| try renderParagraph(p, ctx),
            .separator => |s| try s.render(ctx),
            .window => |w| {
                if (ctx.drawer != null) {
                    try ctxDraw(ctx, ctx.origin_x, ctx.origin_y, "[");
                    try ctxDraw(ctx, ctx.origin_x + 1, ctx.origin_y, w.title);
                    try ctxDraw(ctx, ctx.origin_x + 1 + @as(i32, @intCast(w.title.len)), ctx.origin_y, "]");
                } else {
                    try ctxWrite(ctx, "[");
                    try ctxWrite(ctx, w.title);
                    try ctxWrite(ctx, "]");
                }
            },
            .gauge => |g| try g.render(ctx),
            .spinner => |s| {
                const frame = s.currentFrame();
                if (ctx.drawer != null) {
                    try ctxDraw(ctx, ctx.origin_x, ctx.origin_y, frame);
                } else {
                    try ctxWrite(ctx, frame);
                }
            },
            .graph => |g| try g.render(ctx),
            .canvas => |c| try c.render(ctx),
            .canvas_animation => |anim| try anim.current().render(ctx),
            .gradient_text => |g| try g.render(ctx),
            .gridbox => |g| try g.render(ctx),
            .container => |container_node| try container_node.render(ctx),
            .frame => |f| try renderFrameNode(f, ctx),
            .size => |s| try s.child.*.render(ctx),
            .filler => {},
            .focus => |fx| try fx.child.*.render(ctx),
            .flexbox => |fb| {
                const kids = if (fb.owned_children) |oc| oc else fb.children;
                for (kids) |child| try child.render(ctx);
            },
            .dbox => |db| {
                const kids = if (db.owned_children) |oc| oc else db.children;
                for (kids) |child| try child.render(ctx);
            },
            .cursor => |c| if (c.child) |ch| try ch.*.render(ctx),
            .style => |s| try renderStyledChild(s, ctx),
            .table => |t| try t.render(ctx),
            .automerge => |a| try a.render(ctx),
            .scroll => |s| try s.render(ctx),
            .center => |c| try c.render(ctx),
            .custom => |c| try c.callback(c.user_data, ctx),
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
            .canvas_animation => |anim| {
                _ = anim;
                selection.setAccessibility(.text, "Canvas", "Animated drawing", "", "");
                selection.setCursor(0, 0);
            },
            .table => |t| {
                selection.setAccessibility(.table, "Table", "Tabular data", "", "");
                if (t.selected_row) |row_idx| {
                    selection.cursor_line = row_idx;
                    if (t.selected_column) |col_idx| selection.cursor_index = col_idx;
                }
            },
            .automerge => |a| {
                if (a.children.len > 0) {
                    a.children[0].select(selection);
                } else {
                    selection.clear();
                }
            },
            .scroll => |s| {
                if (s.child) |child| {
                    child.*.select(selection);
                } else {
                    selection.setAccessibility(.container, "Scroll indicator", "", "", "");
                }
            },
            .center => |c| c.child.*.select(selection),
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
            .table => |t| blkTable: {
                if (t.selected_row) |row_idx| {
                    if (row_idx < t.rows.len) {
                        const row = t.rows[row_idx];
                        if (t.selected_column) |col_idx| {
                            if (col_idx < row.len) break :blkTable row[col_idx];
                        }
                        if (row.len > 0) break :blkTable row[0];
                    }
                }
                break :blkTable "";
            },
            .automerge => |a| blkAuto: {
                if (a.children.len == 0) break :blkAuto "";
                break :blkAuto try a.children[0].getSelectedContent(allocator);
            },
            .scroll => |s| blkScroll: {
                if (s.child) |child| break :blkScroll try child.*.getSelectedContent(allocator);
                break :blkScroll "";
            },
            .center => |c| try c.child.*.getSelectedContent(allocator),
            .canvas_animation => "",
            else => "",
        };
    }
};

pub const CanvasBuilder = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    rows: [][]u8,
    fill_char: u8,
    owns_rows: bool = true,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, fill_char: u8) !CanvasBuilder {
        var rows = try allocator.alloc([]u8, height);
        var y: usize = 0;
        while (y < height) : (y += 1) {
            rows[y] = try allocator.alloc(u8, width);
            @memset(rows[y], fill_char);
        }
        return CanvasBuilder{
            .allocator = allocator,
            .width = width,
            .height = height,
            .rows = rows,
            .fill_char = fill_char,
            .owns_rows = true,
        };
    }

    pub fn drawPoint(self: *CanvasBuilder, x: usize, y: usize, ch: u8) void {
        self.setPixelSigned(@intCast(x), @intCast(y), ch);
    }

    fn setPixelSigned(self: *CanvasBuilder, x: i32, y: i32, ch: u8) void {
        if (x < 0 or y < 0) return;
        const ux: usize = @intCast(x);
        const uy: usize = @intCast(y);
        if (uy >= self.rows.len or ux >= self.width) return;
        self.rows[uy][ux] = ch;
    }

    pub fn drawHorizontalLine(self: *CanvasBuilder, y: usize, x0: usize, x1: usize, ch: u8) void {
        if (y >= self.rows.len) return;
        var col = @min(x0, x1);
        const end = @min(@max(x0, x1), self.width - 1);
        while (col <= end) : (col += 1) self.rows[y][col] = ch;
    }

    pub fn drawVerticalLine(self: *CanvasBuilder, x: usize, y0: usize, y1: usize, ch: u8) void {
        if (x >= self.width) return;
        var row = @min(y0, y1);
        const end = @min(@max(y0, y1), self.height - 1);
        while (row <= end) : (row += 1) self.rows[row][x] = ch;
    }

    pub fn drawLine(self: *CanvasBuilder, start_x: i32, start_y: i32, end_x: i32, end_y: i32, ch: u8) void {
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
            self.setPixelSigned(x0, y0, ch);
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

    pub fn drawCircle(self: *CanvasBuilder, center_x: i32, center_y: i32, radius: usize, ch: u8) void {
        if (radius == 0) {
            self.setPixelSigned(center_x, center_y, ch);
            return;
        }
        var x: i32 = @intCast(radius);
        var y: i32 = 0;
        var err: i32 = 0;
        while (x >= y) : (y += 1) {
            self.plotCirclePoints(center_x, center_y, x, y, ch);
            err += 1 + 2 * y;
            if (2 * (err - x) + 1 > 0) {
                x -= 1;
                err += 1 - 2 * x;
            }
        }
    }

    fn plotCirclePoints(self: *CanvasBuilder, cx: i32, cy: i32, x: i32, y: i32, ch: u8) void {
        self.setPixelSigned(cx + x, cy + y, ch);
        self.setPixelSigned(cx - x, cy + y, ch);
        self.setPixelSigned(cx + x, cy - y, ch);
        self.setPixelSigned(cx - x, cy - y, ch);
        self.setPixelSigned(cx + y, cy + x, ch);
        self.setPixelSigned(cx - y, cy + x, ch);
        self.setPixelSigned(cx + y, cy - x, ch);
        self.setPixelSigned(cx - y, cy - x, ch);
    }

    pub fn drawEllipse(self: *CanvasBuilder, center_x: i32, center_y: i32, radius_x: usize, radius_y: usize, ch: u8) void {
        if (radius_x == 0 and radius_y == 0) {
            self.setPixelSigned(center_x, center_y, ch);
            return;
        }
        if (radius_x == 0) {
            self.drawLine(center_x, center_y - @as(i32, @intCast(radius_y)), center_x, center_y + @as(i32, @intCast(radius_y)), ch);
            return;
        }
        if (radius_y == 0) {
            self.drawLine(center_x - @as(i32, @intCast(radius_x)), center_y, center_x + @as(i32, @intCast(radius_x)), center_y, ch);
            return;
        }

        const rx: f64 = @floatFromInt(radius_x);
        const ry: f64 = @floatFromInt(radius_y);
        const rx2 = rx * rx;
        const ry2 = ry * ry;

        var x: f64 = 0;
        var y: f64 = ry;
        var p1: f64 = ry2 - (rx2 * ry) + (0.25 * rx2);

        while (2 * ry2 * x < 2 * rx2 * y) {
            self.plotEllipsePoints(center_x, center_y, @intFromFloat(x), @intFromFloat(y), ch);
            if (p1 < 0) {
                x += 1;
                p1 += 2 * ry2 * x + ry2;
            } else {
                x += 1;
                y -= 1;
                p1 += 2 * ry2 * x - 2 * rx2 * y + ry2;
            }
        }

        var p2: f64 = ry2 * (x + 0.5) * (x + 0.5) + rx2 * (y - 1) * (y - 1) - rx2 * ry2;
        while (y >= 0) : (y -= 1) {
            self.plotEllipsePoints(center_x, center_y, @intFromFloat(x), @intFromFloat(y), ch);
            if (p2 > 0) {
                p2 += rx2 - (2 * rx2 * y);
            } else {
                x += 1;
                p2 += 2 * ry2 * x - 2 * rx2 * y + rx2;
            }
        }
    }

    fn plotEllipsePoints(self: *CanvasBuilder, cx: i32, cy: i32, x: i32, y: i32, ch: u8) void {
        self.setPixelSigned(cx + x, cy + y, ch);
        self.setPixelSigned(cx - x, cy + y, ch);
        self.setPixelSigned(cx + x, cy - y, ch);
        self.setPixelSigned(cx - x, cy - y, ch);
    }

    pub fn drawText(self: *CanvasBuilder, x: usize, y: usize, text: []const u8) void {
        if (y >= self.rows.len) return;
        var idx: usize = 0;
        while (idx < text.len and x + idx < self.width) : (idx += 1) {
            self.rows[y][x + idx] = text[idx];
        }
    }

    pub fn toCanvas(self: *CanvasBuilder) !Canvas {
        const rows_const = try self.allocator.alloc([]const u8, self.rows.len);
        for (self.rows, 0..) |row, idx| {
            rows_const[idx] = row;
        }
        self.owns_rows = false;
        return Canvas{
            .rows = rows_const,
            .width = self.width,
            .height = self.height,
            .fill_char = self.fill_char,
        };
    }

    pub fn toNode(self: *CanvasBuilder) !Node {
        return Node{ .canvas = try self.toCanvas() };
    }

    pub fn deinit(self: *CanvasBuilder) void {
        if (!self.owns_rows) return;
        for (self.rows) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.rows);
        self.owns_rows = false;
    }
};

fn absDiff(a: i32, b: i32) i32 {
    return if (a >= b) a - b else b - a;
}

pub const Table = struct {
    headers: []const []const u8 = &[_][]const u8{},
    rows: []const []const []const u8 = &[_][]const []const u8{},
    selected_row: ?usize = null,
    selected_column: ?usize = null,
    zebra: bool = false,
    border: bool = true,

    const Bounds = struct {
        width: usize,
        height: usize,
    };

    fn maxColumns(self: Table) usize {
        var max_cols: usize = self.headers.len;
        for (self.rows) |row| {
            if (row.len > max_cols) max_cols = row.len;
        }
        return max_cols;
    }

    fn rowVisualWidth(cells: []const []const u8) usize {
        if (cells.len == 0) return 1;
        var width: usize = 1; // leading border
        for (cells) |cell| {
            width += cell.len + 3; // space + content + border
        }
        return width;
    }

    pub fn bounds(self: Table) Bounds {
        var max_width: usize = 1;
        if (self.headers.len > 0) {
            const header_width = Table.rowVisualWidth(self.headers);
            if (header_width > max_width) max_width = header_width;
        }
        for (self.rows) |row| {
            const rw = Table.rowVisualWidth(row);
            if (rw > max_width) max_width = rw;
        }
        const base_height: usize = 2; // top + bottom
        const header_height: usize = if (self.headers.len > 0) 2 else 0; // header + separator
        const body_height: usize = self.rows.len;
        return .{
            .width = max_width,
            .height = base_height + header_height + body_height,
        };
    }

    fn columnWidths(self: Table, allocator: std.mem.Allocator) ![]usize {
        const cols = self.maxColumns();
        const widths = try allocator.alloc(usize, cols);
        @memset(widths, 1);
        for (self.headers, 0..) |cell, idx| {
            widths[idx] = @max(widths[idx], cell.len);
        }
        for (self.rows) |row| {
            for (row, 0..) |cell, idx| {
                widths[idx] = @max(widths[idx], cell.len);
            }
        }
        return widths;
    }

    fn writeHorizontalRule(ctx: *RenderContext, widths: []const usize) !void {
        try ctxWrite(ctx, "+");
        for (widths) |w| {
            var i: usize = 0;
            while (i < w + 2) : (i += 1) try ctxWrite(ctx, "-");
            try ctxWrite(ctx, "+");
        }
        try ctxWrite(ctx, "\n");
    }

    fn writeRow(ctx: *RenderContext, widths: []const usize, cells: []const []const u8, selected_col: ?usize, highlight: bool, zebra: bool) !void {
        try ctxWrite(ctx, "|");
        for (widths, 0..) |w, idx| {
            try ctxWrite(ctx, " ");
            var used: usize = 0;
            if (highlight and idx == 0) {
                try ctxWrite(ctx, ">");
                used += 1;
            } else if (zebra and idx == 0) {
                try ctxWrite(ctx, "~");
                used += 1;
            }
            if (idx < cells.len) {
                const cell = cells[idx];
                if (selected_col) |sc| {
                    if (sc == idx) {
                        try ctxWrite(ctx, "[");
                        used += 1;
                        try ctxWrite(ctx, cell);
                        used += cell.len;
                        try ctxWrite(ctx, "]");
                        used += 1;
                    } else {
                        try ctxWrite(ctx, cell);
                        used += cell.len;
                    }
                } else {
                    try ctxWrite(ctx, cell);
                    used += cell.len;
                }
            }
            if (used < w) {
                var padding = w - used;
                while (padding > 0) : (padding -= 1) try ctxWrite(ctx, " ");
            }
            try ctxWrite(ctx, " |");
        }
        try ctxWrite(ctx, "\n");
    }

    pub fn render(self: Table, ctx: *RenderContext) anyerror!void {
        var arena_storage: ?std.heap.ArenaAllocator = null;
        const allocator = blk: {
            if (ctx.allocator) |alloc| break :blk alloc;
            arena_storage = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            break :blk arena_storage.?.allocator();
        };
        defer if (arena_storage) |*arena| arena.deinit();

        const widths = try self.columnWidths(allocator);
        defer allocator.free(widths);

        try Table.writeHorizontalRule(ctx, widths);
        if (self.headers.len > 0) {
            try Table.writeRow(ctx, widths, self.headers, null, false, false);
            try Table.writeHorizontalRule(ctx, widths);
        }
        if (self.rows.len == 0) {
            try ctxWrite(ctx, "| (empty) |\n");
        } else {
            for (self.rows, 0..) |row, row_idx| {
                const highlight = if (self.selected_row) |sr| sr == row_idx else false;
                const selected_col = if (highlight) self.selected_column else null;
                const zebra = self.zebra and (row_idx % 2 == 1);
                try Table.writeRow(ctx, widths, row, selected_col, highlight, zebra);
            }
        }
        try Table.writeHorizontalRule(ctx, widths);
    }
};

pub const Automerge = struct {
    children: []const Node = &[_]Node{},

    const Dimensions = struct {
        width: usize,
        height: usize,
    };

    pub fn dimensions(self: Automerge) Dimensions {
        var width: usize = 0;
        var height: usize = 0;
        for (self.children) |child| {
            const req = child.computeRequirement();
            if (req.min_width > width) width = req.min_width;
            height += req.min_height;
        }
        return .{ .width = width, .height = height };
    }

    pub fn render(self: Automerge, ctx: *RenderContext) anyerror!void {
        if (ctx.drawer != null) {
            for (self.children) |child| try child.render(ctx);
            return;
        }
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        var buffer = std.ArrayListUnmanaged(u8){};
        defer buffer.deinit(arena.allocator());

        for (self.children) |child| {
            switch (child) {
                .text => |text_node| {
                    try buffer.appendSlice(arena.allocator(), text_node.content);
                },
                else => {
                    if (buffer.items.len > 0) {
                        try ctxWrite(ctx, buffer.items);
                        buffer.clearRetainingCapacity();
                    }
                    try child.render(ctx);
                },
            }
        }
        if (buffer.items.len > 0) {
            try ctxWrite(ctx, buffer.items);
        }
    }
};

pub const ScrollDecorator = struct {
    child: ?*const Node = null,
    indicator: ScrollIndicator = .{},
    top_symbol: []const u8 = "↑",
    bottom_symbol: []const u8 = "↓",

    pub fn render(self: ScrollDecorator, ctx: *RenderContext) anyerror!void {
        if (self.indicator.top) {
            try ctxWrite(ctx, self.top_symbol);
            try ctxWrite(ctx, "\n");
        }
        if (self.child) |child| {
            try child.*.render(ctx);
        }
        if (self.indicator.bottom) {
            try ctxWrite(ctx, "\n");
            try ctxWrite(ctx, self.bottom_symbol);
        }
    }
};

pub const Center = struct {
    child: *const Node,
    width: usize = 0,

    pub fn render(self: Center, ctx: *RenderContext) anyerror!void {
        const req = self.child.*.computeRequirement();
        const span = if (self.width > 0) self.width else req.min_width;
        const padding = if (span > req.min_width) (span - req.min_width) / 2 else 0;
        if (ctx.drawer != null) {
            var child_ctx = ctx.*;
            child_ctx.origin_x += @as(i32, @intCast(padding));
            try self.child.*.render(&child_ctx);
            return;
        }
        var i: usize = 0;
        while (i < padding) : (i += 1) try ctxWrite(ctx, " ");
        try self.child.*.render(ctx);
        var j: usize = 0;
        while (j < padding) : (j += 1) try ctxWrite(ctx, " ");
    }
};

pub const StyleDecorator = struct {
    child: *const Node,
    attrs: StyleAttributes = .{},
};

fn renderParagraph(p: Paragraph, ctx: *RenderContext) !void {
    const width: usize = if (p.width == 0) 1 else p.width;
    if (ctx.drawer != null) {
        var row: usize = 0;
        var idx: usize = 0;
        while (idx < p.content.len) : (row += 1) {
            const remaining = p.content.len - idx;
            const take = @min(width, remaining);
            try ctxDraw(ctx, ctx.origin_x, ctx.origin_y + @as(i32, @intCast(row)), p.content[idx .. idx + take]);
            if (take < width) {
                var col: usize = take;
                while (col < width) : (col += 1) try ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(col)), ctx.origin_y + @as(i32, @intCast(row)), " ");
            }
            idx += take;
        }
        if (p.content.len == 0) {
            var col: usize = 0;
            while (col < width) : (col += 1) try ctxDraw(ctx, ctx.origin_x + @as(i32, @intCast(col)), ctx.origin_y, " ");
        }
        return;
    }

    var idx: usize = 0;
    var row_count: usize = 0;
    while (idx < p.content.len) : (row_count += 1) {
        const remaining = p.content.len - idx;
        const take = @min(width, remaining);
        try ctxWrite(ctx, p.content[idx .. idx + take]);
        if (take < width) {
            var pad: usize = width - take;
            while (pad > 0) : (pad -= 1) try ctxWrite(ctx, " ");
        }
        try ctxWrite(ctx, "\n");
        idx += take;
    }

    if (p.content.len == 0) {
        var pad: usize = 0;
        while (pad < width) : (pad += 1) try ctxWrite(ctx, " ");
        try ctxWrite(ctx, "\n");
    }
}

fn renderStyledChild(s: StyleDecorator, ctx: *RenderContext) !void {
    const saved = ctx.style;
    const merged = mergeStyles(ctx.style, s.attrs);
    ctx.style = merged;
    if (ctx.drawer == null) try applyAnsiStyle(ctx, merged);
    try s.child.*.render(ctx);
    ctx.style = saved;
    if (ctx.drawer == null) try applyAnsiStyle(ctx, saved);
}

fn renderFrameNode(f: Frame, ctx: *RenderContext) !void {
    if (ctx.drawer != null) {
        try frame_mod.renderFrame(f, ctx);
        return;
    }

    const charset = f.charset();
    const child_req = f.child.*.computeRequirement();
    const inner_width = child_req.min_width;
    const inner_height = child_req.min_height;

    // Render child content into a temporary buffer to preserve styling.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var buffer = std.array_list.Managed(u8).init(arena.allocator());
    defer buffer.deinit();
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };
    var child_ctx = RenderContext{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&buffer)), .writeAll = SinkWriter.write },
        .allocator = arena.allocator(),
        .style = ctx.style,
    };
    try f.child.*.render(&child_ctx);

    // Top border
    try ctxWrite(ctx, charset.top_left);
    var col: usize = 0;
    while (col < inner_width) : (col += 1) try ctxWrite(ctx, charset.horizontal);
    try ctxWrite(ctx, charset.top_right);
    try ctxWrite(ctx, "\n");

    // Body
    var line_start: usize = 0;
    var row: usize = 0;
    while (row < inner_height) : (row += 1) {
        var line_end = line_start;
        while (line_end < buffer.items.len and buffer.items[line_end] != '\n') : (line_end += 1) {}
        const line = buffer.items[line_start..line_end];
        line_start = if (line_end < buffer.items.len) line_end + 1 else buffer.items.len;

        try ctxWrite(ctx, charset.vertical);
        try ctxWrite(ctx, line);
        if (line.len < inner_width) {
            var padding = inner_width - line.len;
            while (padding > 0) : (padding -= 1) try ctxWrite(ctx, " ");
        }
        try ctxWrite(ctx, charset.vertical);
        try ctxWrite(ctx, "\n");
    }

    // Bottom border
    try ctxWrite(ctx, charset.bottom_left);
    col = 0;
    while (col < inner_width) : (col += 1) try ctxWrite(ctx, charset.horizontal);
    try ctxWrite(ctx, charset.bottom_right);
    try ctxWrite(ctx, "\n");
    try ctxWrite(ctx, "\x1b[0m");
}

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

test "vertical gauge requirement swaps width/height expectations" {
    const g = Node{ .gauge = .{ .fraction = 0.25, .width = 6, .orientation = .vertical } };
    const req = g.computeRequirement();
    try std.testing.expectEqual(@as(usize, 3), req.min_width);
    try std.testing.expectEqual(@as(usize, 6), req.min_height);
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

test "canvas builder draws diagonal line" {
    var builder = try CanvasBuilder.init(std.testing.allocator, 4, 4, '.');
    defer builder.deinit();
    builder.drawLine(0, 0, 3, 3, '#');
    const canvas = try builder.toCanvas();
    defer {
        for (canvas.rows) |row| std.testing.allocator.free(@constCast(row));
        std.testing.allocator.free(canvas.rows);
        std.testing.allocator.free(builder.rows);
    }
    try std.testing.expectEqualStrings("#...", canvas.rows[0]);
    try std.testing.expectEqualStrings(".#..", canvas.rows[1]);
    try std.testing.expectEqualStrings("..#.", canvas.rows[2]);
    try std.testing.expectEqualStrings("...#", canvas.rows[3]);
}

test "canvas builder draws ellipse outline" {
    var builder = try CanvasBuilder.init(std.testing.allocator, 9, 7, ' ');
    defer builder.deinit();
    builder.drawEllipse(4, 3, 3, 2, '*');
    const canvas = try builder.toCanvas();
    defer {
        for (canvas.rows) |row| std.testing.allocator.free(@constCast(row));
        std.testing.allocator.free(canvas.rows);
        std.testing.allocator.free(builder.rows);
    }
    try std.testing.expectEqual('*', canvas.rows[1][4]);
    try std.testing.expectEqual('*', canvas.rows[3][1]);
    try std.testing.expectEqual('*', canvas.rows[3][7]);
    try std.testing.expectEqual('*', canvas.rows[5][4]);
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

test "canvas animation requirement tracks active frame" {
    const frame_a = Canvas{ .rows = &[_][]const u8{"aa"} };
    const frame_b = Canvas{ .rows = &[_][]const u8{ "long", "row" } };
    const n = Node{ .canvas_animation = .{ .frames = &[_]Canvas{ frame_a, frame_b }, .index = 1 } };
    const req = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), req.min_width);
    try std.testing.expectEqual(@as(usize, 2), req.min_height);
}

test "canvas animation advances through frames" {
    var managed = std.array_list.Managed(u8).init(std.testing.allocator);
    defer managed.deinit();
    const Adapter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const buf = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try buf.appendSlice(data);
        }
    };

    const frame_a = Canvas{ .rows = &[_][]const u8{"A"} };
    const frame_b = Canvas{ .rows = &[_][]const u8{"B"} };
    var node_anim = Node{ .canvas_animation = .{ .frames = &[_]Canvas{ frame_a, frame_b } } };
    var ctx = RenderContext{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&managed)), .writeAll = Adapter.write },
    };

    try node_anim.render(&ctx);
    try std.testing.expect(std.mem.indexOf(u8, managed.items, "A") != null);
    managed.items.len = 0;
    switch (node_anim) {
        .canvas_animation => |*anim| anim.advance(),
        else => unreachable,
    }
    try node_anim.render(&ctx);
    try std.testing.expect(std.mem.indexOf(u8, managed.items, "B") != null);
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
        .config = .{ .direction = .row, .gap = 1 },
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
        .config = .{ .direction = .column, .gap = 2 },
        .children = &[_]Node{
            .{ .text = .{ .content = "ab" } },
            .{ .text = .{ .content = "tool" } },
        },
    } };
    const r = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 4), r.min_width);
    try std.testing.expectEqual(@as(usize, 4), r.min_height); // 1 + 2 + 1
}

test "flexbox config constraints clamp requirement" {
    const n = Node{ .flexbox = .{
        .config = .{
            .direction = .row,
            .main_constraint = .{ .at_least = 10 },
            .cross_constraint = .{ .at_most = 1 },
        },
        .children = &[_]Node{
            .{ .text = .{ .content = "abcd" } },
        },
    } };
    const r = n.computeRequirement();
    try std.testing.expectEqual(@as(usize, 10), r.min_width);
    try std.testing.expectEqual(@as(usize, 1), r.min_height);
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
        .config = .{ .direction = .row, .gap = 1 },
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
