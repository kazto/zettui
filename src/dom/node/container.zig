const std = @import("std");
const common = @import("common.zig");

pub fn Container(comptime Node: type) type {
    return struct {
        children: []const Node = &[_]Node{},
        box: common.Box = .{},
        orientation: common.Orientation = .vertical,
        owned_children: ?[]Node = null,

        pub fn computeRequirement(self: @This()) common.Requirement {
            var req = common.Requirement{};
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

        pub fn render(self: @This(), ctx: *common.RenderContext) anyerror!void {
            const kids = if (self.owned_children) |oc| oc else self.children;
            for (kids) |child| try child.render(ctx);
        }

        pub fn layout(self: @This(), allocator: std.mem.Allocator) ![]common.Box {
            const boxes = try allocator.alloc(common.Box, self.children.len);
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

        pub fn applyLayout(self: *@This(), allocator: std.mem.Allocator) !void {
            const boxes = try self.layout(allocator);
            const owned = try allocator.dupe(Node, self.children);
            for (owned, 0..) |*child, i| {
                child.setBox(boxes[i]);
            }
            self.owned_children = owned;
        }

        pub fn select(self: *@This(), selection: *common.Selection) void {
            const kids = if (self.owned_children) |oc| oc else self.children;
            selection.setAccessibility(.container, "Container", "", "", "");
            for (kids) |child| {
                var tmp = child;
                var child_selection = common.Selection.init();
                tmp.select(&child_selection);
                if (child_selection.has_focus) {
                    selection.* = child_selection;
                    break;
                }
            }
        }

        pub fn check(self: @This()) void {
            const kids = if (self.owned_children) |oc| oc else self.children;
            for (kids) |child| child.check();
        }
    };
}
