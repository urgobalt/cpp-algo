const std = @import("std");
const testing_types = @import("adt_options.zig");
const test_results = @import("test_results.zig");
const adt_tester = @import("adt_simple_tester.zig");
const adt = @import("adt_simple.zig");
const tracked_item = @import("tracked_item.zig");
const errors = @import("error.zig");
const logging = @import("logging.zig");
const TestingError = errors.TestingError;
const AdtTestingOptions = testing_types.AdtSimpleTestingOptions;
const TestCaseResult = test_results.TestCaseResult;
const TestSuiteResult = test_results.TestSuiteResult;
const ADTSimpleBuilder = adt.ADTSimpleBuilder;
const Allocator = std.mem.Allocator;
const Verbosity = testing_types.Verbosity;
const InsertionOrder = testing_types.InsertionOrder;
const Complexity = testing_types.Complexity;
const TestInputType = @import("input_generators.zig").TestInputType;
pub const TestOptions = struct {
    name: []const u8 = "Unnamed ADT Test Case",
    verbosity: Verbosity = .Info,
    order: InsertionOrder = .Unknown,
    expected_output_sorted_by_value: bool = false,
    input_type: TestInputType = .RandomUniqueValues,
    input_sizes: []const c_int,
    prng_seed: u64 = 0,
    estimate_complexity: bool = false,
    max_operations_for_timing: u32 = 10000,
    expected_insert_complexity: Complexity = .Undetermined,
    expected_peek_complexity: Complexity = .Undetermined,
    expected_remove_complexity: Complexity = .Undetermined,
    num_iterations: u32 = 1,
    timeout_ms: ?u64 = 5000,
    fail_fast: bool = false,
};
pub const TestSuiteOptions = struct {
    verbosity: Verbosity = .Info,
    fail_fast_suite: bool = false,
    reset_stats_before_suite: bool = true,
    print_stats_after_suite: bool = false,
};

