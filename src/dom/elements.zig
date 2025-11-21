const std = @import("std");
const node = @import("node.zig");

pub fn empty() node.Node {
    return .{ .empty = {} };
}

pub fn text(content: []const u8) node.Node {
    return .{ .text = .{ .content = content } };
}

pub fn vbox(children: []const node.Node) node.Node {
    return .{ .container = .{ .children = children, .orientation = .vertical } };
}

pub fn hbox(children: []const node.Node) node.Node {
    return .{ .container = .{ .children = children, .orientation = .horizontal } };
}

pub fn custom(
    renderer: fn (user_data: ?*anyopaque, ctx: *node.RenderContext) anyerror!void,
    user_data: ?*anyopaque,
) node.Node {
    return .{
        .custom = .{
            .callback = renderer,
            .user_data = user_data,
        },
    };
}

pub fn separator(orientation: node.Orientation) node.Node {
    return .{ .separator = .{ .orientation = orientation } };
}

pub fn separatorStyled(orientation: node.Orientation, style: node.SeparatorStyle, length: usize) node.Node {
    return .{ .separator = .{ .orientation = orientation, .style = style, .length = length } };
}

pub fn separatorHorizontal(length: usize) node.Node {
    return separatorStyled(.horizontal, .plain, length);
}

pub fn separatorVertical(length: usize) node.Node {
    return separatorStyled(.vertical, .plain, length);
}

pub fn window(title: []const u8) node.Node {
    return .{ .window = .{ .title = title } };
}

pub fn gauge(fraction: f32) node.Node {
    return .{ .gauge = .{ .fraction = fraction, .width = 10 } };
}

pub fn gaugeWidth(fraction: f32, width: usize) node.Node {
    return .{ .gauge = .{ .fraction = fraction, .width = width } };
}

pub fn gaugeVertical(fraction: f32, height: usize) node.Node {
    return .{ .gauge = .{ .fraction = fraction, .width = height, .orientation = .vertical } };
}

pub const GaugeStyle = struct {
    fill: u8 = '#',
    empty: u8 = '.',
    show_percentage: bool = false,
    label: []const u8 = "",
    orientation: node.GaugeOrientation = .horizontal,
    width: usize = 10,
};

pub fn gaugeStyled(fraction: f32, style: GaugeStyle) node.Node {
    return .{ .gauge = .{
        .fraction = fraction,
        .width = style.width,
        .orientation = style.orientation,
        .fill_char = style.fill,
        .empty_char = style.empty,
        .show_percentage = style.show_percentage,
        .label = style.label,
    } };
}

pub fn spinner() node.Node {
    return .{ .spinner = .{} };
}

pub fn spinnerAdvance(n: *node.Node) bool {
    switch (n.*) {
        .spinner => |*s| {
            s.advance();
            return true;
        },
        else => return false,
    }
}

pub fn paragraph(content: []const u8, width: usize) node.Node {
    return .{ .paragraph = .{ .content = content, .width = width } };
}

pub fn graph(values: []const f32, height: usize) node.Node {
    return .{ .graph = .{ .values = values, .height = height } };
}

pub fn graphWidth(values: []const f32, width: usize, height: usize) node.Node {
    return .{ .graph = .{ .values = values, .width = width, .height = height } };
}

pub fn canvas(rows: []const []const u8) node.Node {
    return .{ .canvas = .{ .rows = rows } };
}

pub fn canvasSized(rows: []const []const u8, width: usize, height: usize) node.Node {
    return .{ .canvas = .{ .rows = rows, .width = width, .height = height } };
}

pub fn canvasAnimation(frames: []const node.Canvas) node.Node {
    return .{ .canvas_animation = .{ .frames = frames } };
}

pub fn canvasAnimationAdvance(n: *node.Node) bool {
    switch (n.*) {
        .canvas_animation => |*anim| {
            anim.advance();
            return true;
        },
        else => return false,
    }
}

pub fn framePtr(child: *const node.Node) node.Node {
    return frameStyledPtr(child, .{});
}

pub fn frameOwned(allocator: std.mem.Allocator, child: node.Node) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return frameStyledPtr(ptr, .{});
}

