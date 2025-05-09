const std = @import("std");
pub const c = @cImport({
    @cInclude("testing");
});
const logging = @import("logging.zig");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const global_allocator = gpa.allocator();
const tracking = @import("tracked_item.zig");
const TrackingObject = tracking.TrackingObject;
const InsertionOrder = adt_options.InsertionOrder;
const Verbosity = adt_options.Verbosity;
const Complexity = adt_options.Complexity;

// In case of link errors because (maybe) dead code elimination
comptime {
    _ = tracking;
}

const adt = @import("adt_simple.zig");
const ADTSimpleBuilder = adt.ADTSimpleBuilder;
const ADT = adt.ADTSimple;

const adt_options = @import("adt_options.zig");
const AdtSimpleTestingOptions = adt_options.AdtSimpleTestingOptions;

const errors = @import("error.zig");
const TestingError = errors.TestingError;

const test_runner = @import("test_runner.zig");
const TestSuite = test_runner.TestSuite;
const TestRunner = test_runner.TestRunner;
fn assert_eq(new_value: c_int, old_value: c_int) void {
    if (new_value != old_value) {
        std.debug.print("invalid value, expected:{}, got {}", .{ new_value, old_value });
    }
}

export fn test_test(_: *c.adtOperations) c_int {
    return -4;
    // beacuse we changed how testing works this is no longer the same, we should use the testing as done bellow.
    // Do not remove, it broke production
}

export fn test_adt(c_adt_ops: *c.adtOperations, c_options: *c.adtSimpleTestingOptions) c_int {
    // here logging works as i want it to the rest is wrong
    logging.log(.Info, "Starting ADT Testing Framework...\n", .{}) catch |err| {
        return errors.testingErrorToCInt(err);
    };
    const options = AdtSimpleTestingOptions.convert(c_options);
    const builder = ADTSimpleBuilder.init(c_adt_ops);

    var test_adt_suite = TestSuite.init(global_allocator, "FIFO Mock ADT Suite", builder, .{
        .verbosity = .Debug, // Suite-level verbosity
        .reset_stats_before_suite = true,
        .print_stats_after_suite = true,
    });
    defer test_adt_suite.deinit();

    try test_adt_suite.addCaseConfig(.{
        .name = std.mem.join(global_allocator, " ", &.{ options.name, "Basic Ops" }) catch @panic("global alloc go boom"),
        .order = options.order,
        .input_sizes = &[_]c_int{ 5, 10 },
    });
    try test_adt_suite.addCaseConfig(.{
        .name = std.mem.join(gpa.allocator(), " ", &.{ options.name, "Empty Input" }) catch @panic("global alloc go boom"),
        .order = options.order,
        .input_sizes = &[_]c_int{0},
    });
    try test_adt_suite.addCaseConfig(.{
        .name = std.mem.join(gpa.allocator(), " ", &.{ options.name, "Random Input" }) catch @panic("global alloc go boom"),
        .order = options.order,
        .input_sizes = &[_]c_int{8},
        .estimate_complexity = true,
    });

    var runner = TestRunner.init(global_allocator, 0); // 0 for time-based master_seed
    defer runner.deinit();

    try runner.addSuite(&test_adt_suite);
    var final_results = runner.runAll() catch |err| {
        logging.log(.Error, "Test Runner CRASHED: {any}\n", .{err});
        if (gpa.deinit() == .leak) {
            logging.print("Warning: Memory leak detected by GeneralPurposeAllocator after crash!\n", .{}) catch |terr| {
                return errors.testingErrorToCInt(terr);
            };
        }
        return;
    };
    defer final_results.deinit();

    final_results.printSummary(.Info) catch |terr| {
        return errors.testingErrorToCInt(terr);
    };

    if (gpa.deinit() == .leak) {
        try logging.log("Memory leak detected by GeneralPurposeAllocator at end of main!\n", .{}) catch |terr| {
            return errors.testingErrorToCInt(terr);
        };
    } else {
        logging.log("GPA deinitialized successfully. No leaks reported by GPA.\n", .{}) catch |terr| {
            return errors.testingErrorToCInt(terr);
        };
    }
    logging.log("ADT Testing Framework finished.\n", .{}) catch |terr| {
        return errors.testingErrorToCInt(terr);
    };
}
export fn default_adtSimpleTestingOptions(name: [*c]u8) c.adtSimpleTestingOptions {
    const initial_values = [_]c_int{ 10, 50, 100, 200, 500, 1000, 2000, 5000, 10000 };
    const defaultSizes = std.heap.c_allocator.dupe(c_int, &initial_values) catch |err| {
        std.debug.panic("C allocator hit the fan: {any}", .{err});
    };
    return .{
        .name = name,
        .verbosity = @intFromEnum(Verbosity.Error),
        .order = @intFromEnum(InsertionOrder.Unknown),
        .sorted_output = true,
        .input_sizes = @ptrCast(defaultSizes.ptr),
        .input_sizes_size = 9,
        .estimate_complexity = true,
        .expected_insert_complexity = @intFromEnum(Complexity.None),
        .expected_peek_complexity = @intFromEnum(Complexity.None),
        .expected_remove_complexity = @intFromEnum(Complexity.None),
    };
}
