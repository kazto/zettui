const Canvas = @import("canvas.zig").Canvas;
const common = @import("common.zig");

pub const CanvasAnimation = struct {
    frames: []const Canvas = &[_]Canvas{},
    index: usize = 0,

    pub fn current(self: CanvasAnimation) Canvas {
        if (self.frames.len == 0) return Canvas{};
        const pos = self.index % self.frames.len;
        return self.frames[pos];
    }

    pub fn advance(self: *CanvasAnimation) void {
        if (self.frames.len == 0) return;
        self.index = (self.index + 1) % self.frames.len;
    }

    pub fn requirement(self: CanvasAnimation) common.Requirement {
        const dims = self.current().dimensions();
        return .{ .min_width = dims.width, .min_height = dims.height };
    }
};
