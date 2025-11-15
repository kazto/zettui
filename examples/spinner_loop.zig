const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    var ctx: zettui.dom.RenderContext = .{};
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var n = zettui.dom.elements.spinner();

    var stdout_file = std.fs.File.stdout();
    const heading = try zettui.dom.elements.styleOwned(
        a,
        zettui.dom.elements.text("Spinner animation (press Ctrl+C to quit)"),
        .{ .bold = true, .fg = 0xF97316 },
    );
    try heading.render(&ctx);
    try stdout_file.writeAll("\n");

    var i: usize = 0;
    while (i < 40) : (i += 1) {
        // carriage return to overwrite the same line
        try stdout_file.writeAll("\r");
        try n.render(&ctx);
        try stdout_file.writeAll(" Loading...");

        _ = zettui.dom.elements.spinnerAdvance(&n);
        std.Thread.sleep(80 * std.time.ns_per_ms);
    }

    try stdout_file.writeAll("\nDone.\n");
}
