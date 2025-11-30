const std = @import("std");
const common = @import("common.zig");

pub const SeparatorStyle = enum {
    plain,
    dashed,
    double,
    dotted,
    heavy,
};

pub const Separator = struct {
    orientation: common.Orientation = .horizontal,
    style: SeparatorStyle = .plain,
    length: usize = 0,

    pub fn requirement(self: Separator) common.Requirement {
        const span = if (self.length > 0) self.length else 1;
        return switch (self.orientation) {
            .horizontal => common.Requirement{ .min_width = span, .min_height = 1 },
            .vertical => common.Requirement{ .min_width = 1, .min_height = span },
        };
    }

    pub fn render(self: Separator, ctx: *common.RenderContext) !void {
        const glyphs = separatorGlyphs(self.style);
        const span = if (self.length > 0) self.length else 1;
        switch (self.orientation) {
            .horizontal => {
                var written: usize = 0;
                while (written < span) {
                    const remaining = span - written;
                    const chunk = if (glyphs.horizontal.len <= remaining) glyphs.horizontal else glyphs.horizontal[0..remaining];
                    try common.ctxWrite(ctx, chunk);
                    written += chunk.len;
                }
                try common.ctxWrite(ctx, "\n");
            },
            .vertical => {
                var i: usize = 0;
                while (i < span) : (i += 1) {
                    try common.ctxWrite(ctx, glyphs.vertical);
                    try common.ctxWrite(ctx, "\n");
                }
            },
        }
    }
};

const SeparatorGlyphs = struct {
    horizontal: []const u8,
    vertical: []const u8,
};

fn separatorGlyphs(style: SeparatorStyle) SeparatorGlyphs {
    return switch (style) {
        .plain => .{ .horizontal = "\xE2\x94\x80", .vertical = "\xE2\x94\x82" },
        .dashed => .{ .horizontal = "- ", .vertical = "|" },
        .double => .{ .horizontal = "\xE2\x95\x90", .vertical = "\xE2\x95\x91" },
        .dotted => .{ .horizontal = ". ", .vertical = ":" },
        .heavy => .{ .horizontal = "\xE2\x94\x81", .vertical = "\xE2\x94\x83" },
    };
}
