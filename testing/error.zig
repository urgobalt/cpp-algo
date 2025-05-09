const std = @import("std");

const c = @cImport({
    @cInclude("testing");
});
const logging = @import("logging.zig");
pub const AdtError = error{
    NullPtr,
    Empty,
    Alloc,
    InvalidHandle,
    Other,
};

pub const FrameworkError = error{
    VerificationFailed,
    Timeout,
    InvalidInputConfiguration,
    InputGenerationFailed,
    TestLogicError,
};

pub const TestingError = AdtError || FrameworkError;

pub inline fn asTestingError(code: c_int) !void {
    if (code == c.ADT_RESULT_SUCCESS) return;
    return fromCErrorCode(code);
}

pub inline fn fromCErrorCode(code: c_int) AdtError {
    return switch (code) {
        c.ADT_RESULT_ERROR_NULL_PTR => AdtError.NullPtr,
        c.ADT_RESULT_ERROR_EMPTY => AdtError.Empty,
        c.ADT_RESULT_ERROR_ALLOC => AdtError.Alloc,
        c.ADT_RESULT_ERROR_INVALID_HANDLE => AdtError.InvalidHandle,
        else => AdtError.Other,
    };
}

pub inline fn unwrapTesting(comptime ReturnType: type, success_payload: ReturnType, code: c_int) TestingError!ReturnType {
    if (code == c.ADT_RESULT_SUCCESS) {
        return success_payload;
    }
    return fromCErrorCode(code);
}

pub inline fn testingErrorToCInt(err: TestingError) c_int {
    return switch (err) {
        AdtError.NullPtr => c.ADT_RESULT_ERROR_NULL_PTR,
        AdtError.Empty => c.ADT_RESULT_ERROR_EMPTY,
        AdtError.Alloc => c.ADT_RESULT_ERROR_ALLOC,
        AdtError.InvalidHandle => c.ADT_RESULT_ERROR_INVALID_HANDLE,
        AdtError.Other => c.ADT_RESULT_ERROR_OTHER,
        else => c.ADT_RESULT_ERROR_OTHER,
    };
}

pub fn formatError(err: anyerror) !void {
    switch (err) {
        AdtError.NullPtr => try logging.log(.Error, "AdtError.NullPtr", .{}),
        AdtError.Empty => try logging.log(.Error, "AdtError.Empty", .{}),
        AdtError.Alloc => try logging.log(.Error, "AdtError.Alloc", .{}),
        AdtError.InvalidHandle => try logging.log(.Error, "AdtError.InvalidHandle", .{}),
        AdtError.Other => try logging.log(.Error, "AdtError.Other", .{}),
        FrameworkError.VerificationFailed => try logging.log(.Error, "FrameworkError.VerificationFailed", .{}),
        FrameworkError.Timeout => try logging.log(.Error, "FrameworkError.Timeout", .{}),
        FrameworkError.InvalidInputConfiguration => try logging.log(.Error, "FrameworkError.InvalidInputConfiguration", .{}),
        FrameworkError.InputGenerationFailed => try logging.log(.Error, "FrameworkError.InputGenerationFailed", .{}),
        FrameworkError.TestLogicError => try logging.log(.Error, "FrameworkError.TestLogicError", .{}),
        else => try logging.log(.Error, "Unknown error: {any}", .{err}),
    }
}
