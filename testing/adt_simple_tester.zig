const std = @import("std");
const c = @cImport({
    @cInclude("testing");
});
const logging = @import("logging.zig");
const errors = @import("error.zig");
const tracked_item = @import("tracked_item.zig");
const TrackingObject = tracked_item.TrackingObject;
const testing_types = @import("adt_options.zig");
const input_generators = @import("input_generators.zig");
const test_results = @import("test_results.zig");
const test_runner = @import("test_runner.zig");
const adt = @import("adt_simple.zig");
const Verbosity = @import("adt_options.zig").Verbosity;
const AdtSimpleTestingOptions = testing_types.AdtSimpleTestingOptions;
const InsertionOrder = testing_types.InsertionOrder;
const TestCaseResult = test_results.TestCaseResult;
const ADTSimple = adt.ADTSimple;
const ADTSimpleBuilder = adt.ADTSimpleBuilder;
const Allocator = std.mem.Allocator;

fn formatTracked(obj: TrackingObject, allocator: Allocator) ![]const u8 {
    const val = obj.getValue() catch -999;
    const id = obj.getOrderId() catch -999;
    return std.fmt.allocPrint(allocator, "Tracked(val={d}, id={d}, handle={?*})", .{ val, id, obj.backing });
}
const MaybeTrackingObject = union { t: TrackingObject, v: void };
pub fn runAdtTestCase(
    allocator: Allocator,
    adt_builder: ADTSimpleBuilder,
    options: test_runner.TestOptions,
    prng: *std.Random,
) !TestCaseResult {
    var result = TestCaseResult.init(options.name, allocator);
    const input_data_generated = input_generators.generateInputData(
        allocator,
        options.input_type,
        options.input_sizes[0],
        prng,
    ) catch |err| {
        var err_msg_buf: [128]u8 = undefined;
        var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
        errors.formatError(err, err_fbs.writer()) catch {};
        result.recordFailure("Input data generation failed", err_fbs.getWritten(), null, null);
        return result;
    };
    defer input_generators.deinitTrackingObjectSlice(allocator, input_data_generated);

    try logging.log(.Debug, "  Test: {s}, Input Size: {d}, Type: {s}\n", .{
        options.name, input_data_generated.len, @tagName(options.input_type),
    });
    if (input_data_generated.len > 0 and input_data_generated.len < 20) {
        try logging.log(.Trace, "    Input Data:\n", .{});
        for (input_data_generated, 0..) |item, i| {
            const val_str = item.getValue() catch |e| {
                try logging.log(.Error, "      [{d}] Error getting value: {}\n", .{ i, e });
                continue;
            };
            const id_str = item.getOrderId() catch |e| {
                try logging.log(.Error, "      [{d}] Error getting order_id: {}\n", .{ i, e });
                continue;
            };
            try logging.log(.Debug, "      [{d}] val={d}, id={d}\n", .{ i, val_str, id_str });
        }
    }

    var adt_instance = adt_builder.create() catch |err| {
        var err_msg_buf: [128]u8 = undefined;
        var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
        errors.formatError(err, err_fbs.writer()) catch {};
        result.recordFailure("ADT creation failed", err_fbs.getWritten(), null, null);
        return result;
    };
    defer adt_instance.deinit() catch |err| {
        if (result.passed) {
            var err_msg_buf: [128]u8 = undefined;
            var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
            errors.formatError(err, err_fbs.writer()) catch {};
            result.recordFailure("ADT deinit failed post-test", err_fbs.getWritten(), null, null);
        } else if (@intFromEnum(options.verbosity) >= @intFromEnum(Verbosity.Error)) {
            std.debug.print("Error during ADT deinit after a test failure (error not recorded in result): {any}\n", .{err});
        }
    };

    var timer = try std.time.Timer.start();
    for (input_data_generated) |item_to_insert| {
        adt_instance.insert(item_to_insert) catch |err| {
            const item_str = formatTracked(item_to_insert, allocator) catch "FormattedItemError";
            defer if (std.mem.eql(u8, item_str, "FormattedItemError")) {} else {
                allocator.free(item_str);
            };
            var err_msg_buf: [128]u8 = undefined;
            var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
            errors.formatError(err, err_fbs.writer()) catch {};
            result.recordFailure(
                "ADT insert failed",
                try std.fmt.allocPrint(allocator, "Item: {s}, Error: {s}", .{ item_str, err_fbs.getWritten() }),
                null,
                null,
            );
            return result;
        };
    }
    const insert_duration_ns = timer.read();
    if (options.estimate_complexity) {
        try result.addMeasurement(.{
            .operation = "insert_all",
            .input_size_n = @intCast(input_data_generated.len),
            .duration_ns = insert_duration_ns,
            .operations_count = @intCast(input_data_generated.len),
        });
    }

    if (input_data_generated.len > 0) {
        timer.reset();
        const peeked_obj_wrapper = adt_instance.peek() catch |err| {
            var err_msg_buf: [128]u8 = undefined;
            var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
            errors.formatError(err, err_fbs.writer()) catch {};
            result.recordFailure("ADT peek failed", err_fbs.getWritten(), null, null);
            return result;
        };

        const peek_duration_ns = timer.read();
        if (options.estimate_complexity) {
            try result.addMeasurement(.{ .operation = "peek_one", .input_size_n = @intCast(input_data_generated.len), .duration_ns = peek_duration_ns, .operations_count = 1 });
        }

        var expected_peek_candidate_idx: ?usize = null;
        switch (options.order) {
            .FirstInFirstOut => expected_peek_candidate_idx = 0,
            .FirstInLastOut => expected_peek_candidate_idx = input_data_generated.len - 1,
            .SortedValue => {
                var min_idx: usize = 0;
                for (input_data_generated, 1..) |current_item, current_idx| {
                    if (try TrackingObject.lessThan(current_item, input_data_generated[min_idx])) {
                        min_idx = current_idx;
                    }
                }
                expected_peek_candidate_idx = min_idx;
            },
            else => {},
        }

        if (expected_peek_candidate_idx) |idx| {
            const expected_obj_from_input = input_data_generated[idx];
            if (!(try TrackingObject.eql(peeked_obj_wrapper, expected_obj_from_input))) {
                const actual_str = formatTracked(peeked_obj_wrapper, allocator) catch "FormattedActualError";
                defer if (std.mem.eql(u8, actual_str, "FormattedActualError")) {} else {
                    allocator.free(actual_str);
                };
                const expected_str = formatTracked(expected_obj_from_input, allocator) catch "FormattedExpectedError";
                defer if (std.mem.eql(u8, expected_str, "FormattedExpectedError")) {} else {
                    allocator.free(expected_str);
                };
                result.recordFailure(
                    "Peek verification failed",
                    try std.fmt.allocPrint(allocator, "Order: {s}", .{@tagName(options.order)}),
                    expected_str,
                    actual_str,
                );
                return result;
            }
        }
    } else {
        Peak_Success: {
            const peek_should_fail_err: TrackingObject =
                adt_instance.peek() catch |err| {
                    if (err == errors.AdtError.Empty) {
                        try logging.log(.Trace, "    Peek on empty correctly failed with 'Empty'.\n", .{});
                    } else {
                        var err_msg_buf: [128]u8 = undefined;
                        var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
                        errors.formatError(err, err_fbs.writer()) catch {};
                        result.recordFailure("Peek on empty ADT failed with unexpected error", err_fbs.getWritten(), "errors.AdtError.Empty", null);
                        return result;
                    }
                    break :Peak_Success;
                };
            const peeked_val_on_empty = peek_should_fail_err;
            _ = peeked_val_on_empty;
            result.recordFailure("Peek on empty ADT unexpectedly succeeded", null, "Expected error.Empty", "Success");
            return result;
        }
    }

    var removed_items_list = std.ArrayList(TrackingObject).init(allocator);
    defer {
        for (removed_items_list.items) |item| item.deinit() catch {};
        removed_items_list.deinit();
    }

    timer.reset();
    var k: usize = 0;
    while (k < input_data_generated.len) : (k += 1) {
        const removed_obj = adt_instance.remove() catch |err| {
            var err_msg_buf: [128]u8 = undefined;
            var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
            errors.formatError(err, err_fbs.writer()) catch {};
            result.recordFailure(
                "ADT remove failed",
                try std.fmt.allocPrint(allocator, "Attempted to remove item #{d} of {d}. Error: {s}", .{ k + 1, input_data_generated.len, err_fbs.getWritten() }),
                null,
                null,
            );
            return result;
        };
        try removed_items_list.append(removed_obj);
    }
    const remove_duration_ns = timer.read();
    if (options.estimate_complexity) {
        try result.addMeasurement(.{
            .operation = "remove_all",
            .input_size_n = @intCast(input_data_generated.len),
            .duration_ns = remove_duration_ns,
            .operations_count = @intCast(input_data_generated.len),
        });
    }

    if (removed_items_list.items.len != input_data_generated.len) {
        result.recordFailure(
            "Mismatch in removed items count",
            null,
            try std.fmt.allocPrint(allocator, "{d}", .{input_data_generated.len}),
            try std.fmt.allocPrint(allocator, "{d}", .{removed_items_list.items.len}),
        );
        return result;
    }

    if (input_data_generated.len > 0) {
        const actual_removed_slice = removed_items_list.items;
        var expected_removed_ordered_indices = try allocator.alloc(usize, input_data_generated.len);
        defer allocator.free(expected_removed_ordered_indices);

        switch (options.order) {
            .FirstInFirstOut => {
                for (0..input_data_generated.len) |idx| expected_removed_ordered_indices[idx] = idx;
            },
            .FirstInLastOut => {
                for (0..input_data_generated.len) |idx| expected_removed_ordered_indices[idx] = input_data_generated.len - 1 - idx;
            },
            .SortedValue => {
                const Pair = struct { value: i32, order_id: i32, original_index: usize };
                var pairs = try allocator.alloc(Pair, input_data_generated.len);
                defer allocator.free(pairs);
                for (input_data_generated, 0..) |item, original_idx| {
                    pairs[original_idx] = .{
                        .value = item.getValue() catch |e| {
                            std.debug.print("Error getting value for sort: {any}\n", .{e});
                            return errors.FrameworkError.TestLogicError;
                        },
                        .order_id = item.getOrderId() catch |e| {
                            std.debug.print("Error getting order_id for sort: {any}\n", .{e});
                            return errors.FrameworkError.TestLogicError;
                        },
                        .original_index = original_idx,
                    };
                }
                std.sort.block(Pair, pairs, {}, struct {
                    fn lessThanCtx(_: void, a: Pair, b: Pair) bool {
                        if (a.value == b.value) return a.order_id < b.order_id;
                        return a.value < b.value;
                    }
                }.lessThanCtx);
                for (pairs, 0..) |p, sorted_idx| expected_removed_ordered_indices[sorted_idx] = p.original_index;
            },
            else => {},
        }

        if (options.order != .Unknown and options.order != .Undefined) {
            for (expected_removed_ordered_indices, 0..) |expected_item_original_idx, removed_idx| {
                const expected_item_from_input = input_data_generated[expected_item_original_idx];
                const actual_removed_item = actual_removed_slice[removed_idx];
                if (!(try TrackingObject.eql(expected_item_from_input, actual_removed_item))) {
                    const actual_str = formatTracked(actual_removed_item, allocator) catch "FormattedActualError";
                    defer if (std.mem.eql(u8, actual_str, "FormattedActualError")) {} else {
                        allocator.free(actual_str);
                    };
                    const expected_str = formatTracked(expected_item_from_input, allocator) catch "FormattedExpectedError";
                    defer if (std.mem.eql(u8, expected_str, "FormattedExpectedError")) {} else {
                        allocator.free(expected_str);
                    };
                    result.recordFailure(
                        "Removed item mismatch or incorrect order",
                        try std.fmt.allocPrint(allocator, "Mismatch at removal index {d} for ADT order {s}", .{ removed_idx, @tagName(options.order) }),
                        expected_str,
                        actual_str,
                    );
                    return result;
                }
            }
        }

        if (options.expected_output_sorted_by_value and actual_removed_slice.len > 1) {
            for (1..actual_removed_slice.len) |current_idx| {
                const prev_item = actual_removed_slice[current_idx - 1];
                const current_item = actual_removed_slice[current_idx];
                if (!(try TrackingObject.lessThan(prev_item, current_item)) and !(try TrackingObject.eql(prev_item, current_item))) {
                    const prev_str = formatTracked(prev_item, allocator) catch "FormattedPrevError";
                    defer if (std.mem.eql(u8, prev_str, "FormattedPrevError")) {} else {
                        allocator.free(prev_str);
                    };
                    const curr_str = formatTracked(current_item, allocator) catch "FormattedCurrError";
                    defer if (std.mem.eql(u8, curr_str, "FormattedCurrError")) {} else {
                        allocator.free(curr_str);
                    };
                    result.recordFailure(
                        "Output not sorted by value as expected",
                        try std.fmt.allocPrint(allocator, "Order violation between index {d} ({s}) and {d} ({s})", .{ current_idx - 1, prev_str, current_idx, curr_str }),
                        "prev <= curr",
                        "prev > curr",
                    );
                    return result;
                }
            }
        }
    }

    Peak_Success: {
        _ = adt_instance.remove() catch |err| {
            if (err == errors.AdtError.Empty) {
                try logging.log(.Trace, "    ADT correctly empty after all removals.\n", .{});
            } else {
                var err_msg_buf: [128]u8 = undefined;
                var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
                errors.formatError(err, err_fbs.writer()) catch {};
                result.recordFailure("ADT not empty or remove failed unexpectedly after all items removed", err_fbs.getWritten(), "errors.AdtError.Empty", null);
                return result;
            }
            break :Peak_Success;
        };
        result.recordFailure("ADT was not empty after all expected items were removed.", null, "ADT to be empty", "ADT not empty");
    }
    return result;
}
