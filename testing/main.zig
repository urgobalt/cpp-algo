const std = @import("std");
const tracking = @import("track.zig");
const adt = @import("adt.zig");
const errors = @import("error.zig");
const ADTBuilder = adt.ADTBuilder;
const TrackingObject = tracking.TrackingObject;
const ADT = adt.ADT;
pub const c = @cImport({
    @cInclude("testing");
});

comptime {
    _ = tracking;
}

fn assert_eq(new_value: c_int, old_value: c_int) void {
    if (new_value != old_value) {
        std.debug.print("invalid value, expected:{}, got {}", .{ new_value, old_value });
    }
}
export fn test_simple_adt(s: *c.adtOperations) c_int {
    const adtBuilder = adt.ADTBuilder.init(s);
    internal_test_adt(adtBuilder) catch |err| {
        return errors.testingErrorToInt(err);
    };
    return c.ADT_RESULT_SUCCESS;
}

fn internal_test_adt(adt_builder: ADTBuilder) !void {
    const adtb = try adt_builder.create();
    const value = 10;
    const order = 1;
    const t = try TrackingObject.init(value, order);
    try adtb.insert(t);
    const tn = try adt.remove();
    const new_value = tn.backing.*.value;
    assert_eq(new_value, value);
    const new_order = tn.backing.*.order;
    assert_eq(new_order, order);
    std.debug.print("TADA you have passed the zig tests", .{});
}
