const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== Integration Gallery (DOM + Component + Screen) ===\n\n");
    try renderDomPanel(&stdout, a);
    try stdout.writeAll("\n");
    try renderComponentPanel(&stdout, a);
    try stdout.writeAll("\n");
    try renderScreenPanel(&stdout);
}

fn renderDomPanel(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- DOM panel --\n");
    var ctx = makeContext(stdout, allocator);
    const stats = zettui.dom.elements.gaugeStyled(0.62, .{ .label = "CPU", .show_percentage = true, .width = 28 });
    try stats.render(&ctx);
    try stdout.writeAll("\n");
    const gradient = zettui.dom.elements.linearGradient("Gradient headline", 0xF97316, 0x3B82F6);
    try gradient.render(&ctx);
    try stdout.writeAll("\n");
    const values = [_]f32{ 0.2, 0.4, 0.8, 0.6, 0.3, 0.9, 0.1, 0.5 };
    var graph = zettui.dom.elements.graphWidth(&values, 32, 6);
    try graph.render(&ctx);
    try stdout.writeAll("\n");
}

fn renderComponentPanel(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Component panel --\n");
    const buttons = try zettui.component.widgets.button(allocator, .{ .label = "Launch", .visual = .primary });
    const gallery = try zettui.component.widgets.visualGallery(allocator, "Visual elements");
    try buttons.render();
    try stdout.writeAll("\n");
    try gallery.render();
    try stdout.writeAll("\n");
}

fn renderScreenPanel(stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Screen panel --\n");
    const allocator = std.heap.page_allocator;
    var screen = try zettui.screen.Screen.init(allocator, 32, 5);
    defer allocator.free(screen.image.pixels);
    screen.clear(.{ .glyph = " ", .fg = 0xF8FAFC, .bg = 0x111827 });
    screen.drawString(2, 1, "Screen compositor");
    screen.drawString(2, 3, "[#[[]]]  demo");
    try screen.present(stdout);
}

fn makeContext(stdout: *std.fs.File, allocator: std.mem.Allocator) zettui.dom.RenderContext {
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
