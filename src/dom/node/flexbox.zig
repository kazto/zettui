const std = @import("std");
const common = @import("common.zig");

pub const FlexDirection = enum { row, column };

pub const FlexboxConfig = struct {
    direction: FlexDirection = .row,
    gap: usize = 0,
    main_axis: common.Axis = .horizontal,
    main_constraint: common.Constraint = .none,
    cross_constraint: common.Constraint = .none,

    pub fn normalized(self: FlexboxConfig) FlexboxConfig {
        var cfg = self;
        cfg.main_axis = switch (cfg.direction) {
            .row => .horizontal,
            .column => .vertical,
        };
        return cfg;
    }

    pub fn clampSize(self: FlexboxConfig, width: usize, height: usize) struct { width: usize, height: usize } {
        var out_w = width;
        var out_h = height;
        switch (self.main_axis) {
            .horizontal => {
                out_w = self.main_constraint.clamp(out_w);
                out_h = self.cross_constraint.clamp(out_h);
            },
            .vertical => {
                out_h = self.main_constraint.clamp(out_h);
                out_w = self.cross_constraint.clamp(out_w);
            },
        }
        return .{ .width = out_w, .height = out_h };
    }
};

pub fn Flexbox(comptime Node: type) type {
    return struct {
        children: []const Node = &[_]Node{},
        config: FlexboxConfig = .{},
        box: common.Box = .{},
        owned_children: ?[]Node = null,

        pub fn requirement(self: @This()) common.Requirement {
            var req = common.Requirement{};
            const cfg = self.config.normalized();
            const count = self.children.len;
            const gap_total: usize = if (count > 0) cfg.gap * (count - 1) else 0;
            switch (cfg.direction) {
                .row => {
                    req.min_height = 0;
                    req.min_width = gap_total;
                    for (self.children) |child| {
                        const cr = child.computeRequirement();
                        req.min_width += cr.min_width;
                        req.min_height = @max(req.min_height, cr.min_height);
                    }
                },
                .column => {
                    req.min_width = 0;
                    req.min_height = gap_total;
                    for (self.children) |child| {
                        const cr = child.computeRequirement();
                        req.min_width = @max(req.min_width, cr.min_width);
                        req.min_height += cr.min_height;
                    }
                },
            }
            const clamped = cfg.clampSize(req.min_width, req.min_height);
            req.min_width = clamped.width;
            req.min_height = clamped.height;
            return req;
        }

        pub fn layout(self: @This(), allocator: std.mem.Allocator) ![]common.Box {
            const cfg = self.config.normalized();
            const limits = cfg.clampSize(@intCast(self.box.width), @intCast(self.box.height));
            const boxes = try allocator.alloc(common.Box, self.children.len);
            var x: i32 = self.box.origin_x;
            var y: i32 = self.box.origin_y;
            var i: usize = 0;
            switch (cfg.direction) {
                .row => {
                    while (i < self.children.len) : (i += 1) {
                        const cr = self.children[i].computeRequirement();
                        const width: usize = @min(cr.min_width, limits.width);
                        const height: usize = @min(cr.min_height, limits.height);
                        boxes[i] = .{
                            .origin_x = x,
                            .origin_y = y,
                            .width = @intCast(width),
                            .height = @intCast(height),
                        };
                        x += @as(i32, @intCast(width + cfg.gap));
                    }
                },
                .column => {
                    while (i < self.children.len) : (i += 1) {
                        const cr = self.children[i].computeRequirement();
                        const width: usize = @min(cr.min_width, limits.width);
                        const height: usize = @min(cr.min_height, limits.height);
                        boxes[i] = .{
                            .origin_x = x,
                            .origin_y = y,
                            .width = @intCast(width),
                            .height = @intCast(height),
                        };
                        y += @as(i32, @intCast(height + cfg.gap));
                    }
                },
            }
            return boxes;
        }

        pub fn applyLayout(self: *@This(), allocator: std.mem.Allocator) !void {
            const boxes = try self.layout(allocator);
            const owned = try allocator.dupe(Node, self.children);
            for (owned, 0..) |*child, i| child.setBox(boxes[i]);
            self.owned_children = owned;
        }
    };
}
