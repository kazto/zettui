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

    // Show focus + cursor decorators: render text and a caret using selection info
    try out.writeAll("\nFocus + Cursor decorators demo:\n");
    screen.clear(.{ .glyph = " ", .fg = 0xFFFFFF, .bg = 0x000000 });

    const editable = zettui.dom.elements.text("Edit me");
    // Wrap with focus and cursor (index 4)
    const focused = try zettui.dom.elements.focusOwned(a, editable, .center);
    var with_cursor = try zettui.dom.elements.cursorOwned(a, focused, 4);

    // Render at (2,2)
    var ctx3: zettui.dom.RenderContext = .{
        .sink = null,
        .drawer = .{ .user_data = @as(*anyopaque, @ptrCast(&screen)), .drawText = Adapter.draw },
        .origin_x = 2,
        .origin_y = 2,
        .allocator = a,
    };
    try with_cursor.render(&ctx3);

    // Query selection state and draw caret below the cursor index
    var sel: zettui.dom.Selection = .{};
    var tmp = with_cursor; // select requires mutable Node
    tmp.select(&sel);
    const caret_x: usize = @intCast(ctx3.origin_x + @as(i32, @intCast(sel.cursor_index)));
    const caret_y: usize = @intCast(ctx3.origin_y + 1);
    screen.drawString(caret_x, caret_y, "^");
    try screen.present(out);
}
