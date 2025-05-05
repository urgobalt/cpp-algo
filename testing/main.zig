const std = @import("std");

pub const c = @cImport({
    @cInclude("testing");
});

const TrackingObject = struct {
    backing: c.TrackedItemHandle,
    fn init(value: i64, order: i64) TrackingObject {
        const handle = &null;
        c.create_tracked_item_value(value, order, handle);
        return TrackingObject{ .backing = handle };
    }

    fn deinit(self: @This()) void {
        c.destroy_tracked_item(self.backing);
    }
};
const ADT = struct {
    int_adt: c.ADTHandle,
    ops: *c.AdtOperations,
    fn deinit(self: @This()) void {
        self.ops.destroy(self.int_adt);
    }
    fn insert(self: @This(), t: TrackingObject) void {
        self.ops.insert(*t.backing);
    }
    fn peek(self: @This()) TrackingObject {
        const a = self.ops.peek(self.int_adt);
        return TrackingObject{ .backing = *a };
    }
    fn remove(self: @This()) TrackingObject {
        const a = self.ops.remove(self.int_adt);
        return TrackingObject{ .backing = a };
    }
};
const ADTBuilder = struct {
    ops: *c.AdtOperations,

    fn init(input: *c.AdtOperations) @This() {
        return ADTBuilder{ .ops = input };
    }
    fn create(self: ADTBuilder) ADT {
        const adt = &null;
        self.ops.create(adt);
        return ADT{ .int_adt = adt, .ops = self };
    }
};
export fn test_adt(s: *c.AdtOperations) i32 {
    const b = ADTBuilder.init(s);
}
