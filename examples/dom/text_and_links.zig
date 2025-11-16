const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll("=== DOM Text, Paragraphs, and pseudo-links ===\n\n");

    var ctx = makeContext(&stdout_file, a);
    try renderParagraphs(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderTextFlow(&ctx, &stdout_file, a);
}

fn renderParagraphs(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Paragraph width wrapping --\n");
    const body = zettui.dom.elements.paragraph(
        "Paragraph nodes automatically wrap text to the requested width, producing multi-line DOM nodes without manual slicing.",
        48,
    );
    try body.render(ctx);
    try stdout.writeAll("\n\n");

    const narrow = zettui.dom.elements.paragraph(
        "Narrow paragraphs demonstrate how long words flow into multiple rows.",
        24,
    );
    try narrow.render(ctx);
    try stdout.writeAll("\n");
}

fn renderTextFlow(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Links & inline emphasis --\n");
    const link = try zettui.dom.elements.styleOwned(
        allocator,
        zettui.dom.elements.text("https://github.com/kazto/zettui"),
        .{ .underline = true, .fg = 0x3B82F6 },
    );
    const emphasis = try zettui.dom.elements.styleOwned(
        allocator,
        zettui.dom.elements.text("emphasis"),
        .{ .bold = true },
    );

    const row = zettui.dom.elements.hbox(&[_]zettui.dom.Node{
        zettui.dom.elements.text("Docs:"),
        zettui.dom.elements.separator(.vertical),
        link,
    });
    try row.render(ctx);
    try stdout.writeAll("\n");

    const flow = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        zettui.dom.elements.text("Inline"),
        emphasis,
        zettui.dom.elements.text("can be mixed using hbox/flexbox."),
    }, 1);
    try flow.render(ctx);
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
