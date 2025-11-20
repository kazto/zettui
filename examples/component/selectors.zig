const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Selectors & Toggles ===", .{ .bold = true, .fg = 0xEC4899 });
    try stdout.writeAll("\n");
    try renderCheckboxes(&stdout, a);
    try stdout.writeAll("\n");
    try renderToggles(&stdout, a);
    try stdout.writeAll("\n");
    try renderRadioGroups(&stdout, a);
}

fn renderCheckboxes(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Checkboxes --", .{ .fg = 0xFDE047 });
    const plain = try zettui.component.widgets.checkbox(allocator, .{
        .label = "Enable telemetry",
        .checked = false,
    });
    const framed = try zettui.component.widgets.checkboxFramed(allocator, .{
        .label = "Framed toggle",
        .checked = true,
    }, .{ .title = "Settings" });
    try plain.render();
    try stdout.writeAll("\n");
    try framed.render();
    try stdout.writeAll("\n");
}

fn renderToggles(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Toggles --", .{ .fg = 0x34D399 });
    const toggle_component = try zettui.component.widgets.toggle(allocator, .{
        .on_label = "Dark mode: on",
        .off_label = "Dark mode: off",
        .on = true,
    });
    const framed = try zettui.component.widgets.toggleFramed(allocator, .{
        .on_label = "Notifications: on",
        .off_label = "Notifications: off",
        .on = false,
    }, .{ .title = "Profile" });
    try toggle_component.render();
    try stdout.writeAll("\n");
    try framed.render();
    try stdout.writeAll("\n");
}

fn renderRadioGroups(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Radio groups --", .{ .fg = 0x60A5FA });
    const labels = [_][]const u8{ "Alpha", "Beta", "Gamma" };
    const radios = try zettui.component.widgets.radioGroup(allocator, .{
        .labels = &labels,
        .selected_index = 1,
    });
    try radios.render();
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
