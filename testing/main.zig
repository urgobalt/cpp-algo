const std = @import("std");
const tracking = @import("track.zig");
comptime {
    _ = tracking;
}
pub const c = @cImport({
    @cInclude("testing");
});
const TestingError = error{
    NULL_PTR,
    EMPTY,
    ALLOC,
    INVALID_HANDLE,

    OTHER,
};

fn intToTestingAccessError(err_code: c_int) TestingError {
    switch (err_code) {
        c.adt_RESULT_ERROR_NULL_PTR => return error.NULL_PTR,
        c.adt_RESULT_ERROR_EMPTY => return error.EMPTY,
        c.adt_RESULT_ERROR_ALLOC => return error.ALLOC,
        c.adt_RESULT_ERROR_OTHER => return error.OTHER,
        c.adt_RESULT_ERROR_INVALID_HANDLE => return error.INVALID_HANDLE,
        else => return error.OTHER,
    }
}
fn TestingAccessErrorToInt(err_code: TestingError) c_int {
    switch (err_code) {
        error.NULL_PTR => return c.adt_RESULT_ERROR_NULL_PTR,
        error.EMPTY => return c.adt_RESULT_ERROR_EMPTY,
        error.ALLOC => return c.adt_RESULT_ERROR_ALLOC,
        error.OTHER => return c.adt_RESULT_ERROR_OTHER,
        error.INVALID_HANDLE => return c.adt_RESULT_ERROR_INVALID_HANDLE,
    }
}
const TrackingObject = struct {
    backing: c.TrackedItemHandle,
    fn init(value: i32, order: i32) !TrackingObject {
        var handle: c.TrackedItemHandle = null;
        const a = c.create_value(@intCast(value), @intCast(order), &handle);
        if (a != c.adt_RESULT_SUCCESS) {
            return intToTestingAccessError(a);
        }
        return TrackingObject{ .backing = handle };
    }

    fn deinit(self: @This()) void {
        const a = c.destroy_tracked_item(self.backing);
        if (a != c.adt_RESULT_SUCCESS) {
            return intToTestingAccessError(a);
        }
    }
};
const ADT = struct {
    int_adt: c.ADTHandle,
    ops: *c.adtOperations,
    fn deinit(self: @This()) !void {
        const a: c.testingResultCode = self.ops.destroy.?(self.int_adt);
        if (a != c.adt_RESULT_SUCCESS) {
            return intToTestingAccessError(a);
        }
    }
    fn insert(self: @This(), t: TrackingObject) !void {
        const a = self.ops.insert.?(self.int_adt, t.backing.?.*);
        if (a != c.adt_RESULT_SUCCESS) {
            return intToTestingAccessError(a);
        }
    }
    fn peek(self: @This()) !TrackingObject {
        var adt = null;
        const a: c.testingResultCode = self.ops.peek.?(self.int_adt, &adt);
        if (a != c.adt_RESULT_SUCCESS) {
            return intToTestingAccessError(a);
        }
        return TrackingObject{ .backing = adt };
    }
    fn remove(self: @This()) !TrackingObject {
        var adt: c.TrackedItemHandle = null;
        const a = self.ops.remove.?(self.int_adt, &adt);
        if (a != c.adt_RESULT_SUCCESS) {
            return intToTestingAccessError(a);
        }
        return TrackingObject{ .backing = adt };
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
        if (a != c.adt_RESULT_SUCCESS) {
            return intToTestingAccessError(a);
        }
        return ADT{ .int_adt = adt, .ops = self.ops };
    }
};
fn assert_eq(new_value: c_int, old_value: c_int) void {
    if (new_value != old_value) {
        std.debug.print("invalid value, expected:{}, got {}", .{ new_value, old_value });
    }
}
export fn test_adt(s: *c.adtOperations) c_int {
    const adtBuilder = ADTBuilder.init(s);
    internal_test_adt(adtBuilder) catch |err| {
        return TestingAccessErrorToInt(err);
    };
    return c.adt_RESULT_SUCCESS;
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
