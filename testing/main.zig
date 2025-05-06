const std = @import("std");
pub const c = @cImport({
    @cInclude("testing");
});

const tracking = @import("track.zig");
const TrackingObject = tracking.TrackingObject;

// In case of link errors because (maybe) dead code elimination
comptime {
    _ = tracking;
}

const adt = @import("adt.zig");
const ADTBuilder = adt.ADTBuilder;
const ADT = adt.ADT;

const errors = @import("error.zig");
const TestingError = errors.TestingError;

fn assert_eq(new_value: c_int, old_value: c_int) void {
    if (new_value != old_value) {
        std.debug.print("invalid value, expected:{}, got {}", .{ new_value, old_value });
    }
}

fn c_test_all(adt_builder: ADTBuilder, tests: []const *const fn (ADTBuilder) TestingError!void) c_int {
    for (tests) |@"test"| {
        @"test"(adt_builder) catch |err| {
            return errors.testingErrorToInt(err);
        };
    }
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

export fn test_simple_adt(s: *c.adtOperations) c_int {
    const adtBuilder = ADTBuilder.init(s);
    return c_test_all(adtBuilder, &.{internal_test_adt});
}
