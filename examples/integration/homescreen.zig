const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== Integration: Homescreen layout ===\n");

    const window_components = try buildWindows(a);
    defer a.free(window_components);

    const sections = [_][]const u8{
        "System",
        "Status",
        "Visuals",
    };
    const home = try zettui.component.widgets.homescreen(a, "FTXUI parity demo", &sections, window_components);
    try home.render();
    try stdout.writeAll("\n");
}

fn buildWindows(allocator: std.mem.Allocator) ![]zettui.component.base.Component {
    const buttons = try zettui.component.widgets.button(allocator, .{ .label = "Launch", .visual = .primary });
    const metrics = try zettui.component.widgets.window(allocator, .{
        .title = "Metrics",
        .body = "CPU: 61%\nRAM: 8.3 GB",
        .buttons = &[_][]const u8{"Refresh"},
    });
    const gallery = try zettui.component.widgets.visualGallery(allocator, "Visual gallery pane");

    const windows = try allocator.alloc(zettui.component.base.Component, 3);
    windows[0] = buttons;
    windows[1] = metrics;
    windows[2] = gallery;
    return windows;
}
