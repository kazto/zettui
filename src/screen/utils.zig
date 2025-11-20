const std = @import("std");

pub fn AutoReset(comptime T: type) type {
    return struct {
        original: T,
        value: T,

        pub fn init(v: T) AutoReset(T) {
            return .{ .original = v, .value = v };
        }

        pub fn reset(self: *AutoReset(T)) void {
            self.value = self.original;
        }

        pub fn set(self: *AutoReset(T), v: T) void {
            self.value = v;
        }

        pub fn deinit(self: *AutoReset(T)) void {
            self.reset();
        }
    };
}

pub const Ref = struct {
    ptr: *anyopaque,

    pub fn of(comptime T: type, value: *T) Ref {
        return .{ .ptr = value };
    }

    pub fn get(self: Ref, comptime T: type) *T {
        return @ptrCast(@alignCast(self.ptr));
    }
};

pub const ConstRef = struct {
    ptr: *const anyopaque,

    pub fn of(comptime T: type, value: *const T) ConstRef {
        return .{ .ptr = value };
    }

    pub fn get(self: ConstRef, comptime T: type) *const T {
        return @ptrCast(@alignCast(self.ptr));
    }
};

pub const ConstStringRef = struct {
    value: []const u8,
};

pub const ConstStringListRef = struct {
    items: [][]const u8,
};

pub fn Receiver(comptime T: type) type {
    return struct {
        allocator: std.mem.Allocator,
        queue: std.ArrayList(T),

        pub fn init(allocator: std.mem.Allocator) Receiver(T) {
            return .{ .allocator = allocator, .queue = std.ArrayList(T).init(allocator) };
        }

        pub fn deinit(self: *Receiver(T)) void {
            self.queue.deinit();
        }

        pub fn recv(self: *Receiver(T)) ?T {
            if (self.queue.items.len == 0) return null;
            return self.queue.orderedRemove(0);
        }
    };
}

pub fn Sender(comptime T: type) type {
    return struct {
        receiver: *Receiver(T),

        pub fn send(self: Sender(T), value: T) !void {
            try self.receiver.queue.append(value);
        }
    };
}

pub const WindowsGuard = struct {
    pub fn isWindows() bool {
        return std.builtin.target.os.tag == .windows;
    }
};

test "AutoReset resets to original" {
    var ar = AutoReset(i32).init(5);
    ar.set(10);
    ar.deinit();
    try std.testing.expectEqual(@as(i32, 5), ar.value);
}

test "Ref and ConstRef round trip" {
    var x: i32 = 42;
    const r = Ref.of(i32, &x);
    try std.testing.expectEqual(@as(i32, 42), r.get(i32).*);
    const cr = ConstRef.of(i32, &x);
    try std.testing.expectEqual(@as(i32, 42), cr.get(i32).*);
}

test "Receiver/Sender transfers item" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var rx = Receiver(u8).init(arena.allocator());
    defer rx.deinit();
    const tx = Sender(u8){ .receiver = &rx };
    try tx.send(7);
    try std.testing.expectEqual(@as(u8, 7), rx.recv().?);
    try std.testing.expectEqual(@as(?u8, null), rx.recv());
}

test "WindowsGuard queries target" {
    _ = WindowsGuard.isWindows();
}
