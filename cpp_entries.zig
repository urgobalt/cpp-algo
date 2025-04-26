const CppEntries = @This();

const std = @import("std");
const ArrayList = std.ArrayList;

b: *std.Build,
target: std.Build.ResolvedTarget,
optimize: std.builtin.OptimizeMode,
libraries: ArrayList(CppLibrary),
entries: ArrayList(*std.Build.Step.Compile),

const default_header_extensions = [_][]const u8{ ".h", ".hpp" };

const CppLibraryType = enum {
    obj,
    cpp,
    zig,
};

pub fn CppLibrary(self: CppEntries, library_type: CppLibraryType) type {
    struct {
        step: *std.Build.Step.Compile,
        type: CppLibraryType = library_type,

        const HeaderOptions = switch (library_type) {
            .cpp | .obj => struct {
                root_directory: []const u8,
                extensions: ?[]const []const u8,
            },
            .zig => struct {},
        };

        pub fn install_headers(library: @This(), options: HeaderOptions) void {
            comptime switch (library_type) {
                .cpp | .obj => install_headers_in_dir(self.b, options),
                .zig => {
                    _ = library.step.getEmittedH();
                },
            };
        }

        fn install_headers_in_dir(b: *std.Build, options: HeaderOptions) void {
            const header_extensions = options.extensions orelse &default_header_extensions;

            var dir = try std.fs.cwd().openDir(options.root_directory, .{ .iterate = true });
            var walker = dir.walk(b.allocator) catch @panic("OOM");
            defer walker.deinit();

            while (try walker.next()) |entry| {
                const ext = std.fs.path.extension(entry.basename);
                const include_file = for (header_extensions) |rext| {
                    if (std.mem.eql(u8, ext, rext)) break true;
                } else false;

                const path = path: {
                    const parts = [_][]const u8{ options.root_directory, entry.path };
                    break :path std.fs.path.join(b.allocator, &parts) catch @panic("OOM");
                };

                if (include_file) {
                    b.installFile(path, std.mem.join(self.b.allocator, "/", &[_][]const u8{ "include", entry.basename }) catch @panic("OOM"));
                }
            }
        }
    };
}

const cflags = [_][]const u8{
    "-pedantic-errors",
    "-Wc++11-extensions",
    "-std=c++17",
    "-g",
};

const CppEntriesOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

pub fn init(
    b: *std.Build,
    options: CppEntriesOptions,
) CppEntries {
    const libraries = ArrayList(CppLibrary).init(b.allocator);
    const entries = ArrayList(*std.Build.Step.Compile).init(b.allocator);

    return .{
        .b = b,
        .target = options.target,
        .optimize = options.optimize,
        .libraries = libraries,
        .entries = entries,
    };
}

pub fn deinit(self: CppEntries) void {
    self.libraries.deinit();
    self.entries.deinit();
}

const CppLibraryOptions = struct {
    name: []const u8,
    entry_path: std.Build.LazyPath,
    root_header_files: []const u8,
};

pub fn add_library(self: *CppEntries, library: *std.Build.Step.Compile) void {
    const testing_module = self.b.addModule("testing", .{
        .root_source_file = self.b.path("testing/main.zig"),
        .target = self.target,
        .optimize = self.optimize,
    });

    const lib = self.b.addStaticLibrary(.{
        .name = "testing",
        .root_module = testing_module,
    });

    _ = lib.getEmittedH();

    self.libraries.append(library) catch @panic("OOM");
}

pub fn add_cpp_library_step(self: *CppEntries, lib_opts: CppLibraryOptions) !void {
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

    self.libraries.append(library) catch @panic("OOM");
}

pub fn add_entry(self: *CppEntries, name: []const u8, file: std.Build.LazyPath) void {
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
