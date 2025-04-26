const CppEntries = @This();

const std = @import("std");
const ArrayList = std.ArrayList;

b: *std.Build,
target: std.Build.ResolvedTarget,
optimize: std.builtin.OptimizeMode,
libraries: ArrayList(*CppLibrary),
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
};

pub fn init(
    b: *std.Build,
    options: CppEntriesOptions,
) CppEntries {
    const libraries = ArrayList(*CppLibrary).init(b.allocator);
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
    for (self.libraries.items) |lib| {
        self.b.allocator.destroy(lib);
    }
    self.libraries.deinit();
    self.entries.deinit();
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
        entry.linkLibrary(library.step);
    }

    self.b.installArtifact(entry);

    self.entries.append(entry) catch @panic("OOM");
}

pub fn install_zig_library(self: *CppEntries, name: []const u8, options: std.Build.Module.CreateOptions) *CppLibrary {
    const module = self.b.createModule(options);

    const library = self.b.addLibrary(.{
        .name = name,
        .root_module = module,
    });

    self.b.installArtifact(library);

    const wrapper = self.b.allocator.create(CppLibrary) catch @panic("OOM");
    wrapper.* = CppLibrary{
        .step = library,
        .type = .zig,
    };
    self.libraries.append(wrapper) catch @panic("OOM");
    return wrapper;
}

pub fn install_cpp_library(self: *CppEntries, name: []const u8, file: std.Build.LazyPath) *CppLibrary {
    const root_module = self.b.createModule(.{
        .target = self.target,
        .optimize = self.optimize,
        .link_libcpp = true,
        .pic = true,
    });

    root_module.addCSourceFile(.{
        .file = file,
        .flags = &cflags,
    });

    const library = self.b.addLibrary(.{
        .name = name,
        .root_module = root_module,
    });

    self.b.installArtifact(library);

    const wrapper = self.b.allocator.create(CppLibrary) catch @panic("OOM");
    wrapper.* = CppLibrary{
        .step = library,
        .type = .cpp,
    };
    self.libraries.append(wrapper) catch @panic("OOM");
    return wrapper;
}

const default_header_extensions = [_][]const u8{ ".h", ".hpp" };

const CppLibrary = struct {
    step: *std.Build.Step.Compile,
    type: CppLibraryType,
    options: ?HeaderOptions = null,

    const HeaderOptions = struct {
        root_directory: []const u8,
        extensions: ?[]const []const u8,
        build: *std.Build,
    };

    const CppLibraryType = enum {
        obj,
        cpp,
        zig,
    };

    pub fn configure(self: *CppLibrary, options: HeaderOptions) void {
        self.options = options;
    }

    pub fn install_headers(self: *CppLibrary) !void {
        switch (self.type) {
            .cpp, .obj => {
                if (self.options == null) {
                    @panic("Please run `configure` before running `install_headers`");
                }
                const options = self.options.?;
                const header_extensions = options.extensions orelse &default_header_extensions;

                var dir = try std.fs.cwd().openDir(options.root_directory, .{ .iterate = true });
                var walker = dir.walk(options.build.allocator) catch @panic("OOM");
                defer walker.deinit();

                while (try walker.next()) |entry| {
                    const ext = std.fs.path.extension(entry.basename);
                    const include_file = for (header_extensions) |rext| {
                        if (std.mem.eql(u8, ext, rext)) break true;
                    } else false;

                    const path = path: {
                        const parts = [_][]const u8{ options.root_directory, entry.path };
                        break :path std.fs.path.join(options.build.allocator, &parts) catch @panic("OOM");
                    };

                    if (include_file) {
                        options.build.installFile(path, std.mem.join(options.build.allocator, "/", &[_][]const u8{ "include", entry.basename }) catch @panic("OOM"));
                    }
                }
            },
            .zig => {
                _ = self.step.getEmittedH();
            },
        }
    }
};
