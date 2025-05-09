const std = @import("std");
const adt_options = @import("adt_options.zig");
const LogLevel = adt_options.Verbosity;
const errors = @import("error.zig");

pub var logging_level: LogLevel = LogLevel.Error;
pub fn log(level: LogLevel, comptime format: []const u8, args: anytype) errors.TestingError!void {
    if (@intFromEnum(level) >= @intFromEnum(logging_level)) {
        switch (level) {
            .Error => {
                std.log.err(format, args);
            },
            .Warning => {
                std.log.warn(format, args);
            },
            .Info => {
                std.log.info(format, args);
            },
            .Debug => {
                std.debug.print(format, args);
            },
            .Trace => {
                std.debug.print(format, args);
            },
            .Quiet => {
                // never push here
            },
            else => {},
        }
    }
    return;
}
