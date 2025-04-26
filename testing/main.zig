const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub export fn test_file() void {
    _ = stdout.write("Hello world is being tested!") catch @panic("Failed writing to stdout");
}
