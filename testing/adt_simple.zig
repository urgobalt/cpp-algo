const std = @import("std");
const c = @cImport({
    @cInclude("testing");
});
const errors = @import("error.zig");
const tracked_item = @import("tracked_item.zig");

const TrackingObject = tracked_item.TrackingObject;

pub const ADTSimple = struct {
    int_adt: c.ADTHandle,
    ops: *const c.adtOperations,
    pub fn deinit(self: @This()) !void {
        if (self.ops.destroy == null) return errors.FrameworkError.TestLogicError;
        const result_code = self.ops.destroy.?(self.int_adt);
        return errors.asTestingError(result_code);
    }

    pub fn insert(self: @This(), t: TrackingObject) !void {
        if (self.ops.insert == null) return errors.FrameworkError.TestLogicError;
        const result_code = self.ops.insert.?(self.int_adt, t.backing);
        return errors.asTestingError(result_code);
    }

    pub fn peek(self: @This()) !TrackingObject {
        if (self.ops.peek == null) return errors.FrameworkError.TestLogicError;
        var item_handle: c.TrackedItemHandle = null;
        const result_code = self.ops.peek.?(self.int_adt, &item_handle);

        return errors.unwrapTesting(TrackingObject, .{ .backing = item_handle }, result_code);
    }

    pub fn remove(self: @This()) !TrackingObject {
        if (self.ops.remove == null) return errors.FrameworkError.TestLogicError;
        var item_handle: c.TrackedItemHandle = null;
        const result_code = self.ops.remove.?(self.int_adt, &item_handle);

        return errors.unwrapTesting(TrackingObject, .{ .backing = item_handle }, result_code);
    }
};

pub const ADTSimpleBuilder = struct {
    ops: *const c.adtOperations,
    pub fn init(adt_operations: *const c.adtOperations) @This() {
        return ADTSimpleBuilder{ .ops = adt_operations };
    }

    pub fn deinit() void {}
    pub fn create(self: ADTSimpleBuilder) !ADTSimple {
        if (self.ops.create == null) return errors.FrameworkError.TestLogicError;
        var adt_handle: c.ADTHandle = null;
        const result_code = self.ops.create.?(&adt_handle);
        return errors.unwrapTesting(ADTSimple, .{ .int_adt = adt_handle, .ops = self.ops }, result_code);
    }
};
