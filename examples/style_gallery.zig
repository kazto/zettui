const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout_file = std.fs.File.stdout();
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(data);
        }
    };

    var ctx: zettui.dom.RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&stdout_file)), .writeAll = SinkWriter.write },
        .allocator = a,
    };

    try stdout_file.writeAll("Zettui style & color gallery\n\n");
    try renderTypography(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderColors(&ctx, &stdout_file, a);
}

fn renderTypography(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("== Typography ==\n");
    const samples = [_]struct {
        label: []const u8,
        attrs: zettui.dom.StyleAttributes,
    }{
        .{ .label = "Bold / Strong", .attrs = .{ .bold = true } },
        .{ .label = "Italic emphasis", .attrs = .{ .italic = true } },
        .{ .label = "Single underline", .attrs = .{ .underline = true } },
        .{ .label = "Double underline", .attrs = .{ .underline_double = true } },
        .{ .label = "Strike through", .attrs = .{ .strikethrough = true } },
        .{ .label = "Blink cursor sample", .attrs = .{ .blink = true } },
        .{ .label = "Dim accent", .attrs = .{ .dim = true } },
        .{ .label = "Inverse focus block", .attrs = .{ .inverse = true } },
    };

    for (samples) |sample| {
        const node = try zettui.dom.elements.styleOwned(
            allocator,
            zettui.dom.elements.text(sample.label),
            sample.attrs,
        );
        try node.render(ctx);
        try stdout.writeAll("\n");
    }
}

fn renderColors(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("== Colors ==\n");
    const samples = [_]struct {
        label: []const u8,
        fg: ?u24 = null,
        fg_palette: ?zettui.dom.PaletteColor = null,
        bg: ?u24 = null,
        bg_palette: ?zettui.dom.PaletteColor = null,
        underline: bool = false,
    }{
        .{ .label = "Crimson (palette)", .fg_palette = .bright_red },
        .{ .label = "Emerald", .fg = 0x50C878 },
        .{ .label = "Azure", .fg = 0x007FFF },
        .{ .label = "Sunset on charcoal", .fg = 0xF97316, .bg = 0x1F2933 },
        .{ .label = "Neon on midnight", .fg = 0xE0FF4F, .bg = 0x0F172A },
        .{ .label = "Lavender underline", .fg = 0xA855F7, .underline = true },
    };

    for (samples) |sample| {
        const attrs = zettui.dom.StyleAttributes{
            .fg = sample.fg,
            .bg = sample.bg,
            .fg_palette = sample.fg_palette,
            .bg_palette = sample.bg_palette,
            .underline = sample.underline,
        };
        const node = try zettui.dom.elements.styleOwned(
            allocator,
            zettui.dom.elements.text(sample.label),
            attrs,
        );
        try node.render(ctx);
        try stdout.writeAll("\n");
    }
}
