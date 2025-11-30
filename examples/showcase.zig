const std = @import("std");
const zettui = @import("zettui");

const Theme = struct {
    primary: u24 = 0xF97316,
    accent: u24 = 0x22D3EE,
    glow: u24 = 0xC084FC,
    base: u24 = 0x0F172A,
    text: u24 = 0xE5E7EB,
    muted: u24 = 0x9CA3AF,
};

pub fn main() !void {
    var stdout = std.fs.File.stdout();
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try stdout.writeAll("=== zettui showcase ===\n\n");
    try renderHero(&stdout, a);
    try stdout.writeAll("\n");
    try renderMetrics(&stdout, a);
    try stdout.writeAll("\n");
    try renderComponents(&stdout, a);
    try stdout.writeAll("\n");
    try renderScreenScene(&stdout);
}

fn renderHero(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    const theme = Theme{};
    var ctx = makeSinkContext(stdout, allocator);

    const badge = try zettui.dom.elements.frameStyledOwned(
        allocator,
        zettui.dom.elements.text("crafted terminal ui"),
        .{ .fg = theme.accent, .charset = .single },
    );
    const headline = zettui.dom.elements.linearGradient("zettui / luminous terminals\n", theme.primary, theme.glow);
    const sub_text = "Build expressive layouts, components, and screens with one toolkit. Build expressive layouts, components, and screens with one toolkit.";
    const sub = try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text(sub_text), .{ .fg = theme.text });
    const hero = zettui.dom.elements.vbox(&[_]zettui.dom.Node{ badge, headline, sub });

    const padded = try zettui.dom.elements.styleOwned(allocator, hero, .{ .bg = theme.base });
    const tinted = try zettui.dom.elements.sizeOwned(allocator, padded, 80, 6);
    const framed = try zettui.dom.elements.frameStyledOwned(
        allocator,
        tinted,
        .{ .fg = theme.accent, .charset = .double },
    );
    try framed.render(&ctx);
    try stdout.writeAll("\n");
}

fn renderMetrics(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    const theme = Theme{};
    var ctx = makeSinkContext(stdout, allocator);

    const gauges = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        zettui.dom.elements.gaugeStyled(0.86, .{ .label = "CPU", .show_percentage = true, .width = 22 }),
        zettui.dom.elements.gaugeStyled(0.42, .{ .label = "GPU", .show_percentage = true, .width = 22, .fill = '#', .empty = '.' }),
        zettui.dom.elements.gaugeStyled(0.67, .{ .label = "IO", .show_percentage = true, .width = 22, .fill = '*', .empty = '.' }),
    }, 2);

    const spark_values = [_]f32{ 0.2, 0.4, 0.8, 0.6, 0.3, 0.9, 0.1, 0.5, 0.76, 0.64, 0.88 };
    const sparkline = zettui.dom.elements.graphWidth(&spark_values, 34, 7);
    const sparkline_tinted = try zettui.dom.elements.styleOwned(allocator, sparkline, .{ .fg = theme.accent });

    const gradient_title = zettui.dom.elements.linearGradient("metrics / gradients / sparklines", theme.accent, theme.glow);
    const headline = try zettui.dom.elements.styleOwned(allocator, gradient_title, .{ .bg = theme.base });

    const stack = zettui.dom.elements.vbox(&[_]zettui.dom.Node{
        headline,
        gauges,
        zettui.dom.elements.separator(.horizontal),
        sparkline_tinted,
    });

    const tinted = try zettui.dom.elements.styleOwned(allocator, stack, .{ .bg = theme.base });
    const card = try zettui.dom.elements.frameStyledOwned(
        allocator,
        tinted,
        .{ .fg = theme.primary, .charset = .single },
    );
    try card.render(&ctx);
    try stdout.writeAll("\n");
}

fn renderComponents(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    const theme = Theme{};
    try stdout.writeAll("-- component moments --\n");

    const primary = try zettui.component.widgets.button(allocator, .{ .label = "Launch mission", .visual = .primary });
    const ghost = try zettui.component.widgets.button(allocator, .{ .label = "Ghost action", .frame = .inline_frame });
    const palette = try zettui.component.widgets.visualGallery(allocator, "Palette");
    const window_body = try zettui.component.widgets.button(allocator, .{ .label = "Realtime logs\nstream into this pane." });
    const window_comp = try zettui.component.widgets.window(allocator, window_body, .{ .title = "Observability" });

    const column = try zettui.component.widgets.container(allocator, &[_]zettui.component.base.Component{
        primary,
        ghost,
        palette,
        window_comp,
    });

    const dialog_body = try zettui.component.widgets.button(allocator, .{ .label = "Deploy • Canary • Green" });
    const modal = try zettui.component.widgets.modal(allocator, dialog_body, .{
        .title = "Ready to ship?",
        .is_open = true,
        .dismissible = true,
        .width = 34,
    });

    const row = try zettui.component.widgets.container(allocator, &[_]zettui.component.base.Component{
        column,
        modal,
    });

    try row.render();
    try stdout.writeAll("\n");
    _ = theme;
}

fn renderScreenScene(stdout: *std.fs.File) !void {
    const theme = Theme{};
    const allocator = std.heap.page_allocator;
    var screen = try zettui.screen.Screen.init(allocator, 70, 10);
    defer allocator.free(screen.image.pixels);

    screen.clear(.{ .glyph = " ", .fg = theme.text, .bg = theme.base });
    screen.drawString(2, 1, "Screen compositor");
    screen.drawString(2, 2, "blend DOM + components into pixels");
    screen.drawString(2, 4, "[##] timeline");
    screen.drawString(2, 5, "│ 14:02 deploy");
    screen.drawString(2, 6, "│ 14:05 smoke tests");
    screen.drawString(2, 7, "└ 14:07 promote → prod");
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
