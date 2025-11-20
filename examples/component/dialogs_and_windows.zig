const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Dialogs, Collapsibles, Windows ===", .{ .bold = true, .fg = 0xE879F9 });
    try stdout.writeAll("\n");
    try renderWindow(&stdout, a);
    try stdout.writeAll("\n");
    try renderModal(&stdout, a);
    try stdout.writeAll("\n");
    try renderCollapsible(&stdout, a);
}

fn renderWindow(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Window --", .{ .fg = 0x38BDF8 });
    const body = try windowBody(allocator, "All services healthy.");
    const window_component = try zettui.component.widgets.window(allocator, body, .{ .title = "Status" });
    try window_component.render();
    try stdout.writeAll("\n");
}

fn renderModal(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Modal dialog --", .{ .fg = 0xF97316 });
    const confirm_button = try zettui.component.widgets.button(allocator, .{ .label = "Confirm", .visual = .primary });
    const modal_component = try zettui.component.widgets.modal(allocator, confirm_button, .{
        .title = "Delete file?",
        .is_open = true,
        .dismissible = true,
        .width = 32,
    });
    try modal_component.render();
    try stdout.writeAll("\n");
}

fn renderCollapsible(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Collapsible section --", .{ .fg = 0x34D399 });
    const child = try zettui.component.widgets.button(allocator, .{ .label = "Inside collapsible" });
    const collapsible_component = try zettui.component.widgets.collapsible(allocator, child, .{
        .label = "More details",
        .expanded = false,
    });
    try stdout.writeAll("Collapsed:\n");
    try collapsible_component.render();
    try stdout.writeAll("\nExpanding via space key:\n");
    _ = collapsible_component.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try collapsible_component.render();
    try stdout.writeAll("\n");
}

fn windowBody(allocator: std.mem.Allocator, body: []const u8) !zettui.component.base.Component {
    return try zettui.component.widgets.button(allocator, .{ .label = body });
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
