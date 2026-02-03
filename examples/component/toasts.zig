const std = @import("std");
const posix = std.posix;
const zettui = @import("zettui");
const animator = zettui.animation;

const NotificationType = enum {
    success,
    @"error",
    warning,
    info,

    fn color(self: NotificationType) u24 {
        return switch (self) {
            .success => 0x22C55E,
            .@"error" => 0xEF4444,
            .warning => 0xF59E0B,
            .info => 0x3B82F6,
        };
    }

    fn icon(self: NotificationType) []const u8 {
        return switch (self) {
            .success => "[+]",
            .@"error" => "[!]",
            .warning => "[*]",
            .info => "[i]",
        };
    }

    fn label(self: NotificationType) []const u8 {
        return switch (self) {
            .success => "SUCCESS",
            .@"error" => "ERROR",
            .warning => "WARNING",
            .info => "INFO",
        };
    }
};

const ToastState = enum { entering, visible, exiting, done };

const Toast = struct {
    message: []const u8,
    ntype: NotificationType,
    slide_anim: animator.Animator,
    dismiss_anim: animator.Animator,
    hold_elapsed: f32 = 0,
    hold_duration: f32 = 3.0,
    state: ToastState = .entering,

    fn init(message: []const u8, ntype: NotificationType) Toast {
        return Toast{
            .message = message,
            .ntype = ntype,
            .slide_anim = .{ .duration = 0.3 },
            .dismiss_anim = .{ .duration = 0.2 },
        };
    }

    fn update(self: *Toast, delta: f32) void {
        switch (self.state) {
            .entering => {
                self.slide_anim.advance(delta);
                if (!self.slide_anim.isActive()) {
                    self.state = .visible;
                }
            },
            .visible => {
                self.hold_elapsed += delta;
                if (self.hold_elapsed >= self.hold_duration) {
                    self.state = .exiting;
                }
            },
            .exiting => {
                self.dismiss_anim.advance(delta);
                if (!self.dismiss_anim.isActive()) {
                    self.state = .done;
                }
            },
            .done => {},
        }
    }

    fn slideOffset(self: Toast, toast_width: usize) i32 {
        const tw = @as(i32, @intCast(toast_width));
        return switch (self.state) {
            .entering => blk: {
                const progress = self.slide_anim.value(animator.easeOutBack);
                break :blk tw - @as(i32, @intFromFloat(@as(f32, @floatFromInt(tw)) * progress));
            },
            .visible => 0,
            .exiting => blk: {
                const progress = self.dismiss_anim.value(animator.easeInOutQuad);
                break :blk @as(i32, @intFromFloat(@as(f32, @floatFromInt(tw)) * progress));
            },
            .done => tw,
        };
    }
};

const State = struct {
    toasts: std.ArrayListUnmanaged(Toast) = .{},
    allocator: std.mem.Allocator,
    stdout: *std.fs.File,
    stdin_fd: posix.fd_t,
    running: bool = true,
    msg_index: usize = 0,
    last_time_ns: i128,
};

const success_msgs = [_][]const u8{ "Changes saved!", "Upload complete", "Connection established" };
const error_msgs = [_][]const u8{ "Connection failed", "Invalid input", "Server error" };
const warning_msgs = [_][]const u8{ "Low disk space", "Session expiring", "Rate limit near" };
const info_msgs = [_][]const u8{ "New update available", "3 new messages", "Sync in progress" };

const SCREEN_WIDTH: usize = 60;
const SCREEN_HEIGHT: usize = 20;
const TOAST_WIDTH: usize = 30;
const TOAST_HEIGHT: usize = 3;
const MAX_TOASTS: usize = 5;
const FRAME_MS: i32 = 16;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var stdout = std.fs.File.stdout();
    const stdin_fd = posix.STDIN_FILENO;

    const token = try enableRawMode(stdin_fd);
    defer disableRawMode(stdin_fd, token);

    try stdout.writeAll("\x1b[?25l");
    try stdout.writeAll("\x1b[2J");
    defer stdout.writeAll("\x1b[?25h") catch {};
    defer stdout.writeAll("\x1b[2J\x1b[H") catch {};

    var state = State{
        .allocator = allocator,
        .stdout = &stdout,
        .stdin_fd = stdin_fd,
        .last_time_ns = std.time.nanoTimestamp(),
    };
    defer state.toasts.deinit(allocator);

    var interactive = try zettui.screen.ScreenInteractive.init(allocator, SCREEN_WIDTH, SCREEN_HEIGHT);
    defer interactive.deinit();

    var loop = interactive.customLoop(fetch, handle, @ptrCast(&state));
    try loop.run();
}

