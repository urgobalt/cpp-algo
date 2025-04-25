const std = @import("std");
const ArrayList = std.ArrayList;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var cpp_entries = CppEntries.init(b, .{ .target = target, .optimize = optimize });
    defer cpp_entries.deinit();

    try cpp_entries.add_library(.{
        .name = "testing",
        .entry_path = b.path("testing/lib.cc"),
        .root_header_files = "testing",
    });

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

const CppEntries = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    header_extensions: []const []const u8,
    libraries: ArrayList(*std.Build.Step.Compile),
    entries: ArrayList(*std.Build.Step.Compile),

    const cflags = [_][]const u8{
        "-pedantic-errors",
        "-Wc++11-extensions",
        "-std=c++17",
        "-g",
    };

    const CppEntriesOptions = struct {
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
        header_extensions: ?[]const []const u8 = null,
    };

    fn init(
        b: *std.Build,
        options: CppEntriesOptions,
    ) @This() {
        const libraries = ArrayList(*std.Build.Step.Compile).init(b.allocator);
        const entries = ArrayList(*std.Build.Step.Compile).init(b.allocator);

        return .{
            .b = b,
            .target = options.target,
            .optimize = options.optimize,
            .header_extensions = options.header_extensions orelse &[_][]const u8{ ".h", ".hpp" },
            .libraries = libraries,
            .entries = entries,
        };
    }

    fn deinit(self: @This()) void {
        self.libraries.deinit();
        self.entries.deinit();
    }

    const LibraryOptions = struct {
        name: []const u8,
        entry_path: std.Build.LazyPath,
        root_header_files: []const u8,
    };

    fn add_library(self: *@This(), lib_opts: LibraryOptions) !void {
        const root_module = self.b.createModule(.{
            .target = self.target,
            .optimize = self.optimize,
            .link_libcpp = true,
            .pic = true,
        });

        root_module.addCSourceFile(.{
            .file = lib_opts.entry_path,
            .flags = &cflags,
        });

        const library = self.b.addLibrary(.{
            .name = lib_opts.name,
            .root_module = root_module,
        });

        self.b.installArtifact(library);

        var dir = try std.fs.cwd().openDir(lib_opts.root_header_files, .{ .iterate = true });
        var walker = dir.walk(self.b.allocator) catch @panic("OOM");
        defer walker.deinit();

        while (try walker.next()) |entry| {
            const ext = std.fs.path.extension(entry.basename);
            const include_file = for (self.header_extensions) |rext| {
                if (std.mem.eql(u8, ext, rext)) break true;
            } else false;

            const path = path: {
                const parts = [_][]const u8{ lib_opts.root_header_files, entry.path };
                break :path std.fs.path.join(self.b.allocator, &parts) catch @panic("OOM");
            };

            if (include_file) {
                self.b.installFile(path, std.mem.join(self.b.allocator, "/", &[_][]const u8{ "include", entry.basename }) catch @panic("OOM"));
            }
        }

        self.libraries.append(library) catch @panic("OOM");
    }

    fn add_entry(self: *@This(), name: []const u8, file: std.Build.LazyPath) void {
        const entry = self.b.addExecutable(.{
            .name = name,
            .root_source_file = null,
            .target = self.target,
            .optimize = self.optimize,
        });

        entry.addCSourceFile(.{
            .file = file,
            .flags = &cflags,
        });

        entry.addIncludePath(self.b.path("zig-out/include"));
        entry.linkLibCpp();

        for (self.libraries.items) |library| {
            entry.linkLibrary(library);
        }

        self.b.installArtifact(entry);

        self.entries.append(entry) catch @panic("OOM");
    }
};
