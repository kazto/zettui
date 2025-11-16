const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== FTXUI Component + DOM Gallery ===\n\n");

    try stdout.writeAll("-- Buttons --\n");
    try renderButtons(&stdout, a);
    try stdout.writeAll("\n-- Menu --\n");
    try renderMenu(a);
    try stdout.writeAll("\n-- Graph & Gauge --\n");
    try renderGraphAndGauge(&stdout);
    try stdout.writeAll("\n-- Table --\n");
    try renderTable(a, &stdout);
}

fn renderButtons(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    const primary = try zettui.component.widgets.button(allocator, .{ .label = "Primary", .visual = .primary });
    const success = try zettui.component.widgets.buttonAnimated(allocator, "Animated", .{
        .start_color = 0x34D399,
        .end_color = 0x10B981,
        .duration_ms = 300,
    });
    const framed = try zettui.component.widgets.buttonInFrame(allocator, "Framed", .{ .title = "FTXUI" });
    try primary.render();
    try stdout.writeAll("\n");
    try success.render();
    try stdout.writeAll("\n");
    try framed.render();
    try stdout.writeAll("\n");
}

fn renderMenu(allocator: std.mem.Allocator) !void {
    const labels = [_][]const u8{ "Home", "Graphs", "Tables", "Settings" };
    const menu_component = try zettui.component.widgets.menu(allocator, .{
        .items = &labels,
        .selected_index = 1,
        .underline_gallery = true,
        .highlight_color = 0xF97316,
    });
    try menu_component.render();
}

fn renderGraphAndGauge(stdout: *std.fs.File) !void {
    const values = [_]f32{ 1, 2, 1.5, 3.5, 2.5, 4, 3.8, 2.2 };
    var ctx = makeRenderContext(stdout);
    var graph_node = zettui.dom.elements.graphWidth(&values, 40, 8);
    try graph_node.render(&ctx);
    try stdout.writeAll("\n");

    const gauge_node = zettui.dom.elements.gaugeStyled(0.68, .{
        .label = "Download",
        .show_percentage = true,
        .width = 30,
        .fill = '=',
        .empty = '.',
    });
    try gauge_node.render(&ctx);
    try stdout.writeAll("\n");
}

fn renderTable(allocator: std.mem.Allocator, stdout: *std.fs.File) !void {
    const headers = [_]zettui.dom.Node{
        zettui.dom.elements.text("Name"),
        zettui.dom.elements.text("Value"),
        zettui.dom.elements.text("State"),
    };
    const row_a = [_]zettui.dom.Node{
        zettui.dom.elements.text("Alpha"),
        zettui.dom.elements.text("42"),
        zettui.dom.elements.text("ready"),
    };
    const row_b = [_]zettui.dom.Node{
        zettui.dom.elements.text("Beta"),
        zettui.dom.elements.text("17"),
        zettui.dom.elements.text("running"),
    };
    const row_c = [_]zettui.dom.Node{
        zettui.dom.elements.text("Gamma"),
        zettui.dom.elements.text("3"),
        zettui.dom.elements.text("halted"),
    };
    const rows = [_][]const zettui.dom.Node{ &row_a, &row_b, &row_c };
    const table = try zettui.dom.elements.tableOwned(allocator, &headers, &rows, .{
        .border = true,
        .header_divider = true,
        .column_gap = 2,
    });
    var ctx = makeRenderContext(stdout);
    try table.render(&ctx);
}

fn makeRenderContext(stdout: *std.fs.File) zettui.dom.RenderContext {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    return .{ .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write } };
}
