const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll("=== DOM Borders, Separators, and Sizes ===\n\n");

    var ctx = makeContext(&stdout_file, a);
    try renderFrames(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderSeparators(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try renderSizedPanels(&ctx, &stdout_file, a);
}

fn renderFrames(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Frame styles --\n");
    const samples = [_]struct {
        label: []const u8,
        border: zettui.dom.FrameBorder,
    }{
        .{ .label = "Single border (palette cyan)", .border = .{ .fg_palette = .bright_cyan } },
        .{ .label = "Rounded border (emerald)", .border = .{ .charset = .rounded, .fg = 0x10B981 } },
        .{ .label = "Double border (magenta)", .border = .{ .charset = .double, .fg = 0xDB2777 } },
        .{ .label = "Heavy border (amber)", .border = .{ .charset = .heavy, .fg = 0xF59E0B } },
    };

    for (samples) |sample| {
        const framed = try zettui.dom.elements.frameStyledOwned(
            allocator,
            zettui.dom.elements.text(sample.label),
            sample.border,
        );
        try framed.render(ctx);
        try stdout.writeAll("\n");
    }
}

fn renderSeparators(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Separators --\n");
    try zettui.dom.elements.separatorStyled(.horizontal, .plain, 32).render(ctx);
    try stdout.writeAll("\n");
    try zettui.dom.elements.separatorStyled(.horizontal, .dashed, 32).render(ctx);
    try stdout.writeAll("\n");
    try stdout.writeAll("(vertical separator rendered via layout)\n");

    const column = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        zettui.dom.elements.text("Item A"),
        zettui.dom.elements.separator(.vertical),
        zettui.dom.elements.text("Item B"),
    }, 1);
    try column.render(ctx);
    try stdout.writeAll("\n");
}

fn renderSizedPanels(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Size-limited frames --\n");
    const content = zettui.dom.elements.paragraph(
        "This paragraph is wrapped inside a frame with explicit width/height requirements.",
        32,
    );
    const sized = try zettui.dom.elements.sizeOwned(allocator, content, 34, 5);
    const framed = try zettui.dom.elements.frameStyledOwned(allocator, sized, .{ .charset = .ascii, .fg_palette = .bright_blue });
    try framed.render(ctx);
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
