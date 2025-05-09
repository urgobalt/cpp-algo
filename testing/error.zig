const std = @import("std");

const c = @cImport({
    @cInclude("testing");
});

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
        else=>c.ADT_RESULT_ERROR_OTHER,
    };
}

pub fn formatError(err: anyerror, writer: anytype) !void {
    switch (err) {
        AdtError.NullPtr => try writer.writeAll("AdtError.NullPtr"),
        AdtError.Empty => try writer.writeAll("AdtError.Empty"),
        AdtError.Alloc => try writer.writeAll("AdtError.Alloc"),
        AdtError.InvalidHandle => try writer.writeAll("AdtError.InvalidHandle"),
        AdtError.Other => try writer.writeAll("AdtError.Other"),
        FrameworkError.VerificationFailed => try writer.writeAll("FrameworkError.VerificationFailed"),
        FrameworkError.Timeout => try writer.writeAll("FrameworkError.Timeout"),
        FrameworkError.InvalidInputConfiguration => try writer.writeAll("FrameworkError.InvalidInputConfiguration"),
        FrameworkError.InputGenerationFailed => try writer.writeAll("FrameworkError.InputGenerationFailed"),
        FrameworkError.TestLogicError => try writer.writeAll("FrameworkError.TestLogicError"),
        else => try writer.print("Unknown error: {any}", .{err}),
    }
}
