const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var stdout = std.fs.File.stdout();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    try renderHeading(&stdout, a, "=== Interactive Widgets Demo ===", .{ .bold = true, .fg = 0x22D3EE });
    try stdout.writeAll("Controls:\n");
    try renderHighlighted(&stdout, a, "  Slider: Arrow keys or +/- to adjust\n", 0x34D399);
    try renderHighlighted(&stdout, a, "  Radio: Arrow keys or number keys (1-3) to select\n", 0xA855F7);
    try renderHighlighted(&stdout, a, "  Press 'q' to quit\n\n", 0xF97316);

    // Create widgets
    const slider = try zettui.component.widgets.slider(a, .{
        .min = 0,
        .max = 100,
        .step = 5,
        .horizontal = true,
    });

    const labels = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const radio = try zettui.component.widgets.radioGroup(a, .{
        .labels = &labels,
        .selected_index = 0,
    });

    // Get state pointers for displaying values
    const SliderState = struct {
        value: f32,
        min: f32,
        max: f32,
        step: f32,
        horizontal: bool,
    };

    const RadioGroupState = struct {
        labels: []const []const u8,
        selected_index: usize,
        allocator: std.mem.Allocator,
    };

    const slider_state = @as(*SliderState, @ptrCast(@alignCast(slider.base.user_data.?)));
    const radio_state = @as(*RadioGroupState, @ptrCast(@alignCast(radio.base.user_data.?)));

    // Display current state
    try renderHeading(&stdout, a, "--- Current State ---", .{ .fg = 0xFCD34D });
    const slider_value_buf = try std.fmt.allocPrint(a, "{d:.1}", .{slider_state.value});
    try stdout.writeAll("Slider value: ");
    try stdout.writeAll(slider_value_buf);
    try stdout.writeAll("\n");
    try slider.render();
    try stdout.writeAll("\n\n");

    try stdout.writeAll("Radio selection: ");
    try stdout.writeAll(radio_state.labels[radio_state.selected_index]);
    try stdout.writeAll("\n");
    try radio.render();
    try stdout.writeAll("\n");

    // Demonstrate event handling with some example events
    try stdout.writeAll("\n");
    try renderHeading(&stdout, a, "--- Simulating Events ---", .{ .fg = 0xF472B6 });
    try stdout.writeAll("Sending arrow right to slider...\n");
    _ = slider.onEvent(.{ .key = .{ .arrow_key = .right } });
    const new_slider_value = try std.fmt.allocPrint(a, "{d:.1}", .{slider_state.value});
    try stdout.writeAll("New slider value: ");
    try stdout.writeAll(new_slider_value);
    try stdout.writeAll("\n");
    try slider.render();
    try stdout.writeAll("\n");

    try stdout.writeAll("Sending arrow down to radio group...\n");
    _ = radio.onEvent(.{ .key = .{ .arrow_key = .down } });
    try stdout.writeAll("New radio selection: ");
    try stdout.writeAll(radio_state.labels[radio_state.selected_index]);
    try stdout.writeAll("\n");
    try radio.render();
    try stdout.writeAll("\n");

    try stdout.writeAll("Sending number key '3' to radio group...\n");
    _ = radio.onEvent(.{ .key = .{ .codepoint = '3' } });
    try stdout.writeAll("New radio selection: ");
    try stdout.writeAll(radio_state.labels[radio_state.selected_index]);
    try stdout.writeAll("\n");
    try radio.render();
    try stdout.writeAll("\n");

    try stdout.writeAll("Sending '+' key to slider...\n");
    _ = slider.onEvent(.{ .key = .{ .codepoint = '+' } });
    const final_slider_value = try std.fmt.allocPrint(a, "{d:.1}", .{slider_state.value});
    try stdout.writeAll("Final slider value: ");
    try stdout.writeAll(final_slider_value);
    try stdout.writeAll("\n");
    try slider.render();
    try stdout.writeAll("\n");

    try stdout.writeAll("\nNote: For full interactive control, integrate with a terminal input library.\n");
    try stdout.writeAll("The widgets are ready to receive events via the onEvent() method.\n");
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

fn renderHighlighted(stdout: *std.fs.File, allocator: std.mem.Allocator, text: []const u8, color: u24) !void {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, data: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(data);
        }
    };
    var ctx: zettui.dom.RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write },
    };
    const node = try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text(text), .{ .fg = color });
    try node.render(&ctx);
}
