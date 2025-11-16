const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    var stdout = std.fs.File.stdout();
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try renderHeading(&stdout, a, "=== Component: Buttons & Windows ===", .{ .bold = true, .fg = 0xF97316 });
    try stdout.writeAll("\n");
    try renderButtons(&stdout, a);
    try stdout.writeAll("\n");
    try renderButtonFrames(&stdout, a);
}

fn renderButtons(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Button styles --", .{ .fg = 0x22D3EE });
    const plain = try zettui.component.widgets.button(allocator, .{ .label = "Plain" });
    const primary = try zettui.component.widgets.button(allocator, .{ .label = "Primary", .visual = .primary });
    const danger = try zettui.component.widgets.button(allocator, .{ .label = "Danger", .visual = .danger });
    const animated = try zettui.component.widgets.buttonAnimated(allocator, "Animated pulse", .{
        .start_color = 0xF472B6,
        .end_color = 0xC026D3,
        .duration_ms = 320,
    });

    try plain.render();
    try stdout.writeAll("\n");
    try primary.render();
    try stdout.writeAll("\n");
    try danger.render();
    try stdout.writeAll("\n");
    try animated.render();
    try stdout.writeAll("\n");
}

fn renderButtonFrames(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Buttons in frames/windows --", .{ .fg = 0x34D399 });
    const framed = try zettui.component.widgets.buttonInFrame(allocator, "Frame button", .{ .title = "FTXUI parity" });
    try framed.render();
    try stdout.writeAll("\n");

    const window = try zettui.component.widgets.window(allocator, .{
        .title = "Window with actions",
        .body = "Use button components to pop dialogs or trigger async work.",
        .buttons = &[_][]const u8{ "Accept", "Decline" },
    });
    try window.render();
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
