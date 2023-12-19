//! Root test file.

comptime {
    _ = @import("encoding_tests.zig");
    _ = @import("minlength_tests.zig");
    _ = @import("alphabet.zig");
    _ = @import("blocklist.zig");
}
