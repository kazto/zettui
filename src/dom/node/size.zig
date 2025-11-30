const common = @import("common.zig");

pub fn Size(comptime Node: type) type {
    return struct {
        child: *const Node,
        width: usize = 0,
        height: usize = 0,

        pub fn requirement(self: @This()) common.Requirement {
            const child_req = self.child.*.computeRequirement();
            return .{
                .min_width = @max(child_req.min_width, self.width),
                .min_height = @max(child_req.min_height, self.height),
            };
        }
    };
}