pub fn frameStyledPtr(child: *const node.Node, style: node.FrameBorder) node.Node {
    return .{ .frame = .{ .child = child, .border = style } };
}

pub fn frameStyledOwned(allocator: std.mem.Allocator, child: node.Node, style: node.FrameBorder) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return frameStyledPtr(ptr, style);
}

test "frameOwned wraps child and sets requirement" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const child = text("ok");
    const framed = try frameOwned(alloc, child);
    const req = framed.computeRequirement();
    // child 2x1 -> frame 4x3
    try std.testing.expectEqual(@as(usize, 4), req.min_width);
    try std.testing.expectEqual(@as(usize, 3), req.min_height);
}

test "flex helpers configure filler grow shrink" {
    const default_node = flex();
    const default_req = default_node.computeRequirement();
    try std.testing.expectEqual(@as(f32, 1), default_req.flex_grow);
    try std.testing.expectEqual(@as(f32, 1), default_req.flex_shrink);

    const grow_node = flexGrow(4);
    const grow_req = grow_node.computeRequirement();
    try std.testing.expectEqual(@as(f32, 4), grow_req.flex_grow);

    const tuned_node = flexGrowShrink(2, 0.25);
    const tuned_req = tuned_node.computeRequirement();
    try std.testing.expectEqual(@as(f32, 2), tuned_req.flex_grow);
    try std.testing.expectEqual(@as(f32, 0.25), tuned_req.flex_shrink);
}

pub fn sizePtr(child: *const node.Node, width: usize, height: usize) node.Node {
    return .{ .size = .{ .child = child, .width = width, .height = height } };
}

pub fn sizeOwned(allocator: std.mem.Allocator, child: node.Node, width: usize, height: usize) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return .{ .size = .{ .child = ptr, .width = width, .height = height } };
}

pub fn filler(grow: f32) node.Node {
    return .{ .filler = .{ .grow = grow } };
}

pub fn flex() node.Node {
    return .{ .filler = .{} };
}

pub fn flexGrow(grow: f32) node.Node {
    return .{ .filler = .{ .grow = grow } };
}

pub fn flexGrowShrink(grow: f32, shrink: f32) node.Node {
    return .{ .filler = .{ .grow = grow, .shrink = shrink } };
}

pub fn fillerDefault() node.Node {
    return filler(1);
}

pub fn focusPtr(child: *const node.Node, pos: node.FocusPosition) node.Node {
    return .{ .focus = .{ .child = child, .position = pos } };
}

pub fn focusOwned(allocator: std.mem.Allocator, child: node.Node, pos: node.FocusPosition) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return .{ .focus = .{ .child = ptr, .position = pos } };
}

pub fn flexboxRow(children: []const node.Node, gap: usize) node.Node {
    return .{ .flexbox = .{ .children = children, .direction = .row, .gap = gap } };
}

pub fn flexboxColumn(children: []const node.Node, gap: usize) node.Node {
    return .{ .flexbox = .{ .children = children, .direction = .column, .gap = gap } };
}

pub fn dbox(children: []const node.Node) node.Node {
    return .{ .dbox = .{ .children = children } };
}

pub fn cursorPtr(child: *const node.Node, index: usize) node.Node {
    return .{ .cursor = .{ .child = child, .index = index } };
}

pub fn cursorOwned(allocator: std.mem.Allocator, child: node.Node, index: usize) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return .{ .cursor = .{ .child = ptr, .index = index } };
}

pub fn scrollIndicatorPtr(child: ?*const node.Node, indicator: node.ScrollIndicator) node.Node {
    return .{ .scroll = .{ .child = child, .indicator = indicator } };
}

pub fn scrollIndicatorOwned(allocator: std.mem.Allocator, child: ?node.Node, indicator: node.ScrollIndicator) !node.Node {
    var ptr: ?*const node.Node = null;
    if (child) |c| {
        const new_ptr = try allocator.create(node.Node);
        new_ptr.* = c;
        ptr = new_ptr;
    }
    return scrollIndicatorPtr(ptr, indicator);
}

pub fn centerPtr(child: *const node.Node, width: usize) node.Node {
    return .{ .center = .{ .child = child, .width = width } };
}

pub fn centerOwned(allocator: std.mem.Allocator, child: node.Node, width: usize) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return centerPtr(ptr, width);
}

