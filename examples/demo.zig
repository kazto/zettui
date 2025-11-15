const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var screen = try zettui.screen.Screen.init(allocator, 64, 12);
    defer allocator.free(screen.image.pixels);

    const stdout = std.fs.File.stdout();
    try renderScreenShowcase(&screen, stdout);

    try stdout.writeAll("\nDOM dashboard:\n");
    try renderDomDashboard(stdout, allocator);

    try stdout.writeAll("\nComponent buttons:\n");
    try renderButtonGallery(stdout, allocator);
}

fn renderScreenShowcase(screen: *zettui.screen.Screen, stdout: std.fs.File) !void {
    screen.clear(.{
        .glyph = " ",
        .fg = 0xE0E0E0,
        .bg = 0x101010,
    });

    drawHorizontalLine(screen, 0, "=");
    drawHorizontalLine(screen, screen.image.height - 1, "=");

    const accent = zettui.screen.CellStyle{ .fg = 0xF97316 };
    const accent2 = zettui.screen.CellStyle{ .fg = 0xA855F7 };
    screen.drawStyledString(2, 1, "Zettui showcase", accent);
    screen.drawStyledString(2, 3, "Screen + DOM + Components", .{ .fg = 0x7DD3FC });
    screen.drawStyledString(2, 5, "Inspired by the FTXUI gallery", accent2);
    screen.drawStyledString(2, 7, "Build rich terminal UIs from Zig", .{ .fg = 0x22D3EE });

    try screen.present(stdout);
}

fn drawHorizontalLine(screen: *zettui.screen.Screen, y: usize, glyph: []const u8) void {
    var col: usize = 0;
    while (col < screen.image.width) : (col += 1) {
        screen.drawString(col, y, glyph);
    }
}

fn renderDomDashboard(stdout: std.fs.File, allocator: std.mem.Allocator) !void {
    var ctx: zettui.dom.RenderContext = .{};
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const metrics = [_]f32{ 0.2, 0.45, 0.35, 0.65, 0.9, 0.75, 0.55, 0.6, 0.78, 0.5, 0.62, 0.7 };
    const sparkline = zettui.dom.elements.graphWidth(&metrics, 28, 6);
    const badge_rows = [_][]const u8{
        " /‾‾‾\\ ",
        "/ zet \\",
        "| tui |",
        "\\_____/ ",
    };
    const badge = zettui.dom.elements.canvasSized(&badge_rows, 12, 4);
    const framed_badge = try zettui.dom.elements.frameOwned(a, badge);

    const highlight_label = try zettui.dom.elements.styleOwned(a, zettui.dom.elements.paragraph("Release readiness", 20), .{ .bold = true, .fg = 0xF97316 });
    const stats = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        highlight_label,
        zettui.dom.elements.gaugeWidth(0.82, 16),
        zettui.dom.elements.spinner(),
    }, 2);

    const sparkline_caption = try zettui.dom.elements.styleOwned(a, zettui.dom.elements.paragraph("Sparkline rendered via DOM graph node.", 28), .{ .fg = 0x7DD3FC });

    const left_column = zettui.dom.elements.vbox(&[_]zettui.dom.Node{
        zettui.dom.elements.window("Live metrics"),
        stats,
        sparkline_caption,
        sparkline,
    });

    const badge_caption = try zettui.dom.elements.styleOwned(a, zettui.dom.elements.paragraph("ASCII canvas nodes mix art + layout.", 26), .{ .fg = 0xFBBF24 });
    const vertical_gauge_label = try zettui.dom.elements.styleOwned(
        a,
        zettui.dom.elements.text("Vertical gauge (60%)"),
        .{ .bold = true, .fg = 0xF472B6 },
    );
    const vertical_gauge = try zettui.dom.elements.styleOwned(
        a,
        zettui.dom.elements.gaugeVerticalHeight(0.6, 9),
        .{ .fg = 0x34D399 },
    );
    const vertical_gauge_caption = try zettui.dom.elements.styleOwned(
        a,
        zettui.dom.elements.paragraph("Use gaugeVerticalHeight for stacked fill bars.", 28),
        .{ .fg = 0xA855F7 },
    );

    const right_column = zettui.dom.elements.vbox(&[_]zettui.dom.Node{
        zettui.dom.elements.window("Canvas badge"),
        framed_badge,
        badge_caption,
        zettui.dom.elements.separator(.horizontal),
        vertical_gauge_label,
        vertical_gauge,
        vertical_gauge_caption,
    });

    const dashboard = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        left_column,
        zettui.dom.elements.separator(.vertical),
        right_column,
    }, 3);

    try dashboard.render(&ctx);
    try stdout.writeAll("\n");
}

fn renderButtonGallery(stdout: std.fs.File, allocator: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try renderButtonRow(stdout, a, "Primary actions", &[_][]const u8{ "New project", "Build", "Deploy" });
    try renderButtonRow(stdout, a, "Utility actions", &[_][]const u8{ "Settings", "Logs", "Help" });
    try renderButtonRow(stdout, a, "Media transport", &[_][]const u8{ "Play", "Pause", "Stop", "Record" });

    try stdout.writeAll("\nButtons stay simple today, but onEvent hooks enable\ninteractivity similar to the FTXUI button examples.\n");
}

fn renderButtonRow(
    stdout: std.fs.File,
    allocator: std.mem.Allocator,
    title: []const u8,
    labels: []const []const u8,
) !void {
    var heading_ctx: zettui.dom.RenderContext = .{};
    const heading = try zettui.dom.elements.styleOwned(
        allocator,
        zettui.dom.elements.text(title),
        .{ .bold = true, .fg = 0xF97316 },
    );
    try heading.render(&heading_ctx);
    try stdout.writeAll("\n    ");

    for (labels, 0..) |label, idx| {
        const btn = try zettui.component.widgets.button(allocator, .{ .label = label });
        try btn.render();
        if (idx + 1 < labels.len) {
            try stdout.writeAll("  ");
        }
    }

    try stdout.writeAll("\n");
}
