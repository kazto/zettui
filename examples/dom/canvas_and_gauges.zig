const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    var stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll("=== DOM Canvas, Graph, Gauge, and Spinner ===\n\n");

    var ctx = makeContext(&stdout_file);
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try renderGraph(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try renderGauge(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try renderCanvas(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try stdout_file.writeAll("\n");
    try renderProceduralCanvas(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try animateSpinner(&stdout_file);
}

fn renderGraph(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Graph (sparkline) --\n");
    try stdout.writeAll("-- Graph (sparkline) --\n");
    const values = [_]f32{ 1, 2, 1.5, 3.5, 2.5, 4, 3.8, 2.2, 3.6, 2.9, 3.0, 4.2, 2.1, 1.5, 2.8, 3.5, 4.0, 3.2, 2.5, 1.8 };
    var node = zettui.dom.elements.graphWidth(&values, 60, 8);
    try node.render(ctx);
    try stdout.writeAll("\n");
}

fn renderGauge(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Gauge with percentage --\n");
    const download = zettui.dom.elements.gaugeStyled(0.68, .{
        .label = "Download",
        .show_percentage = true,
        .width = 32,
        .fill = '=',
        .empty = '.',
    });
    try download.render(ctx);
    try stdout.writeAll("\n");

    try stdout.writeAll("-- Vertical gauge variant --\n");
    const vertical = zettui.dom.elements.gaugeStyled(0.42, .{
        .label = "Battery",
        .show_percentage = true,
        .width = 8,
        .orientation = .vertical,
        .fill = '#',
        .empty = '.',
    });
    try vertical.render(ctx);
    try stdout.writeAll("\n");
}

fn renderCanvas(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Canvas (ASCII art) --\n");
    const rows = [_][]const u8{
        "   *   ",
        "  ***  ",
        " ***** ",
        "*******",
        "  | |  ",
    };
    const canvas = zettui.dom.elements.canvas(&rows);
    try canvas.render(ctx);
    try stdout.writeAll("\n");
    try canvas.render(ctx);
    try stdout.writeAll("\n");
}

fn renderProceduralCanvas(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Procedural Canvas (CanvasBuilder) --\n");
    const width = 40;
    const height = 10;
    var builder = try zettui.dom.canvas.CanvasBuilder.init(allocator, width, height, ' ');
    defer builder.deinit();

    // Draw border
    builder.drawRect(.{ .x = 0, .y = 0 }, width, height, '.');

    // Draw X
    builder.drawLine(.{ .x = 1, .y = 1 }, .{ .x = 38, .y = 8 }, 'x');
    builder.drawLine(.{ .x = 1, .y = 8 }, .{ .x = 38, .y = 1 }, 'x');

    // Draw Circle in center
    builder.drawCircle(.{ .x = 20, .y = 4 }, 3, 'O');

    // Draw some text
    builder.writeText(.{ .x = 16, .y = 8 }, "ZETTUI");

    var node_val = builder.toNode();
    try node_val.render(ctx);
    try stdout.writeAll("\n");
}

fn animateSpinner(stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Spinner animation --\n");
    var node = zettui.dom.elements.spinner();
    var ctx: zettui.dom.RenderContext = .{};
    var i: usize = 0;
    while (i < 32) : (i += 1) {
        try stdout.writeAll("\r");
        try node.render(&ctx);
        try stdout.writeAll(" Loading...");
        _ = zettui.dom.elements.spinnerAdvance(&node);
        std.Thread.sleep(60 * std.time.ns_per_ms);
    }
    try stdout.writeAll("\rDone                \n");
}

fn makeContext(stdout: *std.fs.File) zettui.dom.RenderContext {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    return .{ .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write } };
}
