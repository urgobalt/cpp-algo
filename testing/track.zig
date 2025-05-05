const std = @import("std");
// Define the struct to hold the counts for each C++ operation.
// Using u64 for counters to avoid overflow for a long time.
const TrackedItemStats = struct {
    default_constructs: u64 = 0,
    value_constructs: u64 = 0,
    destructs: u64 = 0,
    copy_constructs: u64 = 0,
    copy_assigns: u64 = 0,
    move_constructs: u64 = 0,
    move_assigns: u64 = 0,
    compare_eq: u64 = 0,
    compare_lt: u64 = 0,
    compare_gt: u64 = 0,
    compare_neq: u64 = 0,
    compare_lte: u64 = 0,
    compare_gte: u64 = 0,
};

// Declare a static (file-level) instance of the stats struct.
// It's implicitly static because it's declared with 'var' at the top level
// and not marked 'pub'. It will be initialized with all fields set to 0
// based on the struct definition defaults.
var g_stats: TrackedItemStats = TrackedItemStats{};

export fn notify_default_construct() void {
    g_stats.default_constructs += 1;
}

export fn notify_value_construct(value: c_int, order: c_int) void {
    // Parameters are part of the C signature, but we only need to count the event.
    // Use `_ = var` to explicitly mark them as unused if needed by the linter/compiler.
    _ = value;
    _ = order;
    g_stats.value_constructs += 1;
}

export fn notify_destruct() void {
    g_stats.destructs += 1;
}

export fn notify_copy_construct() void {
    g_stats.copy_constructs += 1;
}

export fn notify_copy_assign() void {
    g_stats.copy_assigns += 1;
}

export fn notify_move_construct() void {
    g_stats.move_constructs += 1;
}

export fn notify_move_assign() void {
    g_stats.move_assigns += 1;
}

export fn notify_compare_eq() void {
    g_stats.compare_eq += 1;
}

export fn notify_compare_lt() void {
    g_stats.compare_lt += 1;
}

export fn notify_compare_gt() void {
    g_stats.compare_gt += 1;
}

export fn notify_compare_neq() void {
    g_stats.compare_neq += 1;
}

export fn notify_compare_lte() void {
    g_stats.compare_lte += 1;
}

export fn notify_compare_gte() void {
    g_stats.compare_gte += 1;
}

pub fn printStats() void {
    std.debug.print("TrackedItem Stats:\n", .{});
    std.debug.print("  Default Constructs: {d}\n", .{g_stats.default_constructs});
    std.debug.print("  Value Constructs:   {d}\n", .{g_stats.value_constructs});
    std.debug.print("  Destructs:          {d}\n", .{g_stats.destructs});
    std.debug.print("  Copy Constructs:    {d}\n", .{g_stats.copy_constructs});
    std.debug.print("  Copy Assigns:       {d}\n", .{g_stats.copy_assigns});
    std.debug.print("  Move Constructs:    {d}\n", .{g_stats.move_constructs});
    std.debug.print("  Move Assigns:       {d}\n", .{g_stats.move_assigns});
    std.debug.print("  Compare ==:         {d}\n", .{g_stats.compare_eq});
    std.debug.print("  Compare !=:         {d}\n", .{g_stats.compare_neq});
    std.debug.print("  Compare <:          {d}\n", .{g_stats.compare_lt});
    std.debug.print("  Compare <=:         {d}\n", .{g_stats.compare_lte});
    std.debug.print("  Compare >:          {d}\n", .{g_stats.compare_gt});
    std.debug.print("  Compare >=:         {d}\n", .{g_stats.compare_gte});
}
