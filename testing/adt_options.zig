const std = @import("std");
const c = @cImport({
    @cInclude("testing");
});
const tracked_item = @import("tracked_item.zig");

pub const insertionOrder = enum(c_int) { unknown = 0, firstInFirstOut = -1, firstInLastOut = -2, _ };

pub const InsertionOrder = enum(c_int) {
    Unknown = 0,
    FirstInFirstOut = -1,
    FirstInLastOut = -2,
    SortedValue = -3,
    Undefined = -4,
    _,
};

pub const Complexity = enum(c_int) {
    None = 0,
    @"O(1)" = -1,
    @"O(logN)" = -2,
    @"O(N)" = -3,
    @"O(NlogN)" = -4,
    @"O(N^2)" = -5,
    Undetermined = -6,
    InsufficientData = -7,
    NotApplicable = -8,
    _,
};

pub const Verbosity = enum(c_int) {
    Quiet = -4,
    Error = 0,
    Warning = -1,
    Info = -2,
    Debug = -3,
    Trace = -5,
    _,
};
pub const AdtSimpleTestingOptions = struct {
    name: []const u8 = "Unnamed ADT Test Case",
    verbosity: Verbosity = .Info,
    order: InsertionOrder = .Unknown,
    expected_output_sorted_by_value: bool = false,
    input_sizes: []const u32 = &[_]u32{ 10, 100 },
    prng_seed: u64 = 0,
    estimate_complexity: bool = false,
    max_operations_for_timing: u32 = 10000,
    expected_insert_complexity: Complexity = .Undetermined,
    expected_peek_complexity: Complexity = .Undetermined,
    expected_remove_complexity: Complexity = .Undetermined,
    num_iterations: u32 = 1,
    timeout_ms: ?u64 = 5000,
    fail_fast: bool = false,
    pub fn convert(options: *c.adtSimpleTestingOptions) AdtSimpleTestingOptions {
        var input_sizes: ?[]c_int = null;
        if (options.input_sizes) |s| {
            input_sizes = s[0..@intCast(options.input_sizes_size)];
        }

        return .{
            .name = std.mem.span(options.name),
            .verbosity = @enumFromInt(options.verbosity),
            .order = @enumFromInt(options.order),
            .expected_output_sorted_by_value = options.sorted_output,
            .input_sizes = input_sizes,
            .estimate_complexity = options.estimate_complexity,
            .expected_insert_complexity = @enumFromInt(options.expected_insert_complexity),
            .expected_peek_complexity = @enumFromInt(options.expected_peek_complexity),
            .expected_remove_complexity= @enumFromInt(options.expected_remove_complexity),
        };
    }
};

pub const TestMeasurement = struct {
    operation: []const u8,
    input_size_n: u32,
    duration_ns: u64,
    operations_count: u64,
};

pub const TestFailure = struct {
    reason: []const u8,
    details: ?[]const u8 = null,
    expected: ?[]const u8 = null,
    actual: ?[]const u8 = null,
    pub fn deinit(self: *TestFailure, allocator: std.mem.Allocator) void {
        if (self.details) |d| allocator.free(d);
        if (self.expected) |e| allocator.free(e);
        if (self.actual) |a| allocator.free(a);
        self.* = undefined;
    }
};