pub const TestSuite = struct {
    name: []const u8,
    adt_builder: ADTSimpleBuilder,
    test_case_configs: std.ArrayList(TestOptions),
    options: TestSuiteOptions,
    allocator: Allocator,

    pub fn init(
        allocator: Allocator,
        name: []const u8,
        builder: ADTSimpleBuilder,
        options: TestSuiteOptions,
    ) TestSuite {
        return .{
            .name = name,
            .adt_builder = builder,
            .test_case_configs = std.ArrayList(TestOptions).init(allocator),
            .options = options,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *TestSuite) void {
        for (self.test_case_configs.items) |*config| {
            self.allocator.destroy(config);
        }
        self.test_case_configs.deinit();
    }

    pub fn addCaseConfig(self: *TestSuite, config: TestOptions) TestingError!void {
        self.test_case_configs.append(config) catch {
            return error.Alloc;
        };
    }
};

pub const TestRunner = struct {
    allocator: Allocator,
    prng_master: std.Random,
    suites_to_run: std.ArrayList(*TestSuite),
    pub fn init(allocator: Allocator, master_seed: u64) TestRunner {
        var seeded_prng = std.Random.DefaultPrng.init(master_seed);
        if (master_seed == 0) {
            const time_seed: usize = @intCast(std.time.nanoTimestamp());
            seeded_prng = std.Random.DefaultPrng.init(time_seed);
            std.debug.print("Initialized TestRunner PRNG with time-based seed: {d}\n", .{time_seed});
        } else {
            std.debug.print("Initialized TestRunner PRNG with fixed seed: {d}\n", .{master_seed});
        }
        return .{
            .allocator = allocator,
            .prng_master = seeded_prng.random(),
            .suites_to_run = std.ArrayList(*TestSuite).init(allocator),
        };
    }

    pub fn deinit(self: *TestRunner) void {
        for (self.suites_to_run.items) |value| {
            value.deinit();
        }
        self.suites_to_run.deinit();
    }

    pub fn addSuite(self: *TestRunner, suite_ptr: *TestSuite) TestingError!void {
        self.suites_to_run.append(suite_ptr) catch {
            return error.Alloc;
        };
    }

    pub fn runAll(self: @This()) !TestSuiteResult {
        var overall_run_result = TestSuiteResult.init("Overall Test Run Summary", self.allocator);

        for (self.suites_to_run.items) |suite_ptr| {
            const suite = suite_ptr.*;
            var suite_result = TestSuiteResult.init(suite.name, self.allocator);

            const suite_verbosity = suite.options.verbosity;
            try logging.log(.Info, "\n=== Running Test Suite: {s} ===\n", .{suite.name});

            if (suite.options.reset_stats_before_suite) {
                try logging.log(.Debug, "  Resetting TrackedItem stats before suite.\n", .{});
                _ = tracked_item.resetStats();
            }

            for (suite.test_case_configs.items) |base_config| {
                END_SUITE_CONFIG_LOOP: for (base_config.input_sizes) |current_n_size| {
                    var iteration: u32 = 0;
                    while (iteration < base_config.num_iterations) : (iteration += 1) {
                        var current_run_options = base_config;
                        var case_run_name_buf: [256]u8 = undefined;
                        const case_run_name = if (base_config.num_iterations > 1)
                            try std.fmt.bufPrint(&case_run_name_buf, "{s} (N={d}, {s}, Iter {d}/{d})", .{
                                base_config.name,
                                current_n_size,
                                @tagName(base_config.input_type),
                                iteration + 1,
                                base_config.num_iterations,
                            })
                        else
                            try std.fmt.bufPrint(&case_run_name_buf, "{s} (N={d}, {s})", .{
                                base_config.name,
                                current_n_size,
                                @tagName(base_config.input_type),
                            });

                        current_run_options.name = case_run_name;
                        current_run_options.input_sizes = &[_]c_int{current_n_size};
                        current_run_options.verbosity = @enumFromInt(@max(@intFromEnum(base_config.verbosity), @intFromEnum(suite_verbosity)));
                        var case_prng_seed = self.prng_master.int(u64);
                        if (base_config.prng_seed != 0) {
                            case_prng_seed ^= base_config.prng_seed;
                        }
                        case_prng_seed += iteration;
                        var rand = std.Random.DefaultPrng.init(case_prng_seed);
                        var case_prng_instance = rand.random();

                        try logging.log(.Trace, "    Starting test case: {s} with PRNG seed: {d}\n", .{ case_run_name, case_prng_seed });

                        const individual_case_result = adt_tester.runAdtTestCase(
                            self.allocator,
                            suite.adt_builder,
                            current_run_options,
                            &case_prng_instance,
                        ) catch |err| {
                            var temp_err_result = TestCaseResult.init(current_run_options.name, self.allocator);
                            defer temp_err_result.deinit();
                            var err_msg_buf: [128]u8 = undefined;
                            var err_fbs = std.io.fixedBufferStream(&err_msg_buf);
                            errors.formatError(err, err_fbs.writer()) catch {};
                            temp_err_result.recordFailure("Test case execution framework error", err_fbs.getWritten(), null, null);

                            try suite_result.addResult(temp_err_result);
                            if (current_run_options.fail_fast or suite.options.fail_fast_suite) {
                                break;
                            }
                            continue;
                        };

                        try suite_result.addResult(individual_case_result);

                        if (!individual_case_result.passed and (current_run_options.fail_fast or suite.options.fail_fast_suite)) {
                            try logging.log(.Warning, "  FAIL_FAST triggered for: {s}. Stopping further tests in this config/suite.\n", .{current_run_options.name});
                            break :END_SUITE_CONFIG_LOOP;
                        }
                    }
                }
                if (suite_result.failed_tests > 0 and suite.options.fail_fast_suite) {
                    break;
                }
            }
            if (suite.options.print_stats_after_suite) {
                try logging.log(.Debug, "  TrackedItem stats after suite '{s}':\n", .{suite.name});
                tracked_item.printStats();
            }

            try suite_result.printSummary();
            overall_run_result.total_tests += suite_result.total_tests;
            overall_run_result.passed_tests += suite_result.passed_tests;
            overall_run_result.failed_tests += suite_result.failed_tests;
            suite_result.deinit();
        }
        return overall_run_result;
    }
};
