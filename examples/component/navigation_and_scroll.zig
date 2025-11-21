const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Navigation & Scrollbars ===", .{ .bold = true, .fg = 0x7C3AED });
    try stdout.writeAll("\n");
    try renderMenuNavigation(&stdout, a);
    try stdout.writeAll("\n");
    try renderScrollbarDemo(&stdout, a);
    try stdout.writeAll("\n");
    try renderFocusCursorSelection(&stdout, a);
}

fn renderMenuNavigation(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Menu navigation (arrow keys & custom events) --", .{ .fg = 0xF59E0B });
    const items = [_][]const u8{ "Overview", "Metrics", "Rendering", "Input" };
    const menu_component = try zettui.component.widgets.menu(allocator, .{
        .items = &items,
        .selected_index = 0,
        .loop_navigation = true,
        .highlight_color = 0xF59E0B,
    });
    try stdout.writeAll("Initial state:\n");
    try menu_component.render();

    try stdout.writeAll("\nSending DOWN arrow twice:\n");
    _ = menu_component.onEvent(.{ .key = .{ .arrow_key = .down } });
    _ = menu_component.onEvent(.{ .key = .{ .arrow_key = .down } });
    try menu_component.render();
    try stdout.writeAll("\n");
}

fn renderScrollbarDemo(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Scrollbar --", .{ .fg = 0x34D399 });
    const scrollbar_component = try zettui.component.widgets.scrollbar(allocator, .{
        .content_length = 100,
        .viewport_length = 12,
        .position = 0,
        .orientation = .vertical,
    });
    try stdout.writeAll("Initial scrollbar:\n");
    try scrollbar_component.render();
    try stdout.writeAll("\nSending DOWN arrow and custom clamp to max:\n");
    _ = scrollbar_component.onEvent(.{ .key = .{ .arrow_key = .down } });
    _ = scrollbar_component.onEvent(.{ .key = .{ .arrow_key = .down } });
    try scrollbar_component.render();
    try stdout.writeAll("\n");
}

fn renderFocusCursorSelection(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Focus / cursor / selection signals --", .{ .fg = 0x22D3EE });
    const hover_child = try zettui.component.widgets.button(allocator, .{ .label = "Hover target" });
    const hover_component = try zettui.component.widgets.hoverWrapper(allocator, hover_child, .{
        .hover_text = "(hovered)",
        .idle_text = "(idle)",
    });
    try stdout.writeAll("Idle hover wrapper:\n");
    try hover_component.render();
    try stdout.writeAll("\nMouse enters -> hovered:\n");
    _ = hover_component.onEvent(.{ .mouse = .{ .position = .{}, .buttons = .{} } });
    try hover_component.render();
    try stdout.writeAll("\nMouse leaves (custom event):\n");
    _ = hover_component.onEvent(.{ .custom = .{ .tag = "hover:leave" } });
    try hover_component.render();
    try stdout.writeAll("\n\nCursor tracking in multiline input:\n");
    const textarea = try zettui.component.widgets.textInput(allocator, .{
        .placeholder = "Logs...",
        .multiline = true,
        .visible_lines = 2,
        .bordered = true,
    });
    _ = textarea.onEvent(.{ .key = .{ .codepoint = 'A' } });
    _ = textarea.onEvent(.{ .key = .{ .codepoint = 'B' } });
    _ = textarea.onEvent(.{ .key = .{ .codepoint = '\n' } });
    _ = textarea.onEvent(.{ .key = .{ .codepoint = 'C' } });
    _ = textarea.onEvent(.{ .key = .{ .arrow_key = .left } });
    try textarea.render();
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
