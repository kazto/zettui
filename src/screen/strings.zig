const std = @import("std");

pub fn utf8Width(text: []const u8) usize {
    var iter = std.unicode.Utf8Iterator{ .bytes = text, .i = 0 };
    var count: usize = 0;
    while (iter.nextCodepoint()) |_| {
        count += 1;
    }
    return count;
}

pub fn splitGraphemes(allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
    var list = std.array_list.Managed([]const u8).init(allocator);
    errdefer list.deinit();

    var index: usize = 0;
    while (index < text.len) : (index += 1) {
        const next = index + 1;
        try list.append(text[index..next]);
    }
    return try list.toOwnedSlice();
}

test "utf8Width counts code points" {
    try std.testing.expectEqual(@as(usize, 4), utf8Width("zet!"));
}

test "splitGraphemes returns slices for each byte" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const graphemes = try splitGraphemes(arena.allocator(), "abc");
    try std.testing.expectEqual(@as(usize, 3), graphemes.len);
    try std.testing.expectEqualStrings("a", graphemes[0]);
    try std.testing.expectEqualStrings("b", graphemes[1]);
    try std.testing.expectEqualStrings("c", graphemes[2]);
}
