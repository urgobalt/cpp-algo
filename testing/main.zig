const std = @import("std");
comptime {
    _ = @import("functions.zig");
}
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

fn c_test(adt_builder: ADTBuilder, @"test": *const fn (ADTBuilder) TestingError!void) c_int {
    @"test"(adt_builder) catch |err| {
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
    const tn = try adtb.remove();
    const new_value = tn.backing.*.value;
    assert_eq(new_value, value);
    const new_order = tn.backing.*.order;
    assert_eq(new_order, order);
    std.debug.print("TADA you have passed the zig tests", .{});
}

export fn test_test(s: *c.adtOperations) c_int {
    const adtBuilder = ADTBuilder.init(s);
    return c_test_all(adtBuilder, &.{internal_test_adt});
}

const insertionOrder = enum(c_int) { unknown = 0, firstInFirstOut = -1, firstInLastOut = -2, _ };

const Complexity = enum(c_int) {
    none = 0,
    @"O(1)" = -1,
    @"O(n)" = -2,
    @"O(nlogn)" = -3,
    @"O(n^2)" = -4,
    undetermined = -5,
    insufficientData = -6,
    _,
};

const Verbosity = enum(c_int) {
    @"error" = 0,
    warning = -1,
    info = -2,
    debug = -3,
    _,
};

const AdtTestingOptions = struct {
    verbosity: Verbosity,
    order: insertionOrder,
    sorted_output: bool,
    input_sizes: ?[]c_int,
    estimate_complexity: bool,
    expected_worst_complexity: Complexity,
    expected_average_complexity: Complexity,
    expected_best_complexity: Complexity,

    fn convert(options: *c.adtTestingOptions) AdtTestingOptions {
        var input_sizes: ?[]c_int = null;
        if (options.input_sizes) |s| {
            input_sizes = s[0..@intCast(options.input_sizes_size)];
        }

        return .{
            .verbosity = @enumFromInt(options.verbosity),
            .order = @enumFromInt(options.order),
            .sorted_output = options.sorted_output,
            .input_sizes = input_sizes,
            .estimate_complexity = options.estimate_complexity,
            .expected_worst_complexity = @enumFromInt(options.expected_worst_complexity),
            .expected_average_complexity = @enumFromInt(options.expected_average_complexity),
            .expected_best_complexity = @enumFromInt(options.expected_best_complexity),
        };
    }
};

export fn test_adt(_: *c.adtOperations, c_options: *c.adtTestingOptions) c_int {
    const options = AdtTestingOptions.convert(c_options);
    std.debug.print("{d}", .{@intFromEnum(options.order)});
    return 0;
}