pub fn automerge(children: []const node.Node) node.Node {
    return .{ .automerge = .{ .children = children } };
}

pub fn automergeOwned(allocator: std.mem.Allocator, children: []const node.Node) !node.Node {
    const copy = try allocator.dupe(node.Node, children);
    return .{ .automerge = .{ .children = copy } };
}

pub fn table(headers: []const []const u8, rows: []const []const []const u8) node.Node {
    return .{ .table = .{ .headers = headers, .rows = rows } };
}

pub fn tableSelectable(headers: []const []const u8, rows: []const []const []const u8, selected_row: ?usize, selected_column: ?usize) node.Node {
    return .{ .table = .{ .headers = headers, .rows = rows, .selected_row = selected_row, .selected_column = selected_column } };
}

pub fn stylePtr(child: *const node.Node, attrs: node.StyleAttributes) node.Node {
    return .{ .style = .{ .child = child, .attrs = attrs } };
}

pub fn styleOwned(allocator: std.mem.Allocator, child: node.Node, attrs: node.StyleAttributes) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return stylePtr(ptr, attrs);
}

pub fn styleBoldOwned(allocator: std.mem.Allocator, child: node.Node) !node.Node {
    return styleOwned(allocator, child, .{ .bold = true });
}

pub fn styleColorOwned(allocator: std.mem.Allocator, child: node.Node, fg: ?u24, bg: ?u24) !node.Node {
    return styleOwned(allocator, child, .{ .fg = fg, .bg = bg });
}

pub fn stylePalettePtr(child: *const node.Node, fg: ?node.PaletteColor, bg: ?node.PaletteColor) node.Node {
    return .{ .style = .{ .child = child, .attrs = .{ .fg_palette = fg, .bg_palette = bg } } };
}

pub fn stylePaletteOwned(allocator: std.mem.Allocator, child: node.Node, fg: ?node.PaletteColor, bg: ?node.PaletteColor) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return stylePalettePtr(ptr, fg, bg);
}

pub fn bold(child: *const node.Node) node.Node {
    return stylePtr(child, .{ .bold = true });
}

pub fn hyperlink(child: *const node.Node, url: []const u8) node.Node {
    return stylePtr(child, .{ .hyperlink = url });
}

pub fn linearGradient(content: []const u8, start_color: u24, end_color: u24) node.Node {
    return .{ .gradient_text = .{
        .text = content,
        .start_color = start_color,
        .end_color = end_color,
    } };
}
pub const GridBoxOptions = struct {
    border: bool = false,
    column_gap: usize = 2,
    row_gap: usize = 0,
    header_divider: bool = false,
};

pub const TableOptions = struct {
    border: bool = true,
    column_gap: usize = 1,
    row_gap: usize = 0,
    header_divider: bool = true,
};

pub const FlowOptions = struct {
    wrap: usize = 0,
    gap: usize = 1,
};

pub const HtmlAttribute = struct {
    name: []const u8,
    value: []const u8,
};

pub const HtmlNode = struct {
    tag: []const u8,
    attributes: []const HtmlAttribute = &[_]HtmlAttribute{},
    text: []const u8 = "",
    children: []const HtmlNode = &[_]HtmlNode{},
};

pub const TreeStatus = enum {
    plain,
    installing,
    success,
    failure,
};

pub const TreeEntry = struct {
    label: []const u8,
    status: TreeStatus = .plain,
    children: []const TreeEntry = &[_]TreeEntry{},
};

const GridCell = struct {
    text: []u8,
    width: usize,
    height: usize,
};

fn renderNodeToOwnedString(allocator: std.mem.Allocator, value: node.Node) ![]u8 {
    var buffer = std.array_list.Managed(u8).init(allocator);
    errdefer buffer.deinit();

    const Sink = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            var list = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
            try list.appendSlice(data);
        }
    };

    var ctx = node.RenderContext{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&buffer)), .writeAll = Sink.write },
        .allocator = allocator,
    };
    try value.render(&ctx);
    const out = try buffer.toOwnedSlice();
    buffer.deinit();
    return out;
}

