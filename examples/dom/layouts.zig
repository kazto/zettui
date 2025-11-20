const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    var screen = try zettui.screen.Screen.init(gpa, 72, 18);
    defer gpa.free(screen.image.pixels);

    screen.clear(.{ .glyph = " ", .fg = 0xFFFFFF, .bg = 0x000000 });

    const Drawer = struct {
        fn draw(user_data: *anyopaque, x: i32, y: i32, text: []const u8, style: zettui.dom.StyleAttributes) anyerror!void {
            if (x < 0 or y < 0) return;
            const scr = @as(*zettui.screen.Screen, @ptrCast(@alignCast(user_data)));
            const cell = zettui.dom.styleToCellStyle(style, 0xFFFFFF, 0x000000);
            scr.drawStyledString(@intCast(@as(usize, @intCast(x))), @intCast(@as(usize, @intCast(y))), text, cell);
        }
    };

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    var ctx: zettui.dom.RenderContext = .{
        .sink = null,
        .drawer = .{ .user_data = @as(*anyopaque, @ptrCast(&screen)), .drawText = Drawer.draw },
        .allocator = a,
    };

    try buildDashboard(&ctx, a);

    var stdout = std.fs.File.stdout();
    try screen.present(stdout);

    try stdout.writeAll("\nGridbox + flows + tree demos:\n");
    try renderGridAndFlows(&stdout, a);

    try stdout.writeAll("\nFocus + cursor decorators:\n");
    try showcaseFocusAndCursor(&screen, &stdout, a, Drawer.draw);
}

fn buildDashboard(ctx: *zettui.dom.RenderContext, allocator: std.mem.Allocator) !void {
    const metrics_label = try zettui.dom.elements.styleOwned(
        allocator,
        zettui.dom.elements.text("Metrics"),
        .{ .bold = true, .fg = 0xEAB308 },
    );
    const gauges = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        zettui.dom.elements.gaugeStyled(0.72, .{ .label = "CPU", .show_percentage = true, .width = 18 }),
        zettui.dom.elements.gaugeStyled(0.43, .{ .label = "GPU", .show_percentage = true, .width = 18, .fill = '#', .empty = '.' }),
    }, 2);
    const sparkline_values = [_]f32{ 0.2, 0.4, 0.35, 0.6, 0.9, 0.75, 0.5, 0.65, 0.8, 0.55 };
    const sparkline = zettui.dom.elements.graphWidth(&sparkline_values, 32, 6);
    const ascii_art_rows = [_][]const u8{
        " /\\  ",
        "/__\\ ",
        "|  | ",
        "|__| ",
    };
    const ascii_panel = zettui.dom.elements.canvasSized(&ascii_art_rows, 8, 4);

    const row_top = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        metrics_label,
        gauges,
    }, 1);

    const row_mid = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        try zettui.dom.elements.styleOwned(allocator, sparkline, .{ .fg = 0x22D3EE }),
        zettui.dom.elements.separator(.vertical),
        try zettui.dom.elements.styleOwned(allocator, ascii_panel, .{ .fg = 0xF97316 }),
    }, 2);

    const footer = zettui.dom.elements.hbox(&[_]zettui.dom.Node{
        try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text("Ready"), .{ .fg = 0x34D399 }),
        zettui.dom.elements.filler(1),
        try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text("Press Q to quit"), .{ .fg = 0xF472B6 }),
    });

    const tree = zettui.dom.elements.vbox(&[_]zettui.dom.Node{ row_top, row_mid, footer });
    try tree.render(ctx);
}

fn renderGridAndFlows(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    var ctx = makeSinkContext(stdout, allocator);

    try stdout.writeAll("-- Gridbox --\n");
    const grid_rows = [_][]const zettui.dom.Node{
        &[_]zettui.dom.Node{ zettui.dom.elements.text("A1"), zettui.dom.elements.text("A2"), zettui.dom.elements.text("A3") },
        &[_]zettui.dom.Node{ zettui.dom.elements.text("B1"), zettui.dom.elements.text("B2"), zettui.dom.elements.text("B3") },
        &[_]zettui.dom.Node{ zettui.dom.elements.text("C1"), zettui.dom.elements.text("C2"), zettui.dom.elements.text("C3") },
    };
    const grid = try zettui.dom.elements.gridboxOwned(allocator, &grid_rows, .{ .border = true, .column_gap = 3 });
    try grid.render(&ctx);
    try stdout.writeAll("\n");

    try stdout.writeAll("-- hflow --\n");
    const flow_items = [_]zettui.dom.Node{
        zettui.dom.elements.text("alpha"),
        zettui.dom.elements.text("beta"),
        zettui.dom.elements.text("gamma"),
        zettui.dom.elements.text("delta"),
        zettui.dom.elements.text("epsilon"),
        zettui.dom.elements.text("zeta"),
    };
    const hflow = try zettui.dom.elements.hflowOwned(allocator, &flow_items, .{ .wrap = 20, .gap = 2 });
    try hflow.render(&ctx);

    try stdout.writeAll("-- vflow --\n");
    const vflow = try zettui.dom.elements.vflowOwned(allocator, &flow_items, .{ .wrap = 3, .gap = 2 });
    try vflow.render(&ctx);

    try stdout.writeAll("-- html_like tree (package manager) --\n");
    const doc = zettui.dom.elements.HtmlNode{
        .tag = "div",
        .children = &[_]zettui.dom.elements.HtmlNode{
            .{ .tag = "h1", .text = "Package Manager" },
            .{
                .tag = "ul",
                .children = &[_]zettui.dom.elements.HtmlNode{
                    .{ .tag = "li", .text = "ftxui (installed)" },
                    .{ .tag = "li", .text = "zettui (up to date)" },
                    .{ .tag = "li", .text = "demo (pending)" },
                },
            },
        },
    };
    const html_like = try zettui.dom.elements.htmlLikeOwned(allocator, doc);
    try html_like.render(&ctx);
    try stdout.writeAll("\n");
}

fn showcaseFocusAndCursor(
    screen: *zettui.screen.Screen,
    stdout: *std.fs.File,
    allocator: std.mem.Allocator,
    comptime drawFn: fn (*anyopaque, i32, i32, []const u8, zettui.dom.StyleAttributes) anyerror!void,
) !void {
    screen.clear(.{ .glyph = " ", .fg = 0xFFFFFF, .bg = 0x000000 });
    const editable = zettui.dom.elements.text("Edit me");
    const focused = try zettui.dom.elements.focusOwned(allocator, editable, .center);
    var cursor_node = try zettui.dom.elements.cursorOwned(allocator, focused, 4);

    var ctx: zettui.dom.RenderContext = .{
        .sink = null,
        .drawer = .{ .user_data = @as(*anyopaque, @ptrCast(screen)), .drawText = drawFn },
        .allocator = allocator,
        .origin_x = 2,
        .origin_y = 1,
    };
    try cursor_node.render(&ctx);

    var selection: zettui.dom.Selection = .{};
    var tmp = cursor_node;
    tmp.select(&selection);
    const caret_x: usize = @intCast(ctx.origin_x + @as(i32, @intCast(selection.cursor_index)));
    const caret_y: usize = @intCast(ctx.origin_y + 1);
    screen.drawString(caret_x, caret_y, "^");
    try screen.present(stdout);
}

fn makeSinkContext(stdout: *std.fs.File, allocator: std.mem.Allocator) zettui.dom.RenderContext {
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
