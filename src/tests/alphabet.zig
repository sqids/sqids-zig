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
    const err = Squids.init(testing_allocator, .{ .alphabet = "ë1092" }) catch |err| err;
    try testing.expectError(sqids.Error.NonASCIICharacter, err);
}

test "repeating alphabet characters" {
    const err = Squids.init(testing_allocator, .{ .alphabet = "aabcdefg" }) catch |err| err;
    try testing.expectError(sqids.Error.RepeatingAlphabetCharacter, err);
}

test "too short of an alphabet" {
    const err = Squids.init(testing_allocator, .{ .alphabet = "ab" }) catch |err| err;
    try testing.expectError(sqids.Error.TooShortAlphabet, err);
}
