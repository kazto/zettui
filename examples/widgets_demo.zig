const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var stdout = std.fs.File.stdout();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try stdout.writeAll("=== Zettui Widgets Demo ===\n\n");

    // Slider examples
    try stdout.writeAll("--- Slider Widgets ---\n");
    try stdout.writeAll("Horizontal slider (0-100, step=5):\n");
    const horizontal_slider = try zettui.component.widgets.slider(a, .{
        .min = 0,
        .max = 100,
        .step = 5,
        .horizontal = true,
    });
    try horizontal_slider.render();
    try stdout.writeAll("\n\n");

    try stdout.writeAll("Vertical slider (0-50, step=2):\n");
    const vertical_slider = try zettui.component.widgets.slider(a, .{
        .min = 0,
        .max = 50,
        .step = 2,
        .horizontal = false,
    });
    try vertical_slider.render();
    try stdout.writeAll("\n\n");

    try stdout.writeAll("Small range slider (10-20, step=1):\n");
    const small_slider = try zettui.component.widgets.slider(a, .{
        .min = 10,
        .max = 20,
        .step = 1,
        .horizontal = true,
    });
    try small_slider.render();
    try stdout.writeAll("\n\n");

    // Radio group examples
    try stdout.writeAll("--- Radio Group Widgets ---\n");
    try stdout.writeAll("Radio group (3 options, selected=1):\n");
    const labels1 = [_][]const u8{ "Option A", "Option B", "Option C" };
    const radio1 = try zettui.component.widgets.radioGroup(a, .{
        .labels = &labels1,
        .selected_index = 1,
    });
    try radio1.render();
    try stdout.writeAll("\n\n");

    try stdout.writeAll("Radio group (5 options, selected=0):\n");
    const labels2 = [_][]const u8{ "Red", "Green", "Blue", "Yellow", "Purple" };
    const radio2 = try zettui.component.widgets.radioGroup(a, .{
        .labels = &labels2,
        .selected_index = 0,
    });
    try radio2.render();
    try stdout.writeAll("\n\n");

    try stdout.writeAll("Radio group (single option):\n");
    const labels3 = [_][]const u8{"Only Choice"};
    const radio3 = try zettui.component.widgets.radioGroup(a, .{
        .labels = &labels3,
        .selected_index = 0,
    });
    try radio3.render();
    try stdout.writeAll("\n\n");

    // Interactive demo instructions
    try stdout.writeAll("--- Interactive Demo Instructions ---\n");
    try stdout.writeAll("To test interactivity:\n");
    try stdout.writeAll("  Slider controls:\n");
    try stdout.writeAll("    - Arrow keys (left/right for horizontal, up/down for vertical)\n");
    try stdout.writeAll("    - Plus/Minus keys (+/-/=/-/_)\n");
    try stdout.writeAll("  Radio group controls:\n");
    try stdout.writeAll("    - Arrow keys (up/down to navigate)\n");
    try stdout.writeAll("    - Number keys (1-9 to select by index)\n");
    try stdout.writeAll("    - Space/Enter to confirm selection\n");
    try stdout.writeAll("\n");
}
