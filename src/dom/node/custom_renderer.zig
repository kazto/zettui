const common = @import("common.zig");

pub const CustomRenderer = struct {
    callback: *const fn (user_data: ?*anyopaque, ctx: *common.RenderContext) anyerror!void,
    user_data: ?*anyopaque = null,
};
