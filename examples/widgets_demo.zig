const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var stdout = std.fs.File.stdout();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try renderHeading(&stdout, a, "=== Zettui Widgets Demo ===", .{ .bold = true, .fg = 0xF97316 });
    try stdout.writeAll("\n");

    // Slider examples
    try renderHeading(&stdout, a, "--- Slider Widgets ---", .{ .fg = 0x22D3EE });
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
    try renderHeading(&stdout, a, "--- Radio Group Widgets ---", .{ .fg = 0xA855F7 });
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
    try renderHeading(&stdout, a, "--- Interactive Demo Instructions ---", .{ .fg = 0xFCD34D });
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

fn renderHeading(stdout: *std.fs.File, allocator: std.mem.Allocator, text: []const u8, attrs: zettui.dom.StyleAttributes) !void {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(data);
        }
    };
    var ctx: zettui.dom.RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write },
    };
    const node = try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text(text), attrs);
    try node.render(&ctx);
    try stdout.writeAll("\n");
}
