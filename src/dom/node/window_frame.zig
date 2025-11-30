const common = @import("common.zig");

pub const WindowFrame = struct {
    title: []const u8 = "",

    pub fn requirement(self: WindowFrame) common.Requirement {
        return .{ .min_width = 2 + self.title.len, .min_height = 1 };
    }
};