fn measureText(content: []const u8) struct { width: usize, height: usize } {
    var line_width: usize = 0;
    var max_width: usize = 0;
    var lines: usize = 1;
    for (content) |ch| {
        if (ch == '\n') {
            max_width = @max(max_width, line_width);
            line_width = 0;
            lines += 1;
        } else {
            line_width += 1;
        }
    }
    max_width = @max(max_width, line_width);
    return .{ .width = max_width, .height = if (content.len == 0) 1 else lines };
}

fn sliceLine(content: []const u8, target: usize) []const u8 {
    var start: usize = 0;
    var line: usize = 0;
    while (start <= content.len) : (line += 1) {
        if (line == target) {
            var end = start;
            while (end < content.len and content[end] != '\n') : (end += 1) {}
            return content[start..end];
        }
        var idx = start;
        while (idx < content.len and content[idx] != '\n') : (idx += 1) {}
        if (idx >= content.len) break;
        start = idx + 1;
    }
    return "";
}

fn repeatChar(builder: *std.array_list.Managed(u8), ch: u8, count: usize) !void {
    var i: usize = 0;
    while (i < count) : (i += 1) try builder.append(ch);
}

fn drawBorderLine(builder: *std.array_list.Managed(u8), column_widths: []const usize) !void {
    try builder.append('+');
    for (column_widths, 0..) |width, idx| {
        try repeatChar(builder, '-', width + 2);
        try builder.append(if (idx + 1 == column_widths.len) '+' else '+');
    }
    try builder.append('\n');
}

fn trimTrailing(content: []const u8) []const u8 {
    var end = content.len;
    while (end > 0 and content[end - 1] == '\n') : (end -= 1) {}
    return content[0..end];
}

fn captureRow(
    allocator: std.mem.Allocator,
    nodes: []const node.Node,
    column_count: usize,
    column_widths: []usize,
) ![]GridCell {
    const cells = try allocator.alloc(GridCell, nodes.len);
    errdefer {
        for (cells) |cell| allocator.free(cell.text);
        allocator.free(cells);
    }

    for (nodes, 0..) |child, idx| {
        const rendered = try renderNodeToOwnedString(allocator, child);
        const dims = measureText(rendered);
        cells[idx] = .{ .text = rendered, .width = dims.width, .height = dims.height };
        column_widths[idx] = @max(column_widths[idx], dims.width);
    }

    if (nodes.len < column_count) {
        var idx = nodes.len;
        while (idx < column_count) : (idx += 1) {
            column_widths[idx] = @max(column_widths[idx], 1);
        }
    }

    return cells;
}

