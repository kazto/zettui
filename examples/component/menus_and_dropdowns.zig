const std = @import("std");
const zettui = @import("zettui");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();

    var stdout = std.fs.File.stdout();
    try renderHeading(&stdout, a, "=== Component: Menus & Dropdowns ===", .{ .bold = true, .fg = 0x3B82F6 });
    try stdout.writeAll("\n");
    try renderMenuGallery(&stdout, a);
    try stdout.writeAll("\n");
    try renderMultiSelectMenu(&stdout, a);
    try stdout.writeAll("\n");
    try renderDropdowns(&stdout, a);
}

fn renderMenuGallery(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Animated menu with underline gallery --", .{ .fg = 0xF97316 });
    const labels = [_][]const u8{ "Home", "Graphs", "Tables", "Settings" };
    const menu_component = try zettui.component.widgets.menu(allocator, .{
        .items = &labels,
        .selected_index = 1,
        .underline_gallery = true,
        .highlight_color = 0xF97316,
        .animation_enabled = true,
    });
    try menu_component.render();
    try stdout.writeAll("\n");

    try renderHeading(stdout, allocator, "-- Custom rendered menu --", .{ .fg = 0x34D399 });
    const custom_menu = try zettui.component.widgets.menuCustom(allocator, .{
        .items = &labels,
        .selected_index = 2,
    }, menuCustomRenderer);
    try custom_menu.render();
    try stdout.writeAll("\n");
}

fn renderMultiSelectMenu(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Multi-select menu --", .{ .fg = 0xA855F7 });
    const entries = [_][]const u8{ "alpha", "beta", "gamma", "delta" };
    const flags = [_]bool{ true, false, true, false };
    const menu_component = try zettui.component.widgets.menu(allocator, .{
        .items = &entries,
        .selected_index = 0,
        .multi_select = true,
        .selected_flags = &flags,
        .highlight_color = 0xA855F7,
    });
    try menu_component.render();
    try stdout.writeAll("\n");
}

fn renderDropdowns(stdout: *std.fs.File, allocator: std.mem.Allocator) !void {
    try renderHeading(stdout, allocator, "-- Dropdowns --", .{ .fg = 0xFCD34D });
    const options = [_][]const u8{ "Debug", "ReleaseFast", "ReleaseSafe" };
    const dropdown_component = try zettui.component.widgets.dropdown(allocator, .{
        .items = &options,
        .selected_index = 1,
        .placeholder = "Select profile",
        .is_open = true,
    });
    try dropdown_component.render();
    try stdout.writeAll("\n");

    try renderHeading(stdout, allocator, "-- Custom dropdown renderer --", .{ .fg = 0xEC4899 });
    const custom_dropdown = try zettui.component.widgets.dropdownCustom(allocator, .{
        .items = &options,
        .selected_index = 0,
        .placeholder = "choose..",
        .is_open = true,
    }, dropdownCustomRenderer);
    try custom_dropdown.render();
    try stdout.writeAll("\n");
}

fn menuCustomRenderer(payload: zettui.component.options.MenuRenderPayload) anyerror!void {
    var stdout = std.fs.File.stdout();
    try stdout.writeAll("[custom menu]\n");
    for (payload.items, 0..) |item, idx| {
        const mark = if (idx == payload.selected_index) ">>" else "  ";
        const underline_char: u8 = if (payload.underline_gallery) '=' else '-';
        var buf: [96]u8 = undefined;
        const line = try std.fmt.bufPrint(&buf, "{s} {s}\n", .{ mark, item });
        try stdout.writeAll(line);
        if (payload.underline_gallery) {
            try stdout.writeAll("   ");
            try writeRepeating(&stdout, underline_char, item.len);
            try stdout.writeAll("\n");
        }
    }
}

fn dropdownCustomRenderer(payload: zettui.component.options.DropdownRenderPayload) anyerror!void {
    var stdout = std.fs.File.stdout();
    const label = if (payload.selected_index) |idx| payload.items[idx] else payload.placeholder;
    var buf: [128]u8 = undefined;
    const line = try std.fmt.bufPrint(&buf, "[custom dropdown] {s} {s}\n", .{ if (payload.is_open) "(open)" else "(closed)", label });
    try stdout.writeAll(line);
}

fn writeRepeating(stdout: *std.fs.File, ch: u8, count: usize) anyerror!void {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        try stdout.writeAll(&[_]u8{ch});
    }
}

fn renderHeading(stdout: *std.fs.File, allocator: std.mem.Allocator, text: []const u8, attrs: zettui.dom.StyleAttributes) !void {
    const SinkWriter = struct {
        fn write(user_data: *anyopaque, bytes: []const u8) anyerror!void {
            const file = @as(*std.fs.File, @ptrCast(@alignCast(user_data)));
            try file.writeAll(bytes);
        }
    };
    var ctx: zettui.dom.RenderContext = .{
        .sink = .{ .user_data = @as(*anyopaque, @ptrCast(stdout)), .writeAll = SinkWriter.write },
    };
    const node = try zettui.dom.elements.styleOwned(allocator, zettui.dom.elements.text(text), attrs);
    try node.render(&ctx);
    try stdout.writeAll("\n");
}
