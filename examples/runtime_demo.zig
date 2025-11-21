const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var stdout = std.fs.File.stdout();

    try stdout.writeAll("=== DOM runtime showcase ===\n");
    const layout = try makeRuntimeLayout(allocator);
    var ctx = zettui.dom.RenderContext{ .allow_hyperlinks = true };
    try layout.render(&ctx);

    try stdout.writeAll("\n\n=== Component event loop demo ===\n");
    try stdout.writeAll("Queueing toggle events via screen_interactive.EventLoop...\n");
    try driveComponentLoop(allocator);
}

fn makeRuntimeLayout(allocator: std.mem.Allocator) !zettui.dom.Node {
    const heading = try makeHeading(allocator);
    const stats = try makeStatsTable(allocator);
    const canvas = try makeCanvas(allocator);
    const summary = try makeSummary(allocator);

    const children = [_]zettui.dom.Node{ heading, stats, canvas, summary };
    return zettui.dom.elements.vbox(&children);
}

fn makeHeading(allocator: std.mem.Allocator) !zettui.dom.Node {
    const raw = zettui.dom.elements.text("Zettui Runtime Snapshot");
    const colored = try zettui.dom.elements.styleOwned(allocator, raw, .{ .fg = 0xF7C948 });
    const ptr = try allocator.create(zettui.dom.Node);
    ptr.* = colored;
    return zettui.dom.elements.bold(ptr);
}

fn makeStatsTable(allocator: std.mem.Allocator) !zettui.dom.Node {
    const headers = [_][]const u8{ "Metric", "Value" };
    const rows = [_][]const []const u8{
        &[_][]const u8{ "Tasks", "3 running" },
        &[_][]const u8{ "Animations", "1 active" },
        &[_][]const u8{ "Mouse", "captured" },
    };
    const table = zettui.dom.elements.tableSelectable(&headers, &rows, 1, 1);
    const table_ptr = try allocator.create(zettui.dom.Node);
    table_ptr.* = table;
    const scroll = zettui.dom.elements.scrollIndicatorPtr(table_ptr, .{ .top = true, .bottom = true });
    return try zettui.dom.elements.frameOwned(allocator, scroll);
}

fn makeCanvas(allocator: std.mem.Allocator) !zettui.dom.Node {
    var builder = try zettui.dom.CanvasBuilder.init(allocator, 26, 6, '.');
    builder.drawHorizontalLine(1, 2, 23, '=');
    builder.drawHorizontalLine(4, 2, 23, '=');
    builder.drawVerticalLine(2, 1, 4, '|');
    builder.drawVerticalLine(23, 1, 4, '|');
    builder.drawText(4, 2, "LOOP");
    builder.drawText(11, 2, "SCREEN");
    builder.drawText(20, 2, "TASK");
    return try builder.toNode();
}

fn makeSummary(allocator: std.mem.Allocator) !zettui.dom.Node {
    const link_text = zettui.dom.elements.text("runtime_event_loop.md");
    const link_ptr = try allocator.create(zettui.dom.Node);
    link_ptr.* = link_text;
    const hyperlink = zettui.dom.elements.hyperlink(link_ptr, "docs/runtime_event_loop.md");
    const parts = [_]zettui.dom.Node{
        zettui.dom.elements.text("Docs available at "),
        hyperlink,
        zettui.dom.elements.text(" – run `zig build run:runtime-demo` to see this output."),
    };
    const automerged = zettui.dom.elements.automerge(&parts);
    return try zettui.dom.elements.centerOwned(allocator, automerged, 60);
}

fn driveComponentLoop(allocator: std.mem.Allocator) !void {
    const toggle = try zettui.component.widgets.toggle(allocator, .{
        .on_label = "[online]",
        .off_label = "[offline]",
        .on = false,
    });
    const decorated = try zettui.component.decorators.underlineDecorator(allocator, toggle, .{ .thickness = 1.5 });
    var maybe = try zettui.component.decorators.maybe(allocator, decorated, true);

    var event_loop = zettui.screen_interactive.EventLoop.init(allocator);
    defer event_loop.deinit();
    event_loop.loop.target_frame_ms = 0;

    try event_loop.postEvent(.{ .key = .{ .codepoint = ' ' } });
    try event_loop.postEvent(.{ .custom = .{ .tag = "animation tick" } });
    try event_loop.run(maybe);

    try std.fs.File.stdout().writeAll("Toggle state after events: ");
    try toggle.render();
    try std.fs.File.stdout().writeAll("\n");

    zettui.component.decorators.maybeSetActive(maybe, false);
    try std.fs.File.stdout().writeAll("maybe() disabled -> wrapper renders nothing:\n");
    try maybe.render();
    try std.fs.File.stdout().writeAll("\n");
}