fn formatGrid(
    allocator: std.mem.Allocator,
    headers: ?[]const node.Node,
    rows: []const []const node.Node,
    options: GridBoxOptions,
) ![]u8 {
    var column_count: usize = 0;
    if (headers) |hdrs| column_count = @max(column_count, hdrs.len);
    for (rows) |row| {
        column_count = @max(column_count, row.len);
    }
    if (column_count == 0) {
        return try allocator.dupe(u8, "");
    }

    var header_rows: usize = 0;
    if (headers != null) header_rows = 1;
    const row_count = rows.len + header_rows;
    const column_widths = try allocator.alloc(usize, column_count);
    defer allocator.free(column_widths);
    @memset(column_widths, 0);

    const row_heights = try allocator.alloc(usize, row_count);
    defer allocator.free(row_heights);

    var all_rows = try allocator.alloc([]GridCell, row_count);
    errdefer allocator.free(all_rows);
    var captured_rows: usize = 0;
    errdefer {
        var idx: usize = 0;
        while (idx < captured_rows) : (idx += 1) {
            for (all_rows[idx]) |cell| allocator.free(cell.text);
            allocator.free(all_rows[idx]);
        }
    }

    var row_index: usize = 0;
    if (headers) |hdrs| {
        const cells = try captureRow(allocator, hdrs, column_count, column_widths);
        all_rows[row_index] = cells;
        row_heights[row_index] = 1;
        for (cells) |cell| row_heights[row_index] = @max(row_heights[row_index], cell.height);
        captured_rows += 1;
        row_index += 1;
    }

    for (rows) |row| {
        const cells = try captureRow(allocator, row, column_count, column_widths);
        all_rows[row_index] = cells;
        row_heights[row_index] = 1;
        for (cells) |cell| row_heights[row_index] = @max(row_heights[row_index], cell.height);
        captured_rows += 1;
        row_index += 1;
    }

    var builder = std.array_list.Managed(u8).init(allocator);
    errdefer builder.deinit();

    if (options.border) try drawBorderLine(&builder, column_widths);

    const header_row_count = header_rows;
    for (all_rows, 0..) |cells, idx| {
        const height = row_heights[idx];
        var line: usize = 0;
        while (line < height) : (line += 1) {
            if (options.border) try builder.append('|');
            for (column_widths, 0..) |width, col_idx| {
                if (options.border) try builder.append(' ');
                const cell_line = if (col_idx < cells.len) sliceLine(cells[col_idx].text, line) else "";
                try builder.appendSlice(cell_line);
                const pad = width - cell_line.len;
                if (pad > 0) try repeatChar(&builder, ' ', pad);
                if (options.border) {
                    try builder.append(' ');
                    try builder.append('|');
                } else if (col_idx + 1 < column_count) {
                    try repeatChar(&builder, ' ', options.column_gap);
                }
            }
            try builder.append('\n');
        }

        const last_row = idx + 1 == all_rows.len;
        if (!last_row and options.row_gap > 0) {
            var gap_count: usize = 0;
            while (gap_count < options.row_gap) : (gap_count += 1) try builder.append('\n');
        }

        if (options.border and (!last_row and (options.header_divider and idx + 1 == header_row_count))) {
            try drawBorderLine(&builder, column_widths);
        } else if (!options.border and options.header_divider and idx + 1 == header_row_count) {
            var width_total: usize = 0;
            for (column_widths, 0..) |width, cidx| {
                width_total += width;
                if (cidx + 1 < column_widths.len) width_total += options.column_gap;
            }
            try repeatChar(&builder, '-', width_total);
            try builder.append('\n');
        }
    }

    if (options.border) try drawBorderLine(&builder, column_widths);

    const out = try builder.toOwnedSlice();
    builder.deinit();

    for (all_rows[0..captured_rows]) |cells| {
        for (cells) |cell| allocator.free(cell.text);
        allocator.free(cells);
    }
    allocator.free(all_rows);

    return out;
}

pub fn gridboxOwned(
    allocator: std.mem.Allocator,
    rows: []const []const node.Node,
    options: GridBoxOptions,
) !node.Node {
    const rendered = try formatGrid(allocator, null, rows, options);
    return .{ .text = .{ .content = rendered } };
}

pub fn tableOwned(
    allocator: std.mem.Allocator,
    headers: []const node.Node,
    rows: []const []const node.Node,
    options: TableOptions,
) !node.Node {
    const rendered = try formatGrid(allocator, headers, rows, .{
        .border = options.border,
        .column_gap = options.column_gap,
        .row_gap = options.row_gap,
        .header_divider = options.header_divider,
    });
    return .{ .text = .{ .content = rendered } };
}

pub fn hflowOwned(
    allocator: std.mem.Allocator,
    items: []const node.Node,
    options: FlowOptions,
) !node.Node {
    var builder = std.array_list.Managed(u8).init(allocator);
    errdefer builder.deinit();

    var current_width: usize = 0;
    for (items, 0..) |item, idx| {
        const rendered = try renderNodeToOwnedString(allocator, item);
        defer allocator.free(rendered);
        const trimmed = trimTrailing(rendered);
        const width = trimmed.len;
        if (width == 0) continue;
        var add_gap = current_width != 0;
        const needed = if (current_width == 0) width else current_width + options.gap + width;
        if (options.wrap > 0 and needed > options.wrap and current_width != 0) {
            try builder.append('\n');
            current_width = 0;
            add_gap = false;
        }
        if (add_gap and idx != 0) {
            try repeatChar(&builder, ' ', options.gap);
            current_width += options.gap;
        }
        try builder.appendSlice(trimmed);
        current_width += width;
    }
    try builder.append('\n');
    const out = try builder.toOwnedSlice();
    builder.deinit();
    return .{ .text = .{ .content = out } };
}

