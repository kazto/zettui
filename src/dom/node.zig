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
    separator: Separator,
    window: WindowFrame,
    gauge: Gauge,
    spinner: Spinner,

    pub fn computeRequirement(self: Node) Requirement {
        return switch (self) {
            .text => |text_node| Requirement{
                .min_width = text_node.content.len,
                .min_height = 1,
            },
            .separator => Requirement{ .min_width = 1, .min_height = 1 },
            .window => |w| Requirement{ .min_width = 2 + w.title.len, .min_height = 1 },
            .gauge => Requirement{ .min_width = 3, .min_height = 1 },
            .spinner => |s| Requirement{ .min_width = s.currentFrame().len, .min_height = 1 },
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

    pub fn render(self: Node, ctx: *RenderContext) anyerror!void {
        switch (self) {
            .text => |text_node| {
                try std.fs.File.stdout().writeAll(text_node.content);
            },
            .separator => {
                try std.fs.File.stdout().writeAll("---\n");
            },
            .window => |w| {
                try std.fs.File.stdout().writeAll("[");
                try std.fs.File.stdout().writeAll(w.title);
                try std.fs.File.stdout().writeAll("]");
            },
            .gauge => |g| {
                _ = g;
                try std.fs.File.stdout().writeAll("[ ]");
            },
            .spinner => |s| {
                try std.fs.File.stdout().writeAll(s.currentFrame());
            },
            .custom => |renderer| try @call(.auto, renderer.callback, .{ renderer.user_data, ctx }),
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
};

pub const Spinner = struct {
    frames: []const []const u8 = &[_][]const u8{ "-", "\\", "|", "/" },
    index: usize = 0,

    pub fn currentFrame(self: Spinner) []const u8 {
        if (self.frames.len == 0) return "";
        return self.frames[self.index % self.frames.len];
    }
};

pub const Container = struct {
    children: []const Node = &[_]Node{},
    box: Box = .{},
    orientation: Orientation = .vertical,

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

test "gauge has minimal width of 3" {
    const g = Node{ .gauge = .{ .fraction = 0.5 } };
    const req = g.computeRequirement();
    try std.testing.expectEqual(@as(usize, 3), req.min_width);
    try std.testing.expectEqual(@as(usize, 1), req.min_height);
}

test "spinner width equals current frame length" {
    const s = Node{ .spinner = .{} };
    const req = s.computeRequirement();
    try std.testing.expectEqual(@as(usize, 1), req.min_width);
}
