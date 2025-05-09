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
    ) !void {
        self.passed = false;

        if (self.failure) |*f| {
            f.deinit(self.allocator);
        }

        var new_failure = TestFailure{ .reason = reason };
        if (details) |d| new_failure.details = try self.allocator.dupe(u8, d);
        if (expected) |e| new_failure.expected = try self.allocator.dupe(u8, e);
        if (actual) |a| new_failure.actual = try self.allocator.dupe(u8, a);

        self.failure = new_failure;
    }

    pub fn addMeasurement(self: *TestCaseResult, measurement: TestMeasurement) !void {
        try self.measurements.append(measurement);
    }

    pub fn printDetails(self: *const TestCaseResult, verbosity: Verbosity) !void {
        if (self.passed) {
            if (verbosity >= .Info) {
                try logging.log("  PASSED: {s}\n", .{self.name});
            }
        } else {
            if (verbosity >= .Error) {
                try logging.log("  FAILED: {s}\n", .{self.name});
                if (self.failure) |f| {
                    try logging.log("    Reason: {s}\n", .{f.reason});
                    if (f.details) |d| try logging.log("    Details: {s}\n", .{d});
                    if (f.expected) |e| try logging.log("    Expected: {s}\n", .{e});
                    if (f.actual) |a| try logging.log("    Actual: {s}\n", .{a});
                }
            }
        }
        if (verbosity >= .Debug and self.measurements.items.len > 0) {
            try logging.log("    Measurements:\n", .{});
            for (self.measurements.items) |m| {
                try logging.log("      - Op: {s}, N: {d}, Time: {d}ns, Count: {d}\n", .{
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

    pub fn printSummary(self: *const TestSuiteResult, verbosity: Verbosity) !void {
        if (verbosity >= .Info) {
            try logging.log("\n--- Test Suite Summary: {s} ---\n", .{self.name});
            try logging.log("Total Test Cases Run: {d}\n", .{self.total_tests});
            try logging.log("Passed: {d}\n", .{self.passed_tests});
            try logging.log("Failed: {d}\n", .{self.failed_tests});
        }

        if (self.failed_tests > 0 and verbosity >= .Error) {
            try logging.log("\nDetailed Failures for Suite '{s}':\n", .{self.name});
            for (self.case_results.items) |result| {
                if (!result.passed) {
                    try result.printDetails(@max(verbosity, .Error));
                } else if (verbosity >= .Debug) {
                    try result.printDetails(verbosity);
                }
            }
        } else if (verbosity >= .Debug) {
            try logging.log("\nDetails for Suite '{s}':\n", .{self.name});
            for (self.case_results.items) |result| {
                try result.printDetails(verbosity);
            }
        }
        try logging.log("--- End Summary: {s} ---\n", .{self.name});
    }
};
