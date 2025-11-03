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

pub const Selection = struct {
    has_focus: bool = false,
    cursor_index: usize = 0,
};

pub const RenderContext = struct {
    allow_hyperlinks: bool = false,
};

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

    pub fn computeRequirement(self: Node) Requirement {
        return switch (self) {
            .text => |text_node| Requirement{
                .min_width = text_node.content.len,
                .min_height = 1,
            },
            .container => |container_node| container_node.computeRequirement(),
            else => Requirement{},
        };
    }

    pub fn setBox(self: *Node, box: Box) void {
        switch (self.*) {
            .container => |*container_node| container_node.box = box,
            else => {},
        }
    }

    pub fn check(self: Node) void {
        switch (self) {
            .container => |container_node| container_node.check(),
            else => {},
        }
    }

    pub fn render(self: Node, ctx: *RenderContext) !void {
        switch (self) {
            .text => |text_node| {
                try std.io.getStdOut().writeAll(text_node.content);
            },
            .custom => |renderer| try renderer.callback(renderer.user_data, ctx),
            .container => |container_node| try container_node.render(ctx),
            else => {},
        }
    }

    pub fn select(self: *Node, selection: *Selection) void {
        switch (self.*) {
            .container => |*container_node| container_node.select(selection),
            else => selection.* = .{},
        }
    }

    pub fn getSelectedContent(self: Node, allocator: std.mem.Allocator) ![]const u8 {
        _ = allocator;
        return switch (self) {
            .text => |text_node| text_node.content,
            else => "",
        };
    }
};

pub const Text = struct {
    content: []const u8,
};

pub const CustomRenderer = struct {
    callback: fn (user_data: ?*anyopaque, ctx: *RenderContext) anyerror!void,
    user_data: ?*anyopaque = null,
};

pub const Container = struct {
    children: []const Node = &[_]Node{},
    box: Box = .{},

    pub fn computeRequirement(self: Container) Requirement {
        var req = Requirement{};
        for (self.children) |child| {
            const child_req = child.computeRequirement();
            req.min_width = std.math.max(req.min_width, child_req.min_width);
            req.min_height += child_req.min_height;
        }
        return req;
    }

    pub fn render(self: Container, ctx: *RenderContext) !void {
        for (self.children) |child| {
            try child.render(ctx);
        }
    }

    pub fn select(self: *Container, selection: *Selection) void {
        for (self.children) |*child| {
            child.select(selection);
        }
    }

    pub fn check(self: Container) void {
        for (self.children) |child| {
            child.check();
        }
    }
};