pub fn vflowOwned(
    allocator: std.mem.Allocator,
    items: []const node.Node,
    options: FlowOptions,
) !node.Node {
    if (items.len == 0) return text("");
    const rows_per_col = if (options.wrap == 0) items.len else options.wrap;
    const column_count = (items.len + rows_per_col - 1) / rows_per_col;
    var rendered_items = try allocator.alloc(GridCell, items.len);
    errdefer {
        for (rendered_items) |cell| allocator.free(cell.text);
        allocator.free(rendered_items);
    }
    for (items, 0..) |item, idx| {
        const rendered = try renderNodeToOwnedString(allocator, item);
        const trimmed = trimTrailing(rendered);
        rendered_items[idx] = .{ .text = rendered, .width = trimmed.len, .height = 1 };
    }

    var column_widths = try allocator.alloc(usize, column_count);
    defer allocator.free(column_widths);
    @memset(column_widths, 0);
    for (rendered_items, 0..) |cell, idx| {
        const column = idx / rows_per_col;
        column_widths[column] = @max(column_widths[column], cell.width);
    }

    var builder = std.array_list.Managed(u8).init(allocator);
    errdefer builder.deinit();

    var row: usize = 0;
    while (row < rows_per_col) : (row += 1) {
        var wrote_any = false;
        for (column_widths, 0..) |width, col_idx| {
            const idx = col_idx * rows_per_col + row;
            if (idx >= rendered_items.len) continue;
            if (wrote_any) try repeatChar(&builder, ' ', options.gap);
            const trimmed = trimTrailing(rendered_items[idx].text);
            try builder.appendSlice(trimmed);
            const pad = if (width > trimmed.len) width - trimmed.len else 0;
            if (pad > 0) try repeatChar(&builder, ' ', pad);
            wrote_any = true;
        }
        if (wrote_any) try builder.append('\n');
    }

    const out = try builder.toOwnedSlice();
    builder.deinit();

    for (rendered_items) |cell| allocator.free(cell.text);
    allocator.free(rendered_items);

    return .{ .text = .{ .content = out } };
}

fn renderHtmlNode(builder: *std.array_list.Managed(u8), element: HtmlNode, depth: usize, indent: usize) !void {
    try repeatChar(builder, ' ', depth * indent);
    try builder.appendSlice("<");
    try builder.appendSlice(element.tag);
    for (element.attributes) |attr| {
        try builder.append(' ');
        try builder.appendSlice(attr.name);
        try builder.appendSlice("=\"");
        try builder.appendSlice(attr.value);
        try builder.appendSlice("\"");
    }
    if (element.text.len == 0 and element.children.len == 0) {
        try builder.appendSlice(" />\n");
        return;
    }
    try builder.appendSlice(">");
    if (element.text.len > 0) {
        try builder.appendSlice(element.text);
    }
    if (element.children.len > 0) {
        try builder.append('\n');
        for (element.children) |child| {
            try renderHtmlNode(builder, child, depth + 1, indent);
        }
        try repeatChar(builder, ' ', depth * indent);
    }
    try builder.appendSlice("</");
    try builder.appendSlice(element.tag);
    try builder.appendSlice(">\n");
}

pub fn htmlLikeOwned(allocator: std.mem.Allocator, root: HtmlNode) !node.Node {
    var builder = std.array_list.Managed(u8).init(allocator);
    errdefer builder.deinit();
    try renderHtmlNode(&builder, root, 0, 2);
    const out = try builder.toOwnedSlice();
    builder.deinit();
    return .{ .text = .{ .content = out } };
}

fn treeStatusPrefix(status: TreeStatus) []const u8 {
    return switch (status) {
        .plain => "",
        .installing => "[~] ",
        .success => "[+] ",
        .failure => "[!] ",
    };
}

fn renderTreeEntry(
    builder: *std.array_list.Managed(u8),
    entry: TreeEntry,
    prefix_flags: *std.array_list.Managed(bool),
    is_last: bool,
) !void {
    for (prefix_flags.items) |flag| {
        if (flag) {
            try builder.appendSlice("│  ");
        } else {
            try builder.appendSlice("   ");
        }
    }
    try builder.appendSlice(if (is_last) "└─ " else "├─ ");
    try builder.appendSlice(treeStatusPrefix(entry.status));
    try builder.appendSlice(entry.label);
    try builder.append('\n');

    if (entry.children.len == 0) return;
    try prefix_flags.append(!is_last);
    for (entry.children, 0..) |child, idx| {
        const child_last = idx + 1 == entry.children.len;
        try renderTreeEntry(builder, child, prefix_flags, child_last);
    }
    _ = prefix_flags.pop();
}