fn fetch(_: *zettui.screen.ScreenInteractive, ctx: ?*anyopaque) anyerror!?zettui.screen.LoopEvent {
    const state: *State = @ptrCast(@alignCast(ctx.?));
    if (!state.running) return null;

    // Poll stdin with frame timeout
    var fds = [_]posix.pollfd{
        .{ .fd = state.stdin_fd, .events = posix.POLL.IN, .revents = 0 },
    };
    _ = posix.poll(&fds, FRAME_MS) catch 0;

    // Check for input
    if (fds[0].revents & posix.POLL.IN != 0) {
        var buf: [1]u8 = undefined;
        const n = posix.read(state.stdin_fd, &buf) catch 0;
        if (n > 0) {
            return .{ .input = .{ .key = .{ .codepoint = buf[0] } } };
        }
    }

    // Return tick event for animation update
    const now = std.time.nanoTimestamp();
    const delta_ns = now - state.last_time_ns;
    state.last_time_ns = now;
    return .{ .tick = .{ .delta_ns = @intCast(@max(0, delta_ns)) } };
}

fn handle(interactive: *zettui.screen.ScreenInteractive, event: zettui.screen.LoopEvent, ctx: ?*anyopaque) anyerror!bool {
    const state: *State = @ptrCast(@alignCast(ctx.?));

    switch (event) {
        .input => |input| {
            switch (input) {
                .key => |key| {
                    if (key.codepoint) |cp| {
                        const ch: u8 = @truncate(cp);
                        switch (ch) {
                            'q' => {
                                state.running = false;
                                return false;
                            },
                            's' => spawnToast(state, .success, success_msgs[state.msg_index % success_msgs.len]),
                            'e' => spawnToast(state, .@"error", error_msgs[state.msg_index % error_msgs.len]),
                            'w' => spawnToast(state, .warning, warning_msgs[state.msg_index % warning_msgs.len]),
                            'i' => spawnToast(state, .info, info_msgs[state.msg_index % info_msgs.len]),
                            else => {},
                        }
                        if (ch == 's' or ch == 'e' or ch == 'w' or ch == 'i') {
                            state.msg_index +%= 1;
                        }
                    }
                },
                else => {},
            }
        },
        .tick => |tick| {
            const delta_s: f32 = @as(f32, @floatFromInt(tick.delta_ns)) / @as(f32, @floatFromInt(std.time.ns_per_s));
            for (state.toasts.items) |*toast| {
                toast.update(delta_s);
            }

            // Remove done toasts
            var i: usize = 0;
            while (i < state.toasts.items.len) {
                if (state.toasts.items[i].state == .done) {
                    _ = state.toasts.orderedRemove(i);
                } else {
                    i += 1;
                }
            }
        },
        else => {},
    }

    try render(interactive, state);
    return state.running;
}

fn spawnToast(state: *State, ntype: NotificationType, message: []const u8) void {
    if (state.toasts.items.len >= MAX_TOASTS) {
        _ = state.toasts.orderedRemove(0);
    }
    state.toasts.append(state.allocator, Toast.init(message, ntype)) catch {};
}

