const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout_file = std.fs.File.stdout();
    try stdout_file.writeAll("=== DOM Typography, Styles, and Colors ===\n\n");

    var ctx = makeContext(&stdout_file, a);
    try renderTypography(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderColors(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderPalette256(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderPalette2D(&ctx, &stdout_file, a);
    try stdout_file.writeAll("\n");
    try renderGradients(&ctx, &stdout_file);
    try stdout_file.writeAll("\n");
    try renderHsvBand(&ctx, &stdout_file, a);
}

fn renderTypography(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Typography --\n");
    const samples = [_]struct {
        label: []const u8,
        attrs: zettui.dom.StyleAttributes,
    }{
        .{ .label = "Bold emphasis", .attrs = .{ .bold = true } },
        .{ .label = "Italic emphasis", .attrs = .{ .italic = true } },
        .{ .label = "Single underline", .attrs = .{ .underline = true } },
        .{ .label = "Double underline", .attrs = .{ .underline_double = true } },
        .{ .label = "Strike through", .attrs = .{ .strikethrough = true } },
        .{ .label = "Blinking text", .attrs = .{ .blink = true } },
        .{ .label = "Dim accent", .attrs = .{ .dim = true } },
        .{ .label = "Inverse highlight", .attrs = .{ .inverse = true } },
    };

    for (samples) |sample| {
        const node = try zettui.dom.elements.styleOwned(
            allocator,
            zettui.dom.elements.text(sample.label),
            sample.attrs,
        );
        try node.render(ctx);
        try stdout.writeAll("\n");
    }
}

fn renderColors(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Palette / True color --\n");
    const palette_samples = [_]struct {
        label: []const u8,
        attrs: zettui.dom.StyleAttributes,
    }{
        .{ .label = "Palette: bright red", .attrs = .{ .fg_palette = .bright_red } },
        .{ .label = "Palette: bright cyan", .attrs = .{ .fg_palette = .bright_cyan } },
        .{ .label = "Palette background", .attrs = .{ .bg_palette = .bright_black, .fg_palette = .bright_white } },
        .{ .label = "True color lavender", .attrs = .{ .fg = 0xA855F7 } },
        .{ .label = "True color sunset on charcoal", .attrs = .{ .fg = 0xF97316, .bg = 0x1F2933 } },
    };
    for (palette_samples) |sample| {
        const node = try zettui.dom.elements.styleOwned(
            allocator,
            zettui.dom.elements.text(sample.label),
            sample.attrs,
        );
        try node.render(ctx);
        try stdout.writeAll("\n");
    }

    try stdout.writeAll("\n-- Paragraph with underline --\n");
    const paragraph_node = try zettui.dom.elements.styleOwned(
        allocator,
        zettui.dom.elements.paragraph(
            "Paragraph nodes wrap text to the requested width and inherit typography styles. Use this to showcase underline and other decorations.",
            48,
        ),
        .{ .underline = true },
    );
    try paragraph_node.render(ctx);
    try stdout.writeAll("\n");
}

fn renderPalette256(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- 256-color table (xterm mapping) --\n");
    var idx: usize = 0;
    while (idx < 256) {
        var col: usize = 0;
        while (col < 16 and idx < 256) {
            const bg_color = xtermColor(idx);
            const fg_color = readableFg(bg_color);
            var buf: [8]u8 = undefined;
            const label = try std.fmt.bufPrint(&buf, "{d:0>3}", .{idx});
            const cell = try zettui.dom.elements.styleOwned(
                allocator,
                zettui.dom.elements.text(label),
                .{ .bg = bg_color, .fg = fg_color },
            );
            try cell.render(ctx);
            try stdout.writeAll(" ");
            idx += 1;
            col += 1;
        }
        try stdout.writeAll("\n");
    }
}

fn renderPalette2D(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- Color cube (6x6x6) laid out by green rows --\n");
    const steps = [_]u8{ 0, 1, 2, 3, 4, 5 };
    for (steps) |g| {
        var buf: [32]u8 = undefined;
        const label = try std.fmt.bufPrint(&buf, "G{d} ", .{g});
        try stdout.writeAll(label);
        for (steps) |r| {
            for (steps) |b| {
                const index = 16 + (@as(usize, r) * 36) + (@as(usize, g) * 6) + @as(usize, b);
                const bg_color = xtermColor(index);
                const fg_color = readableFg(bg_color);
                const cell = try zettui.dom.elements.styleOwned(
                    allocator,
                    zettui.dom.elements.text("  "),
                    .{ .bg = bg_color, .fg = fg_color },
                );
                try cell.render(ctx);
            }
            try stdout.writeAll(" ");
        }
        try stdout.writeAll("\n");
    }
}

fn renderGradients(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File) !void {
    try stdout.writeAll("-- Linear gradients --\n");
    const gradient = zettui.dom.elements.linearGradient("Linear gradient sample", 0xF97316, 0x7C3AED);
    try gradient.render(ctx);
    try stdout.writeAll("\n");
}

fn renderHsvBand(ctx: *zettui.dom.RenderContext, stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try stdout.writeAll("-- True color HSV sweep --\n");
    var i: usize = 0;
    while (i < 36) : (i += 1) {
        const hue = @as(f32, @floatFromInt(i)) * (360.0 / 36.0);
        const color = hsvToRgb(hue, 0.85, 1.0);
        const swatch = try zettui.dom.elements.styleOwned(
            allocator,
            zettui.dom.elements.text("██"),
            .{ .bg = color, .fg = readableFg(color) },
        );
        try swatch.render(ctx);
    }
    try stdout.writeAll("\n");
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

fn xtermColor(index: usize) u24 {
    const base = [_]u24{
        0x000000, 0x800000, 0x008000, 0x808000, 0x000080, 0x800080, 0x008080, 0xC0C0C0,
        0x808080, 0xFF0000, 0x00FF00, 0xFFFF00, 0x0000FF, 0xFF00FF, 0x00FFFF, 0xFFFFFF,
    };
    if (index < base.len) return base[index];
    if (index < 232) {
        const cube = [_]u8{ 0, 95, 135, 175, 215, 255 };
        const idx = index - 16;
        const r = cube[idx / 36];
        const g = cube[(idx / 6) % 6];
        const b = cube[idx % 6];
        return (@as(u24, r) << 16) | (@as(u24, g) << 8) | b;
    }
    const gray = @as(u8, @intCast(8 + 10 * @as(isize, @intCast(index - 232))));
    return (@as(u24, gray) << 16) | (@as(u24, gray) << 8) | gray;
}

fn readableFg(bg: u24) u24 {
    const r = (bg >> 16) & 0xFF;
    const g = (bg >> 8) & 0xFF;
    const b = bg & 0xFF;
    const luminance = (r * 3 + g * 6 + b) / 10;
    return if (luminance > 140) 0x111827 else 0xF8FAFC;
}

fn hsvToRgb(h: f32, s: f32, v: f32) u24 {
    const hh = (h - 360.0 * std.math.floor(h / 360.0)) / 60.0;
    const i = @as(u8, @intFromFloat(std.math.floor(hh)));
    const ff = hh - @as(f32, @floatFromInt(i));
    const p = v * (1.0 - s);
    const q = v * (1.0 - (s * ff));
    const t = v * (1.0 - (s * (1.0 - ff)));
    var r: f32 = undefined;
    var g: f32 = undefined;
    var b: f32 = undefined;
    switch (i) {
        0 => {
            r = v;
            g = t;
            b = p;
        },
        1 => {
            r = q;
            g = v;
            b = p;
        },
        2 => {
            r = p;
            g = v;
            b = t;
        },
        3 => {
            r = p;
            g = q;
            b = v;
        },
        4 => {
            r = t;
            g = p;
            b = v;
        },
        else => {
            r = v;
            g = p;
            b = q;
        },
    }
    const rr: u8 = @intFromFloat(std.math.clamp(r * 255.0, 0.0, 255.0));
    const gg: u8 = @intFromFloat(std.math.clamp(g * 255.0, 0.0, 255.0));
    const bb: u8 = @intFromFloat(std.math.clamp(b * 255.0, 0.0, 255.0));
    return (@as(u24, rr) << 16) | (@as(u24, gg) << 8) | bb;
}
