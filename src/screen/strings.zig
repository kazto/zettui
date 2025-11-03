const std = @import("std");

pub fn utf8Width(text: []const u8) usize {
    var iter = std.unicode.Utf8Iterator.init(text);
    var count: usize = 0;
    while (iter.nextCodepoint()) |_| {
        count += 1;
    }
    return count;
}

pub fn splitGraphemes(allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    errdefer list.deinit();

    var index: usize = 0;
    while (index < text.len) : (index += 1) {
        const next = index + 1;
        try list.append(text[index..next]);
    }
    return try list.toOwnedSlice();
}
