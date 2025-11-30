const common = @import("common.zig");

pub const Filler = struct {
    grow: f32 = 1,
    shrink: f32 = 1,

    pub fn requirement(self: Filler) common.Requirement {
        return .{ .min_width = 0, .min_height = 0, .flex_grow = self.grow, .flex_shrink = self.shrink };
    }
};
