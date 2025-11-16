const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var screen = try zettui.screen.Screen.init(allocator, 48, 8);
    defer allocator.free(screen.image.pixels);

    var stdout = std.fs.File.stdout();
    try stdout.writeAll("=== Screen custom loop ===\n");
    try stdout.writeAll("Rendering progress bar frames with manual timing...\n");

    var frame: usize = 0;
    while (frame <= 20) : (frame += 1) {
        screen.clear(.{ .glyph = " ", .fg = 0xFFFFFF, .bg = 0x000000 });
        const percent = frame * 5;
        drawProgress(&screen, percent);
        try screen.present(stdout);
        std.Thread.sleep(80 * std.time.ns_per_ms);
    }

    try stdout.writeAll("\nCustom loop finished.\n");
}

fn drawProgress(screen: *zettui.screen.Screen, percent: usize) void {
    const width: usize = 32;
    const filled = @min(width, (percent * width) / 100);
    const bar_y: usize = 2;
    screen.drawString(2, 0, "Manual redraw via Screen API");
    screen.drawString(2, bar_y - 1, "Progress:");
    var idx: usize = 0;
    while (idx < width) : (idx += 1) {
        const glyph = if (idx < filled) "#" else ".";
        screen.drawString(2 + idx, bar_y, glyph);
    }
    var buf: [32]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "{d}% complete   ", .{percent}) catch return;
    screen.drawString(2, bar_y + 2, msg);
}
