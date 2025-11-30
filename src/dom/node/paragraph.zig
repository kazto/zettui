const common = @import("common.zig");

pub const Paragraph = struct {
    content: []const u8,
    width: usize = 40,

    pub fn requirement(self: Paragraph) common.Requirement {
        const w: usize = if (self.width == 0) 1 else self.width;
        const lines: usize = (self.content.len + w - 1) / w;
        return .{ .min_width = w, .min_height = if (lines == 0) 1 else lines };
    }
};
