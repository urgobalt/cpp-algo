const std = @import("std");
const tracked_item = @import("tracked_item.zig");
const c = @cImport({
    @cInclude("testing");
});
const testing_types = @import("input_generators.zig");
const errors = @import("error.zig");

const Allocator = std.mem.Allocator;
const TrackingObject = tracked_item.TrackingObject;
const FrameworkError = errors.FrameworkError;

pub const TestInputType = enum {
    Sorted, // Ascending values, ascending order_ids
    Reversed, // Descending values, ascending order_ids
    RandomUniqueValues, // Shuffled unique values, ascending order_ids
    FewUniqueValues, // Many repeated values
    NearlySorted, // Mostly sorted with a few swaps
    Custom, // User-provided data
    Empty,
};
// Generates TrackingObjects with values 0..size-1, order_ids 0..size-1
pub fn sorted(allocator: Allocator, size: usize) ![]TrackingObject {
    if (size == 0) return &[_]TrackingObject{};
    var arr = try allocator.alloc(TrackingObject, size);
    errdefer allocator.free(arr);

    var i: usize = 0;
    while (i < size) : (i += 1) {
        arr[i] = try TrackingObject.init(@intCast(i), @intCast(i));
    }
    return arr;
}

// Generates TrackingObjects with values size-1..0, order_ids 0..size-1
pub fn reversed(allocator: Allocator, size: usize) ![]TrackingObject {
    if (size == 0) return &[_]TrackingObject{};
    var arr = try allocator.alloc(TrackingObject, size);
    errdefer allocator.free(arr);

    var i: usize = 0;
    while (i < size) : (i += 1) {
        arr[i] = try TrackingObject.init(@intCast(size - 1 - i), @intCast(i));
    }
    return arr;
}

// Generates TrackingObjects with unique values 0..size-1 (shuffled), order_ids 0..size-1
pub fn randomUniqueValues(allocator: Allocator, size: usize, prng: *std.rand.Random) ![]TrackingObject {
    if (size == 0) return &[_]TrackingObject{};
    var arr = try allocator.alloc(TrackingObject, size);
    errdefer allocator.free(arr);

    // Create an array of indices to shuffle for values
    var values = try allocator.alloc(i32, size);
    defer allocator.free(values);
    for (0..size) |i| values[i] = @intCast(i);
    prng.shuffle(i32, values);

    var i: usize = 0;
    while (i < size) : (i += 1) {
        arr[i] = try TrackingObject.init(values[i], @intCast(i));
    }
    return arr;
}

// Generates TrackingObjects with a few unique values, spread randomly. order_ids 0..size-1
pub fn fewUniqueValues(allocator: Allocator, size: usize, prng: *std.rand.Random) ![]TrackingObject {
    if (size == 0) return &[_]TrackingObject{};

    var num_distinct_values: usize = @max(1, size / 10);
    if (num_distinct_values <= 1 and size > 1) {
        num_distinct_values = 2;
    }

    var arr = try allocator.alloc(TrackingObject, size);
    errdefer allocator.free(arr);

    var i: usize = 0;
    while (i < size) : (i += 1) {
        const random_value = prng.intRangeAtMost(i32, 0, @intCast(num_distinct_values - 1));
        arr[i] = try TrackingObject.init(random_value, @intCast(i));
    }
    return arr;
}

// Generates TrackingObjects mostly sorted by value, with a few swaps. order_ids 0..size-1
pub fn nearlySorted(allocator: Allocator, size: usize, prng: *std.rand.Random) ![]TrackingObject {
    if (size == 0) return &[_]TrackingObject{};
    var arr = try sorted(allocator, size); // Starts with sorted values and order_ids
    errdefer { // Ensure deinit is called on all successfully initialized objects in arr
        for (arr) |*obj| obj.deinit() catch {}; // Ignore deinit error during cleanup
        allocator.free(arr);
    }

    if (size < 2) return arr;

    const num_swaps: usize = @max(1, size / 20); // Swap about 5% of elements

    var k: usize = 0;
    while (k < num_swaps) : (k += 1) {
        const idx1 = prng.uintAtMost(usize, size - 1);
        const idx2 = prng.uintAtMost(usize, size - 1);
        if (idx1 == idx2) continue; // Don't swap with self

        // Swap the backing handles. The TrackingObject structs themselves are just containers.
        std.mem.swap(c.TrackedItemHandle, &arr[idx1].backing, &arr[idx2].backing);
    }
    return arr;
}

// Deinitializes a slice of TrackingObjects.
pub fn deinitTrackingObjectSlice(allocator: Allocator, slice: []TrackingObject) void {
    for (slice) |*item| {
        // Best effort to deinit. If one fails, we still try others.
        item.deinit() catch |err| {
            std.debug.print("Warning: Failed to deinit TrackingObject: {any}\n", .{err});
        };
    }
    allocator.free(slice);
}

// Main function to generate input data based on options.
// The caller is responsible for deinitializing the returned slice of TrackingObjects
// and then freeing the slice memory using the allocator.
pub fn generateInputData(
    allocator: Allocator,
    input_type: TestInputType,
    size: u32,
    prng: *std.rand.Random,
) FrameworkError![]TrackingObject {
    const usize_size: usize = @intCast(size);
    return switch (input_type) {
        .Empty => sorted(allocator, 0) catch |e| {
            std.debug.print("Error generating empty input: {any}\n", .{e});
            return FrameworkError.InputGenerationFailed;
        },
        .Sorted => sorted(allocator, usize_size) catch |e| {
            std.debug.print("Error generating sorted input: {any}\n", .{e});
            return FrameworkError.InputGenerationFailed;
        },
        .Reversed => reversed(allocator, usize_size) catch |e| {
            std.debug.print("Error generating reversed input: {any}\n", .{e});
            return FrameworkError.InputGenerationFailed;
        },
        .RandomUniqueValues => randomUniqueValues(allocator, usize_size, prng) catch |e| {
            std.debug.print("Error generating random unique input: {any}\n", .{e});
            return FrameworkError.InputGenerationFailed;
        },
        .FewUniqueValues => fewUniqueValues(allocator, usize_size, prng) catch |e| {
            std.debug.print("Error generating few unique input: {any}\n", .{e});
            return FrameworkError.InputGenerationFailed;
        },
        .NearlySorted => nearlySorted(allocator, usize_size, prng) catch |e| {
            std.debug.print("Error generating nearly sorted input: {any}\n", .{e});
            return FrameworkError.InputGenerationFailed;
        },
    };
}
