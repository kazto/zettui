const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== FTXUI Table Showcase ===\n\n");

    const headers = [_]zettui.dom.Node{
        zettui.dom.elements.text("Package"),
        zettui.dom.elements.text("Version"),
        zettui.dom.elements.text("Maintainer"),
        zettui.dom.elements.text("Status"),
    };

    const row_core = [_]zettui.dom.Node{
        zettui.dom.elements.text("core-utils"),
        zettui.dom.elements.text("3.2"),
        zettui.dom.elements.text("kernel"),
        zettui.dom.elements.text("stable"),
    };
    const row_graph = [_]zettui.dom.Node{
        zettui.dom.elements.text("graph-kit"),
        zettui.dom.elements.text("1.7"),
        zettui.dom.elements.text("viz"),
        zettui.dom.elements.text("beta"),
    };
    const row_table = [_]zettui.dom.Node{
        zettui.dom.elements.text("table-plus"),
        zettui.dom.elements.text("0.9"),
        zettui.dom.elements.text("ui"),
        zettui.dom.elements.text("alpha"),
    };
    const rows = [_][]const zettui.dom.Node{ &row_core, &row_graph, &row_table };

    const main_table = try zettui.dom.elements.tableOwned(a, &headers, &rows, .{
        .border = true,
        .header_divider = true,
        .column_gap = 3,
    });
    var ctx = makeRenderContext(&stdout);
    try main_table.render(&ctx);

    try stdout.writeAll("\nCompact version:\n");
    const compact_table = try zettui.dom.elements.tableOwned(a, &headers, &rows, .{
        .border = false,
        .column_gap = 1,
    });
    ctx = makeRenderContext(&stdout);
    try compact_table.render(&ctx);
}

fn makeRenderContext(stdout: *std.fs.File) zettui.dom.RenderContext {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    return .{ .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write } };
}
