const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const utils = @import("utils.zig");

const sqids = @import("sqids");
const Sqids = sqids.Sqids;
const testing_allocator = testing.allocator;

test "if no custom blocklist param, use the default blocklist" {
    const s = try Sqids.init(.{});

    try utils.expectDecode(testing_allocator, s, "aho1e", &.{4572721});
    try utils.expectEncode(testing_allocator, s, &.{4572721}, "JExTR");
}

test "if an empty blocklist param passed, don't use any blocklist" {
    const s = try Sqids.init(.{ .blocklist = &.{} });

    try utils.expectEncodeDecodeWithID(testing_allocator, s, &.{4572721}, "aho1e");
}

test "if a non-empty blocklist param passed, use only that" {
    const s = try Sqids.init(.{ .blocklist = &.{"ArUO"} });

    try utils.expectEncodeDecodeWithID(testing_allocator, s, &.{4572721}, "aho1e");

    try utils.expectDecode(testing_allocator, s, "ArUO", &.{100000});
    try utils.expectEncode(testing_allocator, s, &.{100000}, "QyG4");
    try utils.expectDecode(testing_allocator, s, "QyG4", &.{100000});
}

test "blocklist" {
    const s = try Sqids.init(.{
        .blocklist = &.{
            "JSwXFaosAN", // normal result of 1st encoding, let's block that word on purpose
            "OCjV9JK64o", // result of 2nd encoding
            "rBHf", // result of 3rd encoding is `4rBHfOiqd3`, let's block a substring
            "79SM", // result of 4th encoding is `dyhgw479SM`, let's block the postfix
            "7tE6", // result of 4th encoding is `7tE6jdAHLe`, let's block the prefix
        },
    });

    try utils.expectEncodeDecodeWithID(testing_allocator, s, &.{ 1_000_000, 2_000_000 }, "1aYeB7bRUt");
}

test "decoding blocklist words should still work" {
    const s = try Sqids.init(.{
        .blocklist = &.{
            "86Rf07",
            "se8ojk",
            "ARsz1p",
            "Q8AI49",
            "5sQRZO",
        },
    });

    try utils.expectDecode(testing_allocator, s, "86Rf07", &.{ 1, 2, 3 });
    try utils.expectDecode(testing_allocator, s, "se8ojk", &.{ 1, 2, 3 });
    try utils.expectDecode(testing_allocator, s, "ARsz1p", &.{ 1, 2, 3 });
    try utils.expectDecode(testing_allocator, s, "Q8AI49", &.{ 1, 2, 3 });
    try utils.expectDecode(testing_allocator, s, "5sQRZO", &.{ 1, 2, 3 });
}

test "match against a short blocklist word" {
    const s = try Sqids.init(.{
        .blocklist = &.{"pnd"},
    });

    try utils.expectEncodeDecode(testing_allocator, s, &.{1000});
}

test "blocklist filtering in constructor" {
    const s = try Sqids.init(.{
        .alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        .blocklist = &.{"sxnzkl"},
    });

    try utils.expectEncodeDecodeWithID(testing_allocator, s, &.{ 1, 2, 3 }, "IBSHOZ"); // without blocklist, would've been "SXNZKL"
}

test "max encoding attempts" {
    // Setup encoder such that alphabet.len == min_length == blocklist.len
    const s = try Sqids.init(.{
        .alphabet = "abc",
        .min_length = 3,
        .blocklist = &.{ "cab", "abc", "bca" },
    });

    const err = s.encode(testing_allocator, &.{0}) catch |err| err;
    try testing.expectError(sqids.Error.ReachedMaxAttempts, err);
}
