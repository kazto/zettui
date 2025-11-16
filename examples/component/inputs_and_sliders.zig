const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Inputs & Sliders ===", .{ .bold = true, .fg = 0x22D3EE });
    try stdout.writeAll("\n");
    try renderSliders(&stdout, a);
    try stdout.writeAll("\n");
    try renderInputs(&stdout, a);
    try stdout.writeAll("\n");
    try simulateEvents(&stdout, a);
}

fn renderSliders(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Slider widgets --", .{ .fg = 0x34D399 });
    const horizontal_slider = try zettui.component.widgets.slider(allocator, .{
        .min = 0,
        .max = 100,
        .step = 5,
        .horizontal = true,
    });
    const vertical_slider = try zettui.component.widgets.slider(allocator, .{
        .min = 0,
        .max = 50,
        .step = 2,
        .horizontal = false,
    });
    const small_slider = try zettui.component.widgets.slider(allocator, .{
        .min = 10,
        .max = 20,
        .step = 1,
    });

    try stdout.writeAll("Horizontal slider (0-100, step=5):\n");
    try horizontal_slider.render();
    try stdout.writeAll("\n\nVertical slider (0-50, step=2):\n");
    try vertical_slider.render();
    try stdout.writeAll("\n\nSmall slider (10-20, step=1):\n");
    try small_slider.render();
    try stdout.writeAll("\n");
}

fn renderInputs(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Text inputs --", .{ .fg = 0xF97316 });
    const placeholder = try zettui.component.widgets.textInput(allocator, .{
        .placeholder = "Enter name",
        .placeholder_style = "(name)",
        .bordered = true,
    });
    const password = try zettui.component.widgets.textInput(allocator, .{
        .placeholder = "Password",
        .is_password = true,
        .prefix = "pwd>",
    });
    const multiline = try zettui.component.widgets.textInput(allocator, .{
        .placeholder = "Notes",
        .multiline = true,
        .visible_lines = 3,
    });

    try stdout.writeAll("Framed placeholder input:\n");
    try placeholder.render();
    try stdout.writeAll("\n\nPassword input:\n");
    try password.render();
    try stdout.writeAll("\n\nMultiline input:\n");
    try multiline.render();
    try stdout.writeAll("\n");
}

fn simulateEvents(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Simulated events --", .{ .fg = 0xA855F7 });
    const slider = try zettui.component.widgets.slider(allocator, .{
        .min = 0,
        .max = 10,
        .step = 1,
    });
    const input = try zettui.component.widgets.textInput(allocator, .{
        .placeholder = "Type here",
        .bordered = true,
    });

    try stdout.writeAll("Initial slider state:\n");
    try slider.render();
    try stdout.writeAll("\nSending RIGHT arrow and '+'...\n");
    _ = slider.onEvent(.{ .key = .{ .arrow_key = .right } });
    _ = slider.onEvent(.{ .key = .{ .codepoint = '+' } });
    try slider.render();
    try stdout.writeAll("\n\nTyping \"hi\" into input via events:\n");
    _ = input.onEvent(.{ .key = .{ .codepoint = 'h' } });
    _ = input.onEvent(.{ .key = .{ .codepoint = 'i' } });
    try input.render();
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
