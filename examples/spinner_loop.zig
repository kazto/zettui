const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    var ctx: zettui.dom.RenderContext = .{};
    var n = zettui.dom.elements.spinner();

    var stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll("Spinner animation (press Ctrl+C to quit)\n");

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
