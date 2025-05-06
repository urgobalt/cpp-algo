const std = @import("std");
const ArrayList = std.ArrayList;
const Compile = std.Build.Step.Compile;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cpp_binaries = CppBinaries.init(.{ .build = b, .target = target, .optimize = optimize });

    const header_file = b.addInstallFileWithDir(b.path("testing/testing.h"), .header, "testing");
    const impl_header_files = b.addInstallDirectory(.{
        .source_dir = b.path("impls"),
        .install_dir = .header,
        .install_subdir = "impls",
    });

    const testing_lib = testing_lib: {
        const module = b.createModule(.{
            .root_source_file = b.path("testing/main.zig"),
            .optimize = optimize,
            .target = target,
            .link_libc = true,
        });

        module.addIncludePath(b.path("zig-out/include"));

        const lib = b.addLibrary(.{
            .name = "testing",
            .root_module = module,
            .linkage = .static,
        });

        lib.step.dependOn(&header_file.step);
        b.installArtifact(lib);

        break :testing_lib lib;
    };

    const a1 = cpp_binaries.create_cpp_exe("a1", b.path("./src/a1.cc"));
    const b2 = cpp_binaries.create_cpp_exe("b2", b.path("./src/b2.cc"));
    b2.linkLibrary(testing_lib);
    b2.step.dependOn(&header_file.step);
    b2.step.dependOn(&impl_header_files.step);
    b2.addIncludePath(b.path("zig-out/include"));

    const run = b.step("run", "Run all the binaries built");
    run.dependOn(&b.addRunArtifact(a1).step);
    run.dependOn(&b.addRunArtifact(b2).step);
}

const CppBinaries = struct {
    build: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,

    pub fn init(options: struct {
        build: *std.Build,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
    }) @This() {
        return .{
            .build = options.build,
            .optimize = options.optimize,
            .target = options.target,
        };
    }

    const cflags = [_][]const u8{
        "-pedantic-errors",
        "-Wc++11-extensions",
        "-std=c++20",
        "-g",
    };

    pub fn create_cpp_exe(self: @This(), name: []const u8, root_source_file: std.Build.LazyPath) *Compile {
        const module = self.build.createModule(.{
            .root_source_file = null,
            .optimize = self.optimize,
            .target = self.target,
            .link_libcpp = true,
        });

        module.addCSourceFile(.{
            .file = root_source_file,
            .flags = &cflags,
            .language = .cpp,
        });

        const exe = self.build.addExecutable(.{
            .name = name,
            .root_module = module,
        });

        self.build.installArtifact(exe);

        return exe;
    }
};
