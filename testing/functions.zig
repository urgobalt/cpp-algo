const std = @import("std");
const TrackedObject = @import("track.zig").TrackingObject;
// Helper for error handling when allocation fails
const AllocatorError = error{OutOfMemory};

pub fn reversed(allocator: std.mem.Allocator, size: usize) AllocatorError![]TrackedObject {
    if (size == 0) {
        return &[_]TrackedObject{}; // Return an empty slice for size 0
    }
    var arr = try allocator.alloc(TrackedObject, size);
    errdefer allocator.free(arr); // Ensure memory is freed if an error occurs later

    for (0..size) |i| {
        arr[i] = TrackedObject.init(@intCast(size - 1 - i), @intCast(i));
    }
    return arr;
}

pub fn sorted(allocator: std.mem.Allocator, size: usize) AllocatorError![]TrackedObject {
    if (size == 0) {
        return &[_]TrackedObject{};
    }
    var arr = try allocator.alloc(TrackedObject, size);
    errdefer allocator.free(arr);

    for (0..size) |i| {
        arr[i] = TrackedObject.init(@intCast(i), @intCast(i));
    }
    return arr;
}

pub fn randomUnique(allocator: std.mem.Allocator, size: usize, prng: std.rand.Random) AllocatorError![]TrackedObject {
    if (size == 0) {
        return &[_]TrackedObject{};
    }
    var arr = try allocator.alloc(TrackedObject, size);
    errdefer allocator.free(arr);

    for (0..size) |i| {
        arr[i] = TrackedObject.init(@intCast(i), @intCast(i));
    }

    // Shuffle the array
    prng.shuffle(TrackedObject, arr);

    return arr;
}

pub fn fewUnique(allocator: std.mem.Allocator, size: usize, prng: std.rand.Random) AllocatorError![]TrackedObject {
    if (size == 0) {
        return &[_]TrackedObject{};
    }
    var num_unique: usize = @max(1, size / 10);
    if (num_unique <= 1 and size > 1) {
        num_unique = 2;
    }

    var arr = try allocator.alloc(TrackedObject, size);
    errdefer allocator.free(arr);

    for (0..size) |i| {
        arr[i] = TrackedObject.init(@intCast(prng.uintAtMost(@intCast(num_unique - 1))), @intCast(i));
    }
    return arr;
}

pub fn nearlySorted(allocator: std.mem.Allocator, size: usize, prng: std.rand.Random) AllocatorError![]TrackedObject {
    if (size == 0) {
        return &[_]TrackedObject{};
    }
    var arr = try sorted(allocator, size); // Re-use the sorted function
    // Note: `sorted` allocates, so we don't need to errdefer free `arr` here again
    // as `sorted` itself would have handled it or `arr` would be the successful allocation.

    if (size < 2) {
        return arr;
    }

    const num_swaps: usize = @max(1, size / 20);

    for (0..num_swaps) |_| {
        const idx1 = prng.uintAtMost(usize, size - 1);
        const idx2 = prng.uintAtMost(usize, size - 1);
        std.mem.swap(TrackedObject, &arr[idx1], &arr[idx2]);
    }
    return arr;
}
