const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Visual Galleries ===", .{ .bold = true, .fg = 0xF59E0B });
    try stdout.writeAll("\n");
    try renderGallery(&stdout, a);
    try stdout.writeAll("\n");
    try renderHoverAndSplit(&stdout, a);
}

fn renderGallery(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Combined gallery --", .{ .fg = 0x10B981 });
    const gallery = try zettui.component.widgets.visualGallery(allocator, "Canvas / Gradient / Hover / Focus");
    try gallery.render();
    try stdout.writeAll("\n");
}

fn renderHoverAndSplit(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Hover wrapper + split layout --", .{ .fg = 0xA855F7 });
    const canvas_panel = try zettui.component.widgets.visualGallery(allocator, "Canvas pane");
    const hover_panel = try zettui.component.widgets.hoverWrapper(allocator, try zettui.component.widgets.visualGallery(allocator, "Hover target"), .{
        .hover_text = "(hover active)",
        .idle_text = "(hover idle)",
    });
    const split = try zettui.component.widgets.splitWithClampIndicator(allocator, hover_panel, canvas_panel, .{
        .orientation = .vertical,
        .ratio = 0.45,
        .handle = "||||",
    });
    try split.render();
    try stdout.writeAll("\n");
}

fn renderHeading(stdout: *std.fs.File, allocator: std.mem.Allocator, text: []const u8, attrs: zettui.dom.StyleAttributes) !void {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    var ctx: zettui.dom.RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write },
    };
    const node = try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text(text), attrs);
    try node.render(&ctx);
    try stdout.writeAll("\n");
}
