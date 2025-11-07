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
    sink: ?Sink = null,
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
    frame: Frame,
    size: Size,
    filler: Filler,
    focus: Focus,
    flexbox: Flexbox,
    dbox: Dbox,

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
            .container => |container_node| container_node.computeRequirement(),
            .frame => |f| blockFrame: {
                const child_req = f.child.computeRequirement();
                break :blockFrame Requirement{
                    .min_width = child_req.min_width + 2,
                    .min_height = child_req.min_height + 2,
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
                try ctxWrite(ctx, text_node.content);
            },
            .separator => {
                try ctxWrite(ctx, "---\n");
            },
            .window => |w| {
                try ctxWrite(ctx, "[");
                try ctxWrite(ctx, w.title);
                try ctxWrite(ctx, "]");
            },
            .gauge => |g| {
                const total = if (g.width < 3) 3 else g.width;
                const inner: usize = total - 2;
                const clamped = std.math.clamp(g.fraction, 0.0, 1.0);
                const filled: usize = @intFromFloat(@floor(@as(f32, @floatFromInt(inner)) * clamped + 0.0001));
                const empty: usize = inner - filled;
                try ctxWrite(ctx, "[");
                var i: usize = 0;
                while (i < filled) : (i += 1) try ctxWrite(ctx, "#");
                i = 0;
                while (i < empty) : (i += 1) try ctxWrite(ctx, ".");
                try ctxWrite(ctx, "]");
            },
            .spinner => |s| {
                try ctxWrite(ctx, s.currentFrame());
            },
            .paragraph => |p| {
                const w: usize = if (p.width == 0) 1 else p.width;
                var i: usize = 0;
                while (i < p.content.len) : (i += 1) {
                    if (w > 0 and i > 0 and (i % w) == 0) {
                        try ctxWrite(ctx, "\n");
                    }
                    try ctxWrite(ctx, p.content[i .. i + 1]);
                }
            },
            .custom => |renderer| try @call(.auto, renderer.callback, .{ renderer.user_data, ctx }),
            .frame => |f| {
                const req = f.child.*.computeRequirement();
                const inner_w: usize = req.min_width;
                // top border: ┌───┐
                try ctxWrite(ctx, "\xE2\x94\x8C"); // ┌
                var i: usize = 0;
                while (i < inner_w) : (i += 1) try ctxWrite(ctx, "\xE2\x94\x80"); // ─
                try ctxWrite(ctx, "\xE2\x94\x90\n"); // ┐

                // middle rows: wrap known multi-line children with borders per line
                switch (f.child.*) {
                    .paragraph => |p| {
                        const w: usize = if (p.width == 0) 1 else p.width;
                        var idx: usize = 0;
                        while (idx < p.content.len) {
                            try ctxWrite(ctx, "\xE2\x94\x82"); // │
                            const rem = p.content.len - idx;
                            const take = if (rem < w) rem else w;
                            try ctxWrite(ctx, p.content[idx .. idx + take]);
                            var pad: usize = inner_w - take;
                            while (pad > 0) : (pad -= 1) try ctxWrite(ctx, " ");
                            try ctxWrite(ctx, "\xE2\x94\x82\n"); // │
                            idx += take;
                        }
                        if (p.content.len == 0) {
                            // empty content still renders one empty line inside the frame
                            try ctxWrite(ctx, "\xE2\x94\x82");
                            var j: usize = 0;
                            while (j < inner_w) : (j += 1) try ctxWrite(ctx, " ");
                            try ctxWrite(ctx, "\xE2\x94\x82\n");
                        }
                    },
                    else => {
                        // default: single row with child rendering
                        try ctxWrite(ctx, "\xE2\x94\x82"); // │
                        try f.child.*.render(ctx);
                        // pad to inner width is not attempted here; assume child fits
                        try ctxWrite(ctx, "\xE2\x94\x82\n"); // │
                    },
                }

                // bottom border: └───┘
                try ctxWrite(ctx, "\xE2\x94\x94"); // └
                i = 0;
                while (i < inner_w) : (i += 1) try ctxWrite(ctx, "\xE2\x94\x80"); // ─
                try ctxWrite(ctx, "\xE2\x94\x98\n"); // ┘
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
                for (fb.children) |child| {
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
            },
            .dbox => |db| {
                for (db.children) |child| {
                    try child.render(ctx);
                }
            },
            .container => |container_node| try container_node.render(ctx),
            else => {},
        }
    }

    pub fn select(self: *Node, selection: *Selection) void {
        switch (self.*) {
            .container => |*container_node| container_node.select(selection),
            .frame => |*f| {
                var tmp = f.child.*;
                tmp.select(selection);
            },
            .size => |*s| {
                var tmp = s.child.*;
                tmp.select(selection);
            },
            .focus => |*fx| {
                var tmp = fx.child.*;
                tmp.select(selection);
            },
            .flexbox => |*fb| {
                for (fb.children) |*child| {
                    child.select(selection);
                }
            },
            .dbox => |*db| {
                for (db.children) |*child| child.select(selection);
            },
            else => selection.* = .{},
        }
    }

    pub fn getSelectedContent(self: Node, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self) {
            .text => |text_node| text_node.content,
            .frame => |f| try f.child.*.getSelectedContent(allocator),
            .size => |s| try s.child.*.getSelectedContent(allocator),
            .focus => |fx| try fx.child.*.getSelectedContent(allocator),
            .flexbox => |fb| blkSel: {
                // Return first child's content by convention
                if (fb.children.len == 0) break :blkSel "";
                break :blkSel try fb.children[0].getSelectedContent(allocator);
            },
            .dbox => |db| blkSel2: {
                if (db.children.len == 0) break :blkSel2 "";
                break :blkSel2 try db.children[db.children.len - 1].getSelectedContent(allocator);
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

pub const Frame = struct {
    child: *const Node,
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
};

pub const Dbox = struct {
    children: []const Node = &[_]Node{},
    box: Box = .{},
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
        "\xE2\x94\x94\xE2\x94\x80\xE2\x94\x80\xE2\x94\x80\xE2\x94\x80\xE2\x94\x98\n";
    try std.testing.expectEqualStrings(expected, managed.items);
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
