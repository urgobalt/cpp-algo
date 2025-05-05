const std = @import("std");

pub const comm = @cImport({
    @cInclude("testing");
});
fn start() !void {}
