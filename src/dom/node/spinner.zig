const common = @import("common.zig");

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

    pub fn requirement(self: Spinner) common.Requirement {
        return .{ .min_width = self.currentFrame().len, .min_height = 1 };
    }
};
