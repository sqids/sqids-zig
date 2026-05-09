const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const utils = @import("utils.zig");

const sqids = @import("sqids");
const Sqids = sqids.Sqids;
const testing_allocator = testing.allocator;

test "simple" {
    const s = try Sqids.init(.{ .alphabet = "0123456789abcdef" });
    try utils.expectEncodeDecodeWithID(testing_allocator, s, &.{ 1, 2, 3 }, "489158");
}

test "short" {
    const s = try Sqids.init(.{ .alphabet = "abc" });
    try utils.expectEncodeDecode(testing_allocator, s, &.{ 1, 2, 3 });
}

test "long" {
    const alphabet =
        \\abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_+|{}[];:\'"/?.>,<`~
    ;
    const s = try Sqids.init(.{ .alphabet = alphabet });
    try utils.expectEncodeDecode(testing_allocator, s, &.{ 1, 2, 3 });
}

test "multibyte alphabet" {
    const err = Sqids.init(.{ .alphabet = "ë1092" }) catch |err| err;
    try testing.expectError(sqids.Error.NonASCIICharacter, err);
}

test "repeating alphabet characters" {
    const err = Sqids.init(.{ .alphabet = "aabcdefg" }) catch |err| err;
    try testing.expectError(sqids.Error.RepeatingAlphabetCharacter, err);
}

test "too short of an alphabet" {
    const err = Sqids.init(.{ .alphabet = "ab" }) catch |err| err;
    try testing.expectError(sqids.Error.TooShortAlphabet, err);
}
