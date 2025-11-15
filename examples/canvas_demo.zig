const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var builder = try zettui.dom.canvas.CanvasBuilder.init(a, 24, 10, ' ');
    defer builder.deinit();
    const dims = builder.dimensions();

    var stdout = std.fs.File.stdout();

    try stdout.writeAll("Canvas builder shapes:\n");
    builder.drawRect(.{ .x = 0, .y = 0 }, dims.width, dims.height, '#');
    builder.drawLine(.{ .x = 2, .y = 2 }, .{ .x = 21, .y = 7 }, '*');
    builder.drawCircle(.{ .x = 16, .y = 4 }, 3, 'o');
    builder.writeText(.{ .x = 2, .y = 8 }, "Zettui");

    {
        var ctx: zettui.dom.RenderContext = .{};
        try builder.toNode().render(&ctx);
        try stdout.writeAll("\n");
    }

    try stdout.writeAll("Animated spark:\n");
    var pos = zettui.dom.canvas.CanvasBuilder.Coord{ .x = 1, .y = 1 };
    var delta = zettui.dom.canvas.CanvasBuilder.Coord{ .x = 1, .y = 1 };
    var frame: usize = 0;
    while (frame < 8) : (frame += 1) {
        builder.clear();
        builder.drawRect(.{ .x = 0, .y = 0 }, dims.width, dims.height, '#');
        builder.drawLine(.{ .x = 0, .y = 5 }, .{ .x = @as(i32, @intCast(dims.width - 1)), .y = 5 }, '-');
        builder.setPixel(pos, '@');
        var ctx: zettui.dom.RenderContext = .{};
        try builder.toNode().render(&ctx);
        try stdout.writeAll("\n");

        pos.x += delta.x;
        pos.y += delta.y;
        if (pos.x <= 1 or pos.x >= @as(i32, @intCast(dims.width - 2))) delta.x *= -1;
        if (pos.y <= 1 or pos.y >= @as(i32, @intCast(dims.height - 2))) delta.y *= -1;
    }
}
