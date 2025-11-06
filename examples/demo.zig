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
    });

    screen.drawString(2, 1, "Zettui demo");

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
}
