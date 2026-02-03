const std = @import("std");
const zettui = @import("zettui");

const Cursor = zettui.screen.Cursor;
const ScreenCtl = zettui.screen.ScreenControl;

pub fn main() !void {
    const gpa = std.heap.page_allocator;
    var stdout = std.fs.File.stdout();

    // Hide cursor and clear screen
    try stdout.writeAll(Cursor.hide);
    try stdout.writeAll(ScreenCtl.clearAndHome);

    var interactive = try zettui.screen.ScreenInteractive.init(gpa, 46, 9);
    defer interactive.deinit();

    var event_stream = [_]zettui.screen.LoopEvent{
        .{ .tick = .{ .delta_ns = 16 * std.time.ns_per_ms } },
        .{ .custom = .{ .tag = "nested", .payload = "" } },
        .{ .tick = .{ .delta_ns = 16 * std.time.ns_per_ms } },
        .{ .resize = .{ .width = 50, .height = 10 } },
        .{ .tick = .{ .delta_ns = 16 * std.time.ns_per_ms } },
        .{ .custom = .{ .tag = "restored-io", .payload = "" } },
        .{ .tick = .{ .delta_ns = 16 * std.time.ns_per_ms } },
        .{ .tick = .{ .delta_ns = 16 * std.time.ns_per_ms } },
        .{ .tick = .{ .delta_ns = 16 * std.time.ns_per_ms } },
    };
    var state = State{
        .stdout = &stdout,
        .events = event_stream[0..],
    };

    const Fetcher = struct {
        fn fetch(_: *zettui.screen.ScreenInteractive, ctx: ?*anyopaque) anyerror!?zettui.screen.LoopEvent {
            const st = @as(*State, @ptrCast(@alignCast(ctx.?)));
            if (st.cursor >= st.events.len) return null;
            // Add delay between frames for visible animation
            std.Thread.sleep(200 * std.time.ns_per_ms);
            defer st.cursor += 1;
            return st.events[st.cursor];
        }
    };

    const Handler = struct {
        fn handle(loop_screen: *zettui.screen.ScreenInteractive, event: zettui.screen.LoopEvent, ctx: ?*anyopaque) anyerror!bool {
            const st = @as(*State, @ptrCast(@alignCast(ctx.?)));
            switch (event) {
                .tick => {
                    st.progress = @min(@as(usize, 100), st.progress + 15);
                    st.note = "tick: advancing progress";
                },
                .resize => |r| {
                    st.note = "resize event received";
                    st.dim = .{ .width = r.width, .height = r.height };
                },
                .custom => |c| {
                    if (std.mem.eql(u8, c.tag, "nested")) {
                        var guard = loop_screen.nestedScreen();
                        st.note = "entered nested screen guard";
                        render(loop_screen, st) catch {};
                        guard.restore();
                        st.note = "nested guard restored";
                    } else if (std.mem.eql(u8, c.tag, "restored-io")) {
                        const Restore = struct {
                            fn cb(cb_ctx: ?*anyopaque) void {
                                const out = @as(*std.fs.File, @ptrCast(@alignCast(cb_ctx.?)));
                                _ = out.writeAll("IO restored callback fired.\n") catch {};
                            }
                        };
                        var guard = loop_screen.restoredIo(Restore.cb, st.stdout_anyopaque());
                        st.note = "temporarily handing back IO";
                        render(loop_screen, st) catch {};
                        guard.restore();
                        st.note = "resumed interactive output";
                    } else {
                        st.note = "custom event";
                    }
                },
                .input => {
                    st.note = "input ignored";
                },
            }
            try render(loop_screen, st);
            return st.progress < 100;
        }
    };

    var loop = interactive.customLoop(Fetcher.fetch, Handler.handle, @as(?*anyopaque, @ptrCast(&state)));
    try loop.run();

    // Show cursor and move below the rendered area
    try stdout.writeAll(Cursor.show);
    var pos_buf: [32]u8 = undefined;
    try stdout.writeAll(Cursor.moveTo(&pos_buf, 12, 1));
    try stdout.writeAll("Custom loop finished.\n");
}

const State = struct {
    stdout: *std.fs.File,
    events: []const zettui.screen.LoopEvent,
    cursor: usize = 0,
    progress: usize = 0,
    note: []const u8 = "queue primed",
    dim: struct { width: usize = 46, height: usize = 9 } = .{},

    fn stdout_anyopaque(self: *State) ?*anyopaque {
        return @as(?*anyopaque, @ptrCast(self.stdout));
    }
};

fn render(interactive: *zettui.screen.ScreenInteractive, state: *State) !void {
    // Move cursor to home position for in-place update
    try state.stdout.writeAll(Cursor.home);

    var screen = interactive.screen();
    screen.clear(.{ .glyph = " ", .fg = 0xE5E7EB, .bg = 0x111827 });

    const width: usize = 30;
    const filled = @min(width, (state.progress * width) / 100);
    screen.drawString(2, 0, "Custom Loop (ScreenInteractive)");
    screen.drawString(2, 2, "Progress:");
    var idx: usize = 0;
    while (idx < width) : (idx += 1) {
        const glyph = if (idx < filled) "#" else ".";
        screen.drawString(2 + idx, 3, glyph);
    }
    var buf: [64]u8 = undefined;
    const msg = try std.fmt.bufPrint(&buf, "{d}% complete | note: {s}", .{ state.progress, state.note });
    screen.drawString(2, 5, msg);
    const dim_msg = try std.fmt.bufPrint(&buf, "target size: {d}x{d}", .{ state.dim.width, state.dim.height });
    screen.drawString(2, 6, dim_msg);

    // Show frame count for visual feedback
    const frame_msg = try std.fmt.bufPrint(&buf, "frame: {d}/{d}", .{ state.cursor, state.events.len });
    screen.drawString(2, 8, frame_msg);

    try screen.present(state.stdout.*);
}
