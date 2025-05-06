const std = @import("std");
const tracking = @import("track.zig");

comptime {
    _ = tracking;
}

pub const c = @cImport({
    @cInclude("testing");
});

const TestingError = error{
    nullPtr,
    empty,
    alloc,
    invalidHandle,
    other,
};

inline fn asTestingError(code: c_int) TestingError!void {
    if (code == c.ADT_RESULT_SUCCESS) return;
    return intToTestingError(code);
}

inline fn intToTestingError(code: c_int) TestingError {
    return switch (code) {
        c.ADT_RESULT_ERROR_NULL_PTR => TestingError.nullPtr,
        c.ADT_RESULT_ERROR_EMPTY => TestingError.empty,
        c.ADT_RESULT_ERROR_ALLOC => TestingError.alloc,
        c.ADT_RESULT_ERROR_INVALID_HANDLE => TestingError.invalidHandle,
        else => TestingError.other,
    };
}

inline fn unwrapTesting(comptime returnType: type, obj: returnType, code: c_int) TestingError!returnType {
    return switch (code) {
        c.ADT_RESULT_SUCCESS => obj,
        else => intToTestingError(code),
    };
}

inline fn testingErrorToInt(@"error": TestingError) c_int {
    return switch (@"error") {
        TestingError.nullPtr => c.ADT_RESULT_ERROR_NULL_PTR,
        TestingError.empty => c.ADT_RESULT_ERROR_EMPTY,
        TestingError.alloc => c.ADT_RESULT_ERROR_ALLOC,
        TestingError.invalidHandle => c.ADT_RESULT_ERROR_INVALID_HANDLE,
        TestingError.other => c.ADT_RESULT_ERROR_OTHER,
    };
}

const TrackingObject = struct {
    backing: c.TrackedItemHandle,
    fn init(value: i32, order: i32) !TrackingObject {
        var handle: c.TrackedItemHandle = null;
        const a = c.create_value(@intCast(value), @intCast(order), &handle);
        return unwrapTesting(TrackingObject, .{ .backing = handle }, a);
    }

    fn deinit(self: @This()) !void {
        const a = c.destroy_tracked_item(self.backing);
        return asTestingError(a);
    }
};

const ADT = struct {
    int_adt: c.ADTHandle,
    ops: *c.adtOperations,
    order: c.InsertionOrder,
    fn deinit(self: @This()) !void {
        const a: c.testingResultCode = self.ops.destroy.?(self.int_adt);
        return asTestingError(a);
    }
    fn insert(self: @This(), t: TrackingObject) !void {
        const a = self.ops.insert.?(self.int_adt, t.backing.?.*);
        return asTestingError(a);
    }
    fn peek(self: @This()) !TrackingObject {
        var adt: c.TrackedItemHandle = null;
        const a: c.testingResultCode = self.ops.peek.?(self.int_adt, &adt);
        return unwrapTesting(TrackingObject, .{ .backing = adt }, a);
    }
    fn remove(self: @This()) !TrackingObject {
        var adt: c.TrackedItemHandle = null;
        const a = self.ops.remove.?(self.int_adt, &adt);
        return unwrapTesting(TrackingObject, .{ .backing = adt }, a);
    }
};

const ADTBuilder = struct {
    ops: *c.adtOperations,

    fn init(input: *c.adtOperations) @This() {
        return ADTBuilder{ .ops = input };
    }
    fn create(self: ADTBuilder) !ADT {
        var adt: c.ADTHandle = null;
        const a = self.ops.create.?(&adt);
        return unwrapTesting(ADT, .{ .int_adt = adt, .ops = self.ops, .order = self.ops.order }, a);
    }
};

fn assert_eq(new_value: c_int, old_value: c_int) void {
    if (new_value != old_value) {
        std.debug.print("invalid value, expected:{}, got {}", .{ new_value, old_value });
    }
}

export fn test_simple_adt(s: *c.adtOperations) c_int {
    const adtBuilder = ADTBuilder.init(s);
    internal_test_adt(adtBuilder) catch |err| {
        return testingErrorToInt(err);
    };
    return c.ADT_RESULT_SUCCESS;
}

fn internal_test_adt(adt_builder: ADTBuilder) !void {
    const adt: ADT = try adt_builder.create();
    const value = 10;
    const order = 1;
    const t = try TrackingObject.init(value, order);
    try adt.insert(t);
    const tn = try adt.remove();
    const new_value = tn.backing.*.value;
    assert_eq(new_value, value);
    const new_order = tn.backing.*.order;
    assert_eq(new_order, order);
    std.debug.print("TADA you have passed the zig tests", .{});
}
