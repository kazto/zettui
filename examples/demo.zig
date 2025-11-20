const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var screen = try zettui.screen.Screen.init(allocator, 32, 4);
    defer allocator.free(screen.image.pixels);

    screen.clear(.{
        .glyph = " ",
        .fg = 0xFFFFFF,
        .bg = 0x000000,
        .style = 0,
    });

    screen.drawString(2, 1, "Zettui demo", .{});

    const stdout = std.fs.File.stdout();
    try screen.present(stdout);

    // Simple DOM showcase
    var ctx: zettui.dom.RenderContext = .{};
    try stdout.writeAll("\nDOM elements:\n");
    {
        var wnd = zettui.dom.Node{ .window = .{ .title = "Window" } };
        try wnd.render(&ctx);
        try stdout.writeAll("\n");
        var sep = zettui.dom.Node{ .separator = .{} };
        try sep.render(&ctx);
        var g = zettui.dom.Node{ .gauge = .{ .fraction = 0.5 } };
        try g.render(&ctx);
        try stdout.writeAll(" ");
        var sp = zettui.dom.Node{ .spinner = .{} };
        try sp.render(&ctx);
        try stdout.writeAll("\n");

        // Frame around a child node (owned)
        var dom_arena = std.heap.ArenaAllocator.init(allocator);
        defer dom_arena.deinit();
        const da = dom_arena.allocator();
        var fr = try zettui.dom.elements.frameOwned(da, zettui.dom.elements.text("framed"));
        try fr.render(&ctx);

        // Paragraph wrapped to width 16
        try stdout.writeAll("Paragraph (w=16):\n");
        var para = zettui.dom.elements.paragraph(
            "This is a wrapped paragraph demo.",
            16,
        );
        try para.render(&ctx);
        try stdout.writeAll("\n");
    }

    // Simple Component showcase
    try stdout.writeAll("\nComponents:\n");
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    const btn = try zettui.component.widgets.button(a, .{ .label = "OK" });
    try btn.render();
    try stdout.writeAll("\n");

    const cb = try zettui.component.widgets.checkbox(a, .{ .label = "Accept", .checked = false });
    try cb.render();
    try stdout.writeAll("\n");

    const tog = try zettui.component.widgets.toggle(a, .{ .on_label = "ON", .off_label = "OFF", .on = true });
    try tog.render();
    try stdout.writeAll("\n");

    // DOM rendering via Screen drawer (coordinate-aware)
    try stdout.writeAll("\nDOM drawer demo (Screen):\n");
    screen.clear(.{ .glyph = " ", .fg = 0xFFFFFF, .bg = 0x000000, .style = 0 });

    const Adapter = struct {
        fn draw(user_data: *anyopaque, x: i32, y: i32, text: []const u8, style: zettui.screen.Pixel) anyerror!void {
            const scr = @as(*zettui.screen.Screen, @ptrCast(@alignCast(user_data)));
            if (x >= 0 and y >= 0) {
                scr.drawString(@as(usize, @intCast(x)), @as(usize, @intCast(y)), text, style);
            }
        }
    };

    var ctx2: zettui.dom.RenderContext = .{
        .sink = null,
        .drawer = .{ .user_data = @as(*anyopaque, @ptrCast(&screen)), .drawText = Adapter.draw },
        .origin_x = 1,
        .origin_y = 0,
        .allocator = a,
    };

    const row = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        zettui.dom.elements.text("Hello"),
        zettui.dom.elements.gaugeWidth(0.6, 10),
        zettui.dom.elements.paragraph("wrap", 2),
    }, 1);
    try row.render(&ctx2);
    try screen.present(stdout);
}
