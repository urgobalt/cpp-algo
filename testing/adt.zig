const c = @cImport({
    @cInclude("testing");
});
const errors = @import("error.zig");

pub const ADT = struct {
    int_adt: c.ADTHandle,
    ops: *c.adtOperations,
    order: c.InsertionOrder,
    fn deinit(self: @This()) !void {
        const a: c.testingResultCode = self.ops.destroy.?(self.int_adt);
        return errors.asTestingError(a);
    }
    fn insert(self: @This(), t: TrackingObject) !void {
        const a = self.ops.insert.?(self.int_adt, t.backing.?.*);
        return errors.asTestingError(a);
    }
    fn peek(self: @This()) !TrackingObject {
        var adt: c.TrackedItemHandle = null;
        const a: c.testingResultCode = self.ops.peek.?(self.int_adt, &adt);
        return errors.unwrapTesting(TrackingObject, .{ .backing = adt }, a);
    }
    fn remove(self: @This()) !TrackingObject {
        var adt: c.TrackedItemHandle = null;
        const a = self.ops.remove.?(self.int_adt, &adt);
        return errors.unwrapTesting(TrackingObject, .{ .backing = adt }, a);
    }
};

pub const ADTBuilder = struct {
    ops: *c.adtOperations,

    fn init(input: *c.adtOperations) @This() {
        return ADTBuilder{ .ops = input };
    }
    fn create(self: ADTBuilder) !ADT {
        var adt: c.ADTHandle = null;
        const a = self.ops.create.?(&adt);
        return errors.unwrapTesting(ADT, .{ .int_adt = adt, .ops = self.ops, .order = self.ops.order }, a);
    }
};