pub fn treeOwned(allocator: std.mem.Allocator, roots: []const TreeEntry) !node.Node {
    var builder = std.array_list.Managed(u8).init(allocator);
    errdefer builder.deinit();
    var prefix = std.array_list.Managed(bool).init(allocator);
    defer prefix.deinit();
    for (roots, 0..) |entry, idx| {
        const is_last = idx + 1 == roots.len;
        try renderTreeEntry(&builder, entry, &prefix, is_last);
    }
    const out = try builder.toOwnedSlice();
    builder.deinit();
    return .{ .text = .{ .content = out } };
}

pub const CanvasBuilder = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    fill_char: u8 = ' ',
    data: []u8,

    fn absDiff(a: i32, b: i32) i32 {
        const diff = a - b;
        return if (diff >= 0) diff else -diff;
    }

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !CanvasBuilder {
        const buffer = try allocator.alloc(u8, width * height);
        @memset(buffer, ' ');
        return .{ .allocator = allocator, .width = width, .height = height, .data = buffer };
    }

    pub fn deinit(self: *CanvasBuilder) void {
        self.allocator.free(self.data);
    }

    fn inBounds(self: CanvasBuilder, x: usize, y: usize) bool {
        return x < self.width and y < self.height;
    }

    fn index(self: CanvasBuilder, x: usize, y: usize) usize {
        return y * self.width + x;
    }

    pub fn fill(self: *CanvasBuilder, ch: u8) void {
        @memset(self.data, ch);
    }

    pub fn setPoint(self: *CanvasBuilder, x: usize, y: usize, ch: u8) void {
        if (!self.inBounds(x, y)) return;
        self.data[self.index(x, y)] = ch;
    }

    pub fn drawLine(self: *CanvasBuilder, start_x: i32, start_y: i32, end_x: i32, end_y: i32, ch: u8) void {
        var x0 = start_x;
        var y0 = start_y;
        const dx = absDiff(end_x, start_x);
        const sx: i32 = if (x0 < end_x) 1 else -1;
        const dy = absDiff(end_y, start_y);
        const sy: i32 = if (y0 < end_y) 1 else -1;
        var err = dx - dy;
        while (true) {
            if (x0 >= 0 and y0 >= 0) self.setPoint(@intCast(x0), @intCast(y0), ch);
            if (x0 == end_x and y0 == end_y) break;
            const e2 = err * 2;
            if (e2 > -dy) {
                err -= dy;
                x0 += sx;
            }
            if (e2 < dx) {
                err += dx;
                y0 += sy;
            }
        }
    }

    pub fn writeText(self: *CanvasBuilder, x: usize, y: usize, content: []const u8) void {
        if (y >= self.height) return;
        var col = x;
        for (content) |ch| {
            if (col >= self.width) break;
            self.setPoint(col, y, ch);
            col += 1;
        }
    }

    pub fn toNode(self: *CanvasBuilder) !node.Node {
        const rows = try self.allocator.alloc([]const u8, self.height);
        errdefer self.allocator.free(rows);
        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            const start = y * self.width;
            rows[y] = try self.allocator.dupe(u8, self.data[start .. start + self.width]);
        }
        return .{ .canvas = .{ .rows = rows, .width = self.width, .height = self.height } };
    }
};

test "gridboxOwned renders bordered grid" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const rows = [_][]const node.Node{
        &[_]node.Node{ text("pkg"), text("1.0") },
        &[_]node.Node{ text("core"), text("2.0") },
    };
    const grid = try gridboxOwned(arena.allocator(), &rows, .{ .border = true });
    const content = switch (grid) {
        .text => |t| t.content,
        else => unreachable,
    };
    const expected =
        "+------+-----+\n" ++
        "| pkg  | 1.0 |\n" ++
        "| core | 2.0 |\n" ++
        "+------+-----+\n";
    try std.testing.expectEqualStrings(expected, content);
}

