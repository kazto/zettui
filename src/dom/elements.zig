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

pub fn sizePtr(child: *const node.Node, width: usize, height: usize) node.Node {
    return .{ .size = .{ .child = child, .width = width, .height = height } };
}

pub fn sizeOwned(allocator: std.mem.Allocator, child: node.Node, width: usize, height: usize) !node.Node {
    const ptr = try allocator.create(node.Node);
    ptr.* = child;
    return .{ .size = .{ .child = ptr, .width = width, .height = height } };
}
