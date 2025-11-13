const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var paths = std.ArrayList([]const u8).init(allocator);
    defer paths.deinit();
    try paths.appendSlice(&[_][]const u8{
        "src",
        "examples",
        "docs",
        "build.zig",
    });

    var command = std.ArrayList([]const u8).init(allocator);
    defer command.deinit();
    try command.appendSlice(&[_][]const u8{
        "zig",
        "fmt",
        "--check",
        "--color",
        "auto",
    });
    try command.appendSlice(paths.items);

    var child = std.process.Child.init(command.items, allocator);
    child.stdin_behavior = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;
    const term = try child.spawnAndWait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                std.log.err("formatting issues detected (exit code {d})", .{code});
                return error.FormattingIssues;
            }
        },
        else => {
            return error.LintAborted;
        },
    }
}