test "tableOwned inserts header divider" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const headers = [_]node.Node{ text("name"), text("version") };
    const rows = [_][]const node.Node{
        &[_]node.Node{ text("pkg"), text("1.0") },
    };
    const tbl = try tableOwned(arena.allocator(), &headers, &rows, .{});
    const content = switch (tbl) {
        .text => |t| t.content,
        else => unreachable,
    };
    const expected =
        "+------+---------+\n" ++
        "| name | version |\n" ++
        "+------+---------+\n" ++
        "| pkg  | 1.0     |\n" ++
        "+------+---------+\n";
    try std.testing.expectEqualStrings(expected, content);
}

test "hflowOwned wraps at configured width" {
    const items = [_]node.Node{ text("alpha"), text("beta"), text("gamma") };
    const flow = try hflowOwned(std.testing.allocator, &items, .{ .wrap = 10, .gap = 1 });
    const content = switch (flow) {
        .text => |t| t.content,
        else => unreachable,
    };
    defer std.testing.allocator.free(@constCast(content));
    try std.testing.expectEqualStrings("alpha beta\ngamma\n", content);
}

test "vflowOwned groups items into columns" {
    const items = [_]node.Node{ text("A"), text("B"), text("C") };
    const flow = try vflowOwned(std.testing.allocator, &items, .{ .wrap = 2, .gap = 2 });
    const content = switch (flow) {
        .text => |t| t.content,
        else => unreachable,
    };
    const expected =
        "A  C\n" ++
        "B\n";
    defer std.testing.allocator.free(@constCast(content));
    try std.testing.expectEqualStrings(expected, content);
}

test "htmlLikeOwned renders nested markup" {
    const tree = HtmlNode{
        .tag = "div",
        .attributes = &[_]HtmlAttribute{.{ .name = "class", .value = "root" }},
        .children = &[_]HtmlNode{
            .{ .tag = "p", .text = "Hello" },
        },
    };
    const doc = try htmlLikeOwned(std.testing.allocator, tree);
    const content = switch (doc) {
        .text => |t| t.content,
        else => unreachable,
    };
    defer std.testing.allocator.free(@constCast(content));
    try std.testing.expect(std.mem.indexOf(u8, content, "<div") != null);
    try std.testing.expect(std.mem.indexOf(u8, content, "Hello") != null);
}

test "treeOwned draws guide characters" {
    const entries = [_]TreeEntry{
        .{ .label = "pkg", .children = &[_]TreeEntry{.{ .label = "bin" }} },
        .{ .label = "docs", .status = .success },
    };
    const tree_node = try treeOwned(std.testing.allocator, &entries);
    const content = switch (tree_node) {
        .text => |t| t.content,
        else => unreachable,
    };
    defer std.testing.allocator.free(@constCast(content));
    try std.testing.expect(std.mem.indexOf(u8, content, "└─ bin") != null);
    try std.testing.expect(std.mem.indexOf(u8, content, "[+]") != null);
}

test "CanvasBuilder draws lines and exports canvas" {
    var builder = try CanvasBuilder.init(std.testing.allocator, 4, 3);
    defer builder.deinit();
    builder.fill('.');
    builder.drawLine(0, 0, 3, 2, '#');
    builder.writeText(0, 1, "HI");
    const canvas_node = try builder.toNode();
    const rendered = switch (canvas_node) {
        .canvas => |c| c,
        else => unreachable,
    };
    const dims = rendered.dimensions();
    try std.testing.expectEqual(@as(usize, 4), dims.width);
    try std.testing.expectEqual(@as(usize, 3), dims.height);
    const rows_mut = @constCast(rendered.rows);
    for (rows_mut) |row| std.testing.allocator.free(@constCast(row));
    std.testing.allocator.free(rows_mut);
}

test "canvasAnimationAdvance cycles frames" {
    const frame_a = node.Canvas{ .rows = &[_][]const u8{"A"} };
    const frame_b = node.Canvas{ .rows = &[_][]const u8{"B"} };
    var anim = canvasAnimation(&[_]node.Canvas{ frame_a, frame_b });
    try std.testing.expect(canvasAnimationAdvance(&anim));
}
