const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const gpa = std.heap.page_allocator;

    var screen = try zettui.screen.Screen.init(gpa, 64, 12);
    defer gpa.free(screen.image.pixels);

    screen.clear(.{ .glyph = " ", .fg = 0xFFFFFF, .bg = 0x000000 });

    // Drawer adapter bridging DOM RenderContext to Screen
    const Adapter = struct {
        fn draw(user_data: *anyopaque, x: i32, y: i32, text: []const u8) anyerror!void {
            const scr = @as(*zettui.screen.Screen, @ptrCast(@alignCast(user_data)));
            if (x >= 0 and y >= 0) {
                scr.drawString(@as(usize, @intCast(x)), @as(usize, @intCast(y)), text);
            }
        }
    };

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    var ctx: zettui.dom.RenderContext = .{
        .sink = null,
        .drawer = .{ .user_data = @as(*anyopaque, @ptrCast(&screen)), .drawText = Adapter.draw },
        .origin_x = 0,
        .origin_y = 0,
        .allocator = a,
    };

    // Build a simple dashboard: two rows
    const top_row = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        zettui.dom.elements.window("Stats"),
        zettui.dom.elements.gaugeWidth(0.75, 20),
        zettui.dom.elements.paragraph("CPU RAM", 3),
    }, 2);

    const bottom_row = zettui.dom.elements.flexboxRow(&[_]zettui.dom.Node{
        zettui.dom.elements.text("Ready"),
        zettui.dom.elements.text("|"),
        zettui.dom.elements.text("Press Q to quit"),
    }, 1);

    const root = zettui.dom.elements.vbox(&[_]zettui.dom.Node{ top_row, bottom_row });
    try root.render(&ctx);

    const out = std.fs.File.stdout();
    try screen.present(out);
}
