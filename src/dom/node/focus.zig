const common = @import("common.zig");

pub fn Focus(comptime Node: type) type {
    return struct {
        child: *const Node,
        position: common.FocusPosition = .center,

        pub fn requirement(self: @This()) common.Requirement {
            var req = self.child.*.computeRequirement();
            req.focus = self.position;
            return req;
        }
    };
}
