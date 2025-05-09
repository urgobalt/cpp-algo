const std = @import("std");
const testing_types = @import("adt_options.zig");
const errors = @import("error.zig");
const logging = @import("logging.zig");
const TestMeasurement = testing_types.TestMeasurement;
const TestFailure = testing_types.TestFailure;
const Verbosity = testing_types.Verbosity;
const Allocator = std.mem.Allocator;

pub const TestCaseResult = struct {
    name: []const u8,
    passed: bool,
    failure: ?TestFailure = null,
    measurements: std.ArrayList(TestMeasurement),
    allocator: Allocator,
    pub fn init(name: []const u8, allocator: Allocator) TestCaseResult {
        return .{
            .name = name,
            .passed = true,
            .measurements = std.ArrayList(TestMeasurement).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *TestCaseResult) void {
        if (self.failure) |*f| {
            f.deinit(self.allocator);
        }
        self.measurements.deinit();
    }

    pub fn recordFailure(
        self: *TestCaseResult,
        reason: []const u8,
        details: ?[]const u8,
        expected: ?[]const u8,
        actual: ?[]const u8,
    ) void {
        self.passed = false;

        if (self.failure) |*f| {
            f.deinit(self.allocator);
        }

        var new_failure = TestFailure{ .reason = reason };
        if (details) |d| new_failure.details = self.allocator.dupe(u8, d) catch @panic("failed to allocate failure");
        if (expected) |e| new_failure.expected = self.allocator.dupe(u8, e) catch @panic("failed to allocate failure");
        if (actual) |a| new_failure.actual = self.allocator.dupe(u8, a) catch @panic("failed to allocate failure");

        self.failure = new_failure;
    }

    pub fn addMeasurement(self: *TestCaseResult, measurement: TestMeasurement) !void {
        try self.measurements.append(measurement);
    }

    pub fn printDetails(self: *const TestCaseResult, verbosity: Verbosity) !void {
        if (self.passed) {
            try logging.log(verbosity, "  PASSED: {s}\n", .{self.name});
        } else {
            try logging.log(verbosity, "  FAILED: {s}", .{self.name});
            if (self.failure) |f| {
                try logging.log(verbosity, "    Reason: {s}", .{f.reason});
                if (f.details) |d| try logging.log(verbosity, "    Details: {s}", .{d});
                if (f.expected) |e| try logging.log(verbosity, "    Expected: {s}", .{e});
                if (f.actual) |a| try logging.log(verbosity, "    Actual: {s}", .{a});
            }
        }
        if (self.measurements.items.len > 0) {
            try logging.log(verbosity, "    Measurements:\n", .{});
            for (self.measurements.items) |m| {
                try logging.log(verbosity, "      - Op: {s}, N: {d}, Time: {d}ns, Count: {d}", .{
                    m.operation, m.input_size_n, m.duration_ns, m.operations_count,
                });
            }
        }
    }
};

pub const TestSuiteResult = struct {
    name: []const u8,
    case_results: std.ArrayList(TestCaseResult),
    allocator: Allocator,
    total_tests: u32 = 0,
    passed_tests: u32 = 0,
    failed_tests: u32 = 0,

    pub fn init(name: []const u8, allocator: Allocator) TestSuiteResult {
        return .{
            .name = name,
            .case_results = std.ArrayList(TestCaseResult).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *TestSuiteResult) void {
        for (self.case_results.items) |*result| {
            result.deinit();
        }
        self.case_results.deinit();
    }

    pub fn addResult(self: *TestSuiteResult, result: TestCaseResult) !void {
        try self.case_results.append(result);
        self.total_tests += 1;
        if (result.passed) {
            self.passed_tests += 1;
        } else {
            self.failed_tests += 1;
        }
    }

    pub fn printSummary(self: *const TestSuiteResult) !void {
        try logging.log(.Info, "\n--- Test Suite Summary: {s} ---\n", .{self.name});
        try logging.log(.Info, "Total Test Cases Run: {d}\n", .{self.total_tests});
        try logging.log(.Info, "Passed: {d}\n", .{self.passed_tests});
        try logging.log(.Info, "Failed: {d}\n", .{self.failed_tests});

        if (self.failed_tests > 0) {
            try logging.log(.Debug, "\nDetailed Failures for Suite '{s}':\n", .{self.name});
            for (self.case_results.items) |result| {
                if (!result.passed) {
                    try result.printDetails(.Error);
                } else {
                    try result.printDetails(.Info);
                }
            }
        } else {
            try logging.log(.Info, "\nDetails for Suite '{s}':\n", .{self.name});
            for (self.case_results.items) |result| {
                try result.printDetails(.Debug);
            }
        }
        try logging.log(.Info,"--- End Summary: {s} ---\n", .{self.name});
    }
};
