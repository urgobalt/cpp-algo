const c = @cImport({
    @cInclude("testing");
});
pub const TestingError = error{
    nullPtr,
    empty,
    alloc,
    invalidHandle,
    other,
};

pub inline fn asTestingError(code: c_int) TestingError!void {
    if (code == c.ADT_RESULT_SUCCESS) return;
    return intToTestingError(code);
}

pub inline fn intToTestingError(code: c_int) TestingError {
    return switch (code) {
        c.ADT_RESULT_ERROR_NULL_PTR => TestingError.nullPtr,
        c.ADT_RESULT_ERROR_EMPTY => TestingError.empty,
        c.ADT_RESULT_ERROR_ALLOC => TestingError.alloc,
        c.ADT_RESULT_ERROR_INVALID_HANDLE => TestingError.invalidHandle,
        else => TestingError.other,
    };
}

pub inline fn unwrapTesting(comptime returnType: type, obj: returnType, code: c_int) TestingError!returnType {
    return switch (code) {
        c.ADT_RESULT_SUCCESS => obj,
        else => intToTestingError(code),
    };
}

pub inline fn testingErrorToInt(@"error": TestingError) c_int {
    return switch (@"error") {
        TestingError.nullPtr => c.ADT_RESULT_ERROR_NULL_PTR,
        TestingError.empty => c.ADT_RESULT_ERROR_EMPTY,
        TestingError.alloc => c.ADT_RESULT_ERROR_ALLOC,
        TestingError.invalidHandle => c.ADT_RESULT_ERROR_INVALID_HANDLE,
        TestingError.other => c.ADT_RESULT_ERROR_OTHER,
    };
}