fn render(interactive: *zettui.screen.ScreenInteractive, state: *State) !void {
    var screen = interactive.screen();
    screen.clear(.{ .glyph = " ", .fg = 0xE5E7EB, .bg = 0x111827 });

    screen.drawStyledString(2, 1, "Toast Notification Demo", .{ .fg = 0xF9FAFB, .bg = 0x111827, .style = .{ .bold = true } });
    screen.drawString(2, 3, "Keys: [s]uccess [e]rror [w]arning [i]nfo [q]uit");

    var buf: [64]u8 = undefined;
    const count_msg = std.fmt.bufPrint(&buf, "Active toasts: {d}/{d}", .{ state.toasts.items.len, MAX_TOASTS }) catch "?";
    screen.drawString(2, 5, count_msg);

    const base_y: i32 = @as(i32, @intCast(SCREEN_HEIGHT)) - @as(i32, @intCast(TOAST_HEIGHT)) - 1;
    for (state.toasts.items, 0..) |toast, idx| {
        const stack_offset = @as(i32, @intCast(idx)) * @as(i32, @intCast(TOAST_HEIGHT + 1));
        const y = base_y - stack_offset;
        if (y < 0) continue;

        const x_offset = toast.slideOffset(TOAST_WIDTH);
        const x = @as(i32, @intCast(SCREEN_WIDTH)) - @as(i32, @intCast(TOAST_WIDTH)) + x_offset;
        if (x >= @as(i32, @intCast(SCREEN_WIDTH))) continue;

        drawToast(screen, toast, x, y);
    }

    try state.stdout.writeAll("\x1b[H");
    try screen.present(state.stdout.*);
}

fn drawToast(screen: *zettui.screen.Screen, toast: Toast, x: i32, y: i32) void {
    const color = toast.ntype.color();
    const ux: usize = if (x < 0) 0 else @as(usize, @intCast(x));
    const uy: usize = @as(usize, @intCast(y));

    const top_border = "+" ++ ("-" ** (TOAST_WIDTH - 2)) ++ "+";
    const bottom_border = top_border;

    if (uy < SCREEN_HEIGHT) {
        drawClipped(screen, ux, uy, top_border, color);
    }

    if (uy + 1 < SCREEN_HEIGHT) {
        var line_buf: [TOAST_WIDTH]u8 = undefined;
        @memset(&line_buf, ' ');
        line_buf[0] = '|';
        line_buf[TOAST_WIDTH - 1] = '|';

        const icon_str = toast.ntype.icon();
        const label_str = toast.ntype.label();
        const content_start: usize = 2;
        @memcpy(line_buf[content_start .. content_start + icon_str.len], icon_str);
        @memcpy(line_buf[content_start + icon_str.len + 1 .. content_start + icon_str.len + 1 + label_str.len], label_str);

        drawClipped(screen, ux, uy + 1, &line_buf, color);
    }

    if (uy + 2 < SCREEN_HEIGHT) {
        var msg_buf: [TOAST_WIDTH]u8 = undefined;
        @memset(&msg_buf, ' ');
        msg_buf[0] = '|';
        msg_buf[TOAST_WIDTH - 1] = '|';

        const msg_max = TOAST_WIDTH - 4;
        const msg_len = @min(toast.message.len, msg_max);
        @memcpy(msg_buf[2 .. 2 + msg_len], toast.message[0..msg_len]);

        drawClipped(screen, ux, uy + 2, &msg_buf, color);
    }

    if (uy + 3 < SCREEN_HEIGHT) {
        drawClipped(screen, ux, uy + 3, bottom_border, color);
    }
}

fn drawClipped(screen: *zettui.screen.Screen, x: usize, y: usize, text: []const u8, fg: u24) void {
    if (x >= SCREEN_WIDTH or y >= SCREEN_HEIGHT) return;
    const max_len = SCREEN_WIDTH - x;
    const draw_len = @min(text.len, max_len);
    screen.drawStyledString(x, y, text[0..draw_len], .{ .fg = fg, .bg = 0x1F2937 });
}

fn enableRawMode(fd: posix.fd_t) !posix.termios {
    const term = try posix.tcgetattr(fd);
    var raw = term;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    raw.cc[@intFromEnum(std.posix.V.MIN)] = 0;
    raw.cc[@intFromEnum(std.posix.V.TIME)] = 0;
    try posix.tcsetattr(fd, .NOW, raw);
    return term;
}

fn disableRawMode(fd: posix.fd_t, token: posix.termios) void {
    posix.tcsetattr(fd, .NOW, token) catch {};
}
