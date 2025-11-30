const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== Integration Gallery (DOM + Component + Screen) ===\n\n");
    try renderDomPanel(&stdout, a);
    try stdout.writeAll("\n");
    try renderComponentPanel(&stdout, a);
    try stdout.writeAll("\n");
    try renderScreenPanel(&stdout);
}

fn renderDomPanel(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- DOM panel --\n");
    var ctx = makeContext(stdout, allocator);
    const stats = zettui.dom.elements.gaugeStyled(0.62, .{ .label = "CPU", .show_percentage = true, .width = 28 });
    try stats.render(&ctx);
    try stdout.writeAll("\n");
    const gradient = zettui.dom.elements.linearGradient("Gradient headline", 0xF97316, 0x3B82F6);
    try gradient.render(&ctx);
    try stdout.writeAll("\n");
    const values = [_]f32{ 0.2, 0.4, 0.8, 0.6, 0.3, 0.9, 0.1, 0.5 };
    var graph = zettui.dom.elements.graphWidth(&values, 32, 6);
    try graph.render(&ctx);
    try stdout.writeAll("\n");

    try stdout.writeAll("Package tree (html_like + tree):\n");
    const tree_text = try packageTreeText(allocator);
    defer allocator.free(tree_text);
    try stdout.writeAll(tree_text);
}

fn renderComponentPanel(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Component panel --\n");
    const buttons = try zettui.component.widgets.button(allocator, .{ .label = "Launch", .visual = .primary });
    const gallery = try zettui.component.widgets.visualGallery(allocator, "Visual elements");
    try buttons.render();
    try stdout.writeAll("\n");
    try gallery.render();
    try stdout.writeAll("\n");

    const left = try zettui.component.widgets.button(allocator, .{ .label = "Logs", .visual = .ghost, .frame = .inline_frame });
    const right = try zettui.component.widgets.button(allocator, .{ .label = "Packages", .visual = .ghost, .frame = .inline_frame });
    const split = try zettui.component.widgets.splitWithClampIndicator(allocator, left, right, .{
        .orientation = .horizontal,
        .ratio = 0.45,
        .min_ratio = 0.3,
        .max_ratio = 0.7,
        .handle = "Clamp indicator",
    });
    try split.render();
    try stdout.writeAll("\n");
}

fn renderScreenPanel(stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Screen panel --\n");
    const allocator = std.heap.page_allocator;
    var screen = try zettui.screen.Screen.init(allocator, 32, 5);
    defer allocator.free(screen.image.pixels);
    screen.clear(.{ .glyph = " ", .fg = 0xF8FAFC, .bg = 0x111827 });
    screen.drawString(2, 1, "Screen compositor");
    screen.drawString(2, 3, "[#[[]]]  demo");
    try screen.present(stdout);
}

fn makeContext(stdout: *std.fs.File, allocator: std.mem.Allocator) zettui.dom.RenderContext {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    return .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write },
        .allocator = allocator,
    };
}

fn packageTreeText(allocator: std.mem.Allocator) ![]u8 {
    const roots = [_]zettui.dom.elements.TreeEntry{
        .{
            .label = "packages",
            .status = .plain,
            .children = &[_]zettui.dom.elements.TreeEntry{
                .{ .label = "ftxui", .status = .installing },
                .{
                    .label = "zettui",
                    .status = .success,
                    .children = &[_]zettui.dom.elements.TreeEntry{
                        .{ .label = "dom", .status = .success },
                        .{ .label = "component", .status = .success },
                        .{ .label = "screen", .status = .success },
                    },
                },
                .{ .label = "demo-tool", .status = .failure },
            },
        },
    };
    const tree_node = try zettui.dom.elements.treeOwned(allocator, &roots);
    return switch (tree_node) {
        .text => |t| try allocator.dupe(u8, t.content),
        else => blk: {
            var buffer = std.array_list.Managed(u8).init(allocator);
            errdefer buffer.deinit();
            const Sink = struct {
                fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
                    const list = @as(*std.array_list.Managed(u8), @ptrCast(@alignCast(user_data)));
                    try list.appendSlice(bytes);
                }
            };
            var ctx = zettui.dom.RenderContext{
                .sink = .{ .user_data = @as(*anyopaque, @ptrCast(&buffer)), .writeAll = Sink.write },
                .allocator = allocator,
            };
            try tree_node.render(&ctx);
            break :blk try buffer.toOwnedSlice();
        },
    };
}
