const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    var stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll("=== DOM Canvas, Graph, Gauge, and Spinner ===\n\n");

    var ctx = makeContext(&stdout_file);
    try renderGraph(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try renderGauge(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try renderCanvas(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try animateSpinner(&stdout_file);
}

fn renderGraph(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Graph (sparkline) --\n");
    const values = [_]f32{ 1, 2, 1.5, 3.5, 2.5, 4, 3.8, 2.2, 3.6, 2.9 };
    var node = zettui.dom.elements.graphWidth(&values, 40, 8);
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
