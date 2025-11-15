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

pub fn window(title: []const u8) node.Node {
    return .{ .window = .{ .title = title } };
}

pub fn gauge(fraction: f32) node.Node {
    return .{ .gauge = .{ .fraction = fraction, .width = 10 } };
}

pub fn gaugeWidth(fraction: f32, width: usize) node.Node {
    return .{ .gauge = .{ .fraction = fraction, .width = width } };
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

pub fn framePtr(child: *const node.Node) node.Node {
    return .{ .frame = .{ .child = child } };
}

pub fn frameOwned(allocator: std.mem.Allocator, child: node.Node) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return .{ .frame = .{ .child = ptr } };
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
