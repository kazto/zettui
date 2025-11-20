const std = @import("std");

pub const WideString = []const u16;

/// Convert a wide (UTF-16-like) string to UTF-8. Only BMP code points are supported;
/// surrogate pairs are treated as separate code units to keep the implementation small.
pub fn wideToUtf8(allocator: std.mem.Allocator, input: WideString) ![]u8 {
    var list = std.ArrayList(u8).init(allocator);
    errdefer list.deinit();
    for (input) |cp16| {
        const cp32: u21 = @as(u21, cp16);
        try list.appendSlice(std.unicode.utf8Encode(cp32) catch |err| {
            _ = err;
            // fallback: replace invalid code unit with '?'
            return try allocator.dupe(u8, "?");
        });
    }
    return list.toOwnedSlice();
}

/// Convert UTF-8 to a zero-terminated wide buffer suitable for platform interop.
pub fn utf8ToWideZ(allocator: std.mem.Allocator, input: []const u8) ![:0]u16 {
    var iter = std.unicode.Utf8Iterator{ .bytes = input, .i = 0 };
    var buf = std.ArrayList(u16).init(allocator);
    errdefer buf.deinit();
    while (iter.nextCodepoint()) |cp| {
        // clamp to BMP for simplicity
        const clamped: u21 = @min(cp, @as(u21, 0xFFFF));
        try buf.append(@intCast(clamped));
    }
    try buf.append(0);
    const slice = try buf.toOwnedSlice();
    return slice[0 .. slice.len - 1 :0];
}

test "wideToUtf8 round-trips simple ASCII" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const wide: []const u16 = &[_]u16{ 'Z', 'i', 'g' };
    const utf8 = try wideToUtf8(arena.allocator(), wide);
    try std.testing.expectEqualStrings("Zig", utf8);
}

test "utf8ToWideZ appends terminator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const wide_z = try utf8ToWideZ(arena.allocator(), "hi");
    try std.testing.expectEqual(@as(u16, 'h'), wide_z[0]);
    try std.testing.expectEqual(@as(u16, 0), wide_z[wide_z.len]);
}
