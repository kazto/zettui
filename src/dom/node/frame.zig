const std = @import("std");
const common = @import("common.zig");

pub const FrameBorderStyle = enum {
    single,
    double,
    rounded,
    heavy,
    ascii,
};

const FrameCharset = struct {
    top_left: []const u8,
    top_right: []const u8,
    bottom_left: []const u8,
    bottom_right: []const u8,
    horizontal: []const u8,
    vertical: []const u8,
};

fn frameCharset(style: FrameBorderStyle) FrameCharset {
    return switch (style) {
        .single => .{
            .top_left = "\xE2\x94\x8C", // ┌
            .top_right = "\xE2\x94\x90", // ┐
            .bottom_left = "\xE2\x94\x94", // └
            .bottom_right = "\xE2\x94\x98", // ┘
            .horizontal = "\xE2\x94\x80", // ─
            .vertical = "\xE2\x94\x82", // │
        },
        .double => .{
            .top_left = "\xE2\x95\x94", // "╔"
            .top_right = "\xE2\x95\x97", // "╗"
            .bottom_left = "\xE2\x95\x9A", // "╚"
            .bottom_right = "\xE2\x95\x9D", // "╝"
            .horizontal = "\xE2\x95\x90", // "═"
            .vertical = "\xE2\x95\x91", // "║"
        },
        .rounded => .{
            .top_left = "\xE2\x94\x8D", // ┍
            .top_right = "\xE2\x94\x91", // ┑
            .bottom_left = "\xE2\x94\x95", // ┕
            .bottom_right = "\xE2\x94\x99", // ┙
            .horizontal = "\xE2\x94\x80", // ─
            .vertical = "\xE2\x94\x82", // │
        },
        .heavy => .{
            .top_left = "\xE2\x94\x8F", // ┏
            .top_right = "\xE2\x94\x93", // ┓
            .bottom_left = "\xE2\x94\x97", // ┗
            .bottom_right = "\xE2\x94\x9B", // ┛
            .horizontal = "\xE2\x94\x81", // ━
            .vertical = "\xE2\x94\x83", // ┃
        },
        .ascii => .{
            .top_left = "+",
            .top_right = "+",
            .bottom_left = "+",
            .bottom_right = "+",
            .horizontal = "-",
            .vertical = "|",
        },
    };
}

pub const FrameBorder = struct {
    charset: FrameBorderStyle = .single,
    fg: ?u24 = null,
    fg_palette: ?common.PaletteColor = null,
};

pub fn Frame(comptime Node: type) type {
    return struct {
        child: *const Node,
        border: FrameBorder = .{},

        pub fn requirement(self: @This()) common.Requirement {
            const child_req = self.child.*.computeRequirement();
            return .{ .min_width = child_req.min_width + 2, .min_height = child_req.min_height + 2 };
        }

        pub fn charset(self: @This()) FrameCharset {
            return frameCharset(self.border.charset);
        }
    };
}

pub fn renderFrame(self: anytype, ctx: *common.RenderContext) !void {
    const charset = frameCharset(self.border.charset);
    const child_req = self.child.*.computeRequirement();
    const width: i32 = @intCast(child_req.min_width);
    const height: i32 = @intCast(child_req.min_height);

    try common.frameWrite(ctx, ctx.origin_x, ctx.origin_y, charset.top_left);
    var top: i32 = 0;
    while (top < width) : (top += 1) try common.frameWrite(ctx, ctx.origin_x + 1 + top, ctx.origin_y, charset.horizontal);
    try common.frameWrite(ctx, ctx.origin_x + 1 + width, ctx.origin_y, charset.top_right);

    var row: i32 = 0;
    while (row < height) : (row += 1) {
        try common.frameWrite(ctx, ctx.origin_x, ctx.origin_y + 1 + row, charset.vertical);
        try common.frameWrite(ctx, ctx.origin_x + 1 + width, ctx.origin_y + 1 + row, charset.vertical);
    }

    try common.frameWrite(ctx, ctx.origin_x, ctx.origin_y + 1 + height, charset.bottom_left);
    var bottom: i32 = 0;
    while (bottom < width) : (bottom += 1) try common.frameWrite(ctx, ctx.origin_x + 1 + bottom, ctx.origin_y + 1 + height, charset.horizontal);
    try common.frameWrite(ctx, ctx.origin_x + 1 + width, ctx.origin_y + 1 + height, charset.bottom_right);

    var child_ctx = ctx.*;
    child_ctx.origin_x += 1;
    child_ctx.origin_y += 1;
    try self.child.*.render(&child_ctx);
}
