const std = @import("std");
const ArrayList = std.ArrayList;
const CppEntries = @import("./cpp_entries.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var cpp_entries = CppEntries.init(b, .{ .target = target, .optimize = optimize });
    defer cpp_entries.deinit();

    const testing = testing: {
        const testing_module = b.addModule("testing", .{
            .root_source_file = b.path("testing/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        const lib = b.addStaticLibrary(.{
            .name = "testing",
            .root_module = testing_module,
        });

        _ = lib.getEmittedH();

        break :testing lib;
    };

    cpp_entries.add_library(testing);
    cpp_entries.add_entry("a1", b.path("src/a1.cc"));
    cpp_entries.add_entry("a2", b.path("src/a2.cc"));

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(b.getInstallStep());

    for (cpp_entries.entries.items) |entry| {
        const run_cmd = b.addRunArtifact(entry);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        run_step.dependOn(&run_cmd.step);
    }
}
