const std = @import("std");

// Boilerplate reducing object construction / deconstruction interface via dynamic function creation

/// Create function that will allocate given T type with given allocator and call 'init' over it with arbitrary argument parameter
pub fn autoAlloc(comptime T: type) fn (std.mem.Allocator, anytype) anyerror!*T {
    return struct {
        fn alloc(allocator: std.mem.Allocator, args: anytype) anyerror!*T {
            var self = try allocator.create(T);
            errdefer allocator.destroy(self);
            try self.init(args);
            return self;
        }
    }.alloc;
}

/// Create function that will allocate given T type on stack and call 'init' over it with arbitrary argument parameter
pub fn autoCreate(comptime T: type) fn (anytype) callconv(.Inline) anyerror!T {
    return struct {
        inline fn create(args: anytype) anyerror!T {
            var self = std.mem.zeroes(T);
            try (&self).init(args);
            return self;
        }
    }.create;
}

/// Create function that will call 'deinit' and then deallocate object with given allocator
pub fn autoDestroy(comptime T: type) fn (*T, std.mem.Allocator) void {
    return struct {
        fn destroy(self: *T, allocator: std.mem.Allocator) void {
            self.deinit();
            allocator.destroy(self);
        }
    }.destroy;
}

test "stack" {
    const expect = std.testing.expect;

    const MyObj = struct {
        value: u32,

        const Self = @This();

        pub const create = autoCreate(Self);
        pub const destroy = autoDestroy(Self);

        fn init(self: *Self, args: anytype) !void {
            self.value = args.@"0";
        }

        fn deinit(self: *Self) void {
            _ = self;
        }
    };

    var obj = try MyObj.create(.{123});
    try expect(obj.value == 123);
}

test "heap" {
    const expect = std.testing.expect;

    const MyObj = struct {
        value: u32,

        const Self = @This();

        pub const alloc = autoAlloc(Self);
        pub const destroy = autoDestroy(Self);

        fn init(self: *Self, args: anytype) !void {
            self.value = args.@"0";
        }

        fn deinit(self: *Self) void {
            _ = self;
        }
    };

    var buffer: [100]u8 = undefined;
    const allocator = std.heap.FixedBufferAllocator.init(&buffer).allocator();
    var obj = try MyObj.alloc(allocator, .{123});
    try expect(obj.value == 123);
    obj.destroy(allocator);
}
