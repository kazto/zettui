const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Renderer & Maybe decorators ===", .{ .bold = true, .fg = 0xF97316 });
    try stdout.writeAll("\n");
    try renderRendererDecorator(&stdout, a);
    try stdout.writeAll("\n");
    try renderMaybeDecorator(&stdout, a);
}

fn renderRendererDecorator(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- renderer() custom output --", .{ .fg = 0x34D399 });
    const button = try zettui.component.widgets.button(allocator, .{ .label = "Child button", .visual = .primary });
    const decorator = try zettui.component.widgets.renderer(allocator, button, customRenderer);
    try decorator.render();
    try stdout.writeAll("\n");
}

fn customRenderer(ctx: zettui.component.widgets.RendererContext) anyerror!void {
    try ctx.stdout.writeAll("[renderer decorator]\n");
    try ctx.stdout.writeAll("Child component below:\n");
    try ctx.child.render();
}

fn renderMaybeDecorator(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- maybe() toggling visibility --", .{ .fg = 0xA855F7 });
    const child = try zettui.component.widgets.button(allocator, .{ .label = "Maybe child" });
    const maybe_component = try zettui.component.widgets.maybe(allocator, child, true);
    try stdout.writeAll("Visible state:\n");
    try maybe_component.render();
    try stdout.writeAll("\nToggling via custom event (hide):\n");
    _ = maybe_component.onEvent(.{ .custom = .{ .tag = "maybe:hide" } });
    try maybe_component.render();
    try stdout.writeAll("\nToggling via space key (show):\n");
    _ = maybe_component.onEvent(.{ .key = .{ .codepoint = ' ' } });
    try maybe_component.render();
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
