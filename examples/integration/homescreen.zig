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
    const metrics_body = try windowBody(allocator, "CPU: 61%\nRAM: 8.3 GB");
    const metrics = try zettui.component.widgets.window(allocator, metrics_body, .{ .title = "Metrics" });
    const gallery_child = try zettui.component.widgets.visualGallery(allocator, "Visual gallery pane");
    const gallery = try zettui.component.widgets.window(allocator, gallery_child, .{ .title = "Gallery" });

    const tree_text = try packageTreeText(allocator);
    const tree_component = try textRenderer(allocator, tree_text);
    const packages = try zettui.component.widgets.window(allocator, tree_component, .{ .title = "Packages" });

    const clamp_left = try zettui.component.widgets.button(allocator, .{ .label = "Overview", .visual = .ghost, .frame = .inline_frame });
    const clamp_right = try zettui.component.widgets.button(allocator, .{ .label = "Details", .visual = .ghost, .frame = .inline_frame });
    const clamp_split = try zettui.component.widgets.splitWithClampIndicator(allocator, clamp_left, clamp_right, .{
        .orientation = .horizontal,
        .ratio = 0.5,
        .min_ratio = 0.35,
        .max_ratio = 0.75,
        .handle = "Clamp demo",
    });
    const clamp_window = try zettui.component.widgets.window(allocator, clamp_split, .{ .title = "Resizable Split" });

    const windows = try allocator.alloc(zettui.component.base.Component, 5);
    windows[0] = buttons;
    windows[1] = metrics;
    windows[2] = gallery;
    windows[3] = packages;
    windows[4] = clamp_window;
    return windows;
}

fn windowBody(allocator: std.mem.Allocator, body: []const u8) !zettui.component.base.Component {
    return try zettui.component.widgets.button(allocator, .{ .label = body });
}

fn textRenderer(allocator: std.mem.Allocator, text: []const u8) !zettui.component.base.Component {
    const owned = try allocator.dupe(u8, text);
    const Data = struct { text: []const u8 };
    const data_ptr = try allocator.create(Data);
    data_ptr.* = .{ .text = owned };
    return zettui.component.widgets.renderer(allocator, try zettui.component.widgets.label(allocator, ""), struct {
        fn render(ctx: zettui.component.widgets.RendererContext) anyerror!void {
            const data = @as(*Data, @ptrCast(@alignCast(ctx.child.base.user_data.?)));
            try ctx.stdout.writeAll(data.text);
        }
    }.render);
}

fn packageTreeText(allocator: std.mem.Allocator) ![]u8 {
    const roots = [_]zettui.dom.elements.TreeEntry{
        .{
            .label = "packages",
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
