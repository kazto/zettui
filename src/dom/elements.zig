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
    return .{ .gauge = .{ .fraction = fraction } };
}

pub fn spinner() node.Node {
    return .{ .spinner = .{} };
}
