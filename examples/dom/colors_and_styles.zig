const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll("=== DOM Typography, Styles, and Colors ===\n\n");

    var ctx = makeContext(&stdout_file, a);
    try renderTypography(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderColors(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderGradients(&ctx, &stdout_file);
}

fn renderTypography(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Typography --\n");
    const samples = [_]struct {
        label: []const u8,
        attrs: zettui.dom.StyleAttributes,
    }{
        .{ .label = "Bold emphasis", .attrs = .{ .bold = true } },
        .{ .label = "Italic emphasis", .attrs = .{ .italic = true } },
        .{ .label = "Single underline", .attrs = .{ .underline = true } },
        .{ .label = "Double underline", .attrs = .{ .underline_double = true } },
        .{ .label = "Strike through", .attrs = .{ .strikethrough = true } },
        .{ .label = "Blinking text", .attrs = .{ .blink = true } },
        .{ .label = "Dim accent", .attrs = .{ .dim = true } },
        .{ .label = "Inverse highlight", .attrs = .{ .inverse = true } },
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
    try stdout.writeAll("-- Palette / True color --\n");
    const palette_samples = [_]struct {
        label: []const u8,
        attrs: zettui.dom.StyleAttributes,
    }{
        .{ .label = "Palette: bright red", .attrs = .{ .fg_palette = .bright_red } },
        .{ .label = "Palette: bright cyan", .attrs = .{ .fg_palette = .bright_cyan } },
        .{ .label = "Palette background", .attrs = .{ .bg_palette = .bright_black, .fg_palette = .bright_white } },
        .{ .label = "True color lavender", .attrs = .{ .fg = 0xA855F7 } },
        .{ .label = "True color sunset on charcoal", .attrs = .{ .fg = 0xF97316, .bg = 0x1F2933 } },
    };
    for (palette_samples) |sample| {
        const node = try zettui.dom.elements.styleOwned(
            allocator,
            zettui.dom.elements.text(sample.label),
            sample.attrs,
        );
        try node.render(ctx);
        try stdout.writeAll("\n");
    }

    try stdout.writeAll("\n-- Paragraph with underline --\n");
    const paragraph_node = try zettui.dom.elements.styleOwned(
        allocator,
        zettui.dom.elements.paragraph(
            "Paragraph nodes wrap text to the requested width and inherit typography styles. Use this to showcase underline and other decorations.",
            48,
        ),
        .{ .underline = true },
    );
    try paragraph_node.render(ctx);
    try stdout.writeAll("\n");
}

fn renderGradients(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Linear gradients --\n");
    const gradient = zettui.dom.elements.linearGradient("Linear gradient sample", 0xF97316, 0x7C3AED);
    try gradient.render(ctx);
    try stdout.writeAll("\n");
}

fn makeContext(stdout: *std.fs.File, allocator: std.mem.Allocator) zettui.dom.RenderContext {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    return .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write },
        .allocator = allocator,
    };
}
