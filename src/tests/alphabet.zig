const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const utils = @import("utils.zig");

const sqids = @import("sqids");
const Squids = sqids.Sqids;
const testing_allocator = testing.allocator;

test "simple" {
    const s = try Squids.init(testing_allocator, .{ .alphabet = "0123456789abcdef" });
    defer s.deinit();
    try utils.expectEncodeDecodeWithID(testing_allocator, s, &.{ 1, 2, 3 }, "489158");
}

test "short" {
    const s = try Squids.init(testing_allocator, .{ .alphabet = "abc" });
    defer s.deinit();
    try utils.expectEncodeDecode(testing_allocator, s, &.{ 1, 2, 3 });
}
test "long" {
    const alphabet =
        \\abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:\'"/?.>,<`~
    ;
    const s = try Squids.init(testing_allocator, .{ .alphabet = alphabet });
    defer s.deinit();
    try utils.expectEncodeDecode(testing_allocator, s, &.{ 1, 2, 3 });
}

test "multibyte alphabet" {
    // Mark as failing, since, this is not properly handled by the library.
    const s = try Squids.init(testing_allocator, .{ .alphabet = "ë1092" });
    defer s.deinit();
    try testing.expect(false);
}

test "repeating alphabet characters" {
    // Mark as failing, since, this is not properly handled by the library.
    const s = try Squids.init(testing_allocator, .{ .alphabet = "aabcdefg" });
    defer s.deinit();
    try testing.expect(false);
}

test "too short of an alphabet" {
    // Mark as failing, since, this is not properly handled by the library.
    const s = try Squids.init(testing_allocator, .{ .alphabet = "ab" });
    defer s.deinit();
    try testing.expect(false);
}
