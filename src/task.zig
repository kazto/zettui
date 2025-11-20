const std = @import("std");

pub const TaskFn = *const fn (*Task, std.mem.Allocator) anyerror!void;

pub const Task = struct {
    callback: TaskFn,
    user_data: ?*anyopaque = null,
    completed: bool = false,
};

pub const Scheduler = struct {
    allocator: std.mem.Allocator,
    tasks: std.ArrayListUnmanaged(Task) = .{},

    pub fn init(allocator: std.mem.Allocator) Scheduler {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Scheduler) void {
        self.tasks.deinit(self.allocator);
    }

    pub fn add(self: *Scheduler, task: Task) !void {
        try self.tasks.append(self.allocator, task);
    }

    pub fn run(self: *Scheduler) void {
        var i: usize = 0;
        while (i < self.tasks.items.len) {
            var task = &self.tasks.items[i];
            if (!task.completed) {
                task.callback(task, self.allocator) catch |err| {
                    std.log.err("task failed: {s}", .{@errorName(err)});
                    task.completed = true;
                };
            }
            if (task.completed) {
                _ = self.tasks.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }
};

test "scheduler executes tasks" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var scheduler = Scheduler.init(arena.allocator());
    defer scheduler.deinit();

    var hits: usize = 0;
    const task_fn = struct {
        fn run(task: *Task, _: std.mem.Allocator) anyerror!void {
            const counter = @as(*usize, @ptrCast(@alignCast(task.user_data.?)));
            counter.* += 1;
            task.completed = true;
        }
    };

    try scheduler.add(.{ .callback = task_fn.run, .user_data = @as(*anyopaque, @ptrCast(&hits)) });
    scheduler.run();
    try std.testing.expectEqual(@as(usize, 1), hits);
}
