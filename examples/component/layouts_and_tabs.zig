const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Tabs & Resizable Splits ===", .{ .bold = true, .fg = 0x60A5FA });
    try stdout.writeAll("\n");
    try renderTabs(&stdout, a);
    try stdout.writeAll("\n");
    try renderSplit(&stdout, a);
}

fn renderTabs(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    const labels = [_][]const u8{ "Overview", "Metrics", "Logs" };
    try renderHeading(stdout, allocator, "-- Horizontal tabs --", .{ .fg = 0xF97316 });
    const horizontal = try zettui.component.widgets.tabHorizontal(allocator, .{
        .labels = &labels,
        .selected_index = 1,
    });
    try horizontal.render();
    try stdout.writeAll("\n");

    try renderHeading(stdout, allocator, "-- Vertical tabs --", .{ .fg = 0x34D399 });
    const vertical = try zettui.component.widgets.tabVertical(allocator, .{
        .labels = &labels,
        .selected_index = 2,
    });
    try vertical.render();
    try stdout.writeAll("\n");
}

fn renderSplit(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Resizable split with clamp indicator --", .{ .fg = 0xA855F7 });
    const left = try zettui.component.widgets.button(allocator, .{ .label = "Left pane" });
    const right = try zettui.component.widgets.button(allocator, .{ .label = "Right pane", .visual = .primary });
    const split_component = try zettui.component.widgets.splitWithClampIndicator(allocator, left, right, .{
        .orientation = .horizontal,
        .ratio = 0.4,
        .min_ratio = 0.2,
        .max_ratio = 0.8,
        .handle = "====",
    });
    try split_component.render();
    try stdout.writeAll("\n");

    try stdout.writeAll("Clamp to min via custom event:\n");
    _ = split_component.onEvent(.{ .custom = .{ .tag = "split:clamp:min" } });
    try split_component.render();
    try stdout.writeAll("\nClamp to max via custom event:\n");
    _ = split_component.onEvent(.{ .custom = .{ .tag = "split:clamp:max" } });
    try split_component.render();
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
