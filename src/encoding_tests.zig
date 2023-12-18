const std = @import("std");
const mem = std.mem;
const testing = std.testing;

// So verbose...
const sqids = @import("main.zig");
const Squids = sqids.Sqids;
const testing_allocator = testing.allocator;

fn expectEncodeDecode(
    allocator: mem.Allocator,
    s: Squids,
    numbers: []const u64,
    id: []const u8,
) !void {
    // Test encoding.
    const obtained_id = try s.encode(numbers);
    defer allocator.free(obtained_id);
    try testing.expectEqualStrings(id, obtained_id);

    // Test decoding back.
    const obtained_numbers = try s.decode(obtained_id);
    defer allocator.free(obtained_numbers);
    try testing.expectEqualSlices(u64, numbers, obtained_numbers);
}

test "default encoder: encode incremental numbers" {
    const s = try Squids.init(testing_allocator, .{});
    defer s.deinit();

    var cases = std.StringHashMap([]const u64).init(testing_allocator);
    defer cases.deinit();

    // Simple.
    try cases.put("86Rf07", &.{ 1, 2, 3 });

    // Incremental numbers.
    try cases.put("bM", &.{0});
    try cases.put("Uk", &.{1});
    try cases.put("gb", &.{2});
    try cases.put("Ef", &.{3});
    try cases.put("Vq", &.{4});
    try cases.put("uw", &.{5});
    try cases.put("OI", &.{6});
    try cases.put("AX", &.{7});
    try cases.put("p6", &.{8});
    try cases.put("nJ", &.{9});

    // Incremental numbers, same index zero.
    try cases.put("SvIz", &.{ 0, 0 });
    try cases.put("n3qa", &.{ 0, 1 });
    try cases.put("tryF", &.{ 0, 2 });
    try cases.put("eg6q", &.{ 0, 3 });
    try cases.put("rSCF", &.{ 0, 4 });
    try cases.put("sR8x", &.{ 0, 5 });
    try cases.put("uY2M", &.{ 0, 6 });
    try cases.put("74dI", &.{ 0, 7 });
    try cases.put("30WX", &.{ 0, 8 });
    try cases.put("moxr", &.{ 0, 9 });

    // Incremental numbers, same index 1.
    try cases.put("SvIz", &.{ 0, 0 });
    try cases.put("nWqP", &.{ 1, 0 });
    try cases.put("tSyw", &.{ 2, 0 });
    try cases.put("eX68", &.{ 3, 0 });
    try cases.put("rxCY", &.{ 4, 0 });
    try cases.put("sV8a", &.{ 5, 0 });
    try cases.put("uf2K", &.{ 6, 0 });
    try cases.put("7Cdk", &.{ 7, 0 });
    try cases.put("3aWP", &.{ 8, 0 });
    try cases.put("m2xn", &.{ 9, 0 });

    var it = cases.iterator();
    while (it.next()) |e| {
        const id = e.key_ptr.*;
        const numbers = e.value_ptr.*;

        try expectEncodeDecode(testing_allocator, s, numbers, id);
    }
}

test "default encoder: multi input" {
    const s = try Squids.init(testing_allocator, .{});
    defer s.deinit();

    const numbers = [2][]const u64{
        &.{ 0, 0, 0, 1, 2, 3, 100, 1_000, 100_000, 1_000_000, std.math.maxInt(u64) },
        &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99 },
    };

    for (numbers) |n| {
        const tmp_id = try s.encode(n);
        defer testing_allocator.free(tmp_id);
        const dec_output = try s.decode(tmp_id);
        defer testing_allocator.free(dec_output);

        try testing.expectEqualSlices(u64, n, dec_output);
    }
}

test "default encoder: encoding no numbers" {
    const s = try Squids.init(testing_allocator, .{});
    defer s.deinit();

    const output = try s.encode(&.{});
    try testing.expectEqualStrings("", output);
    testing_allocator.free(output);
}

test "default encoder: decoding empty string" {
    const s = try Squids.init(testing_allocator, .{});
    defer s.deinit();

    const output = try s.decode("");
    try testing.expectEqualSlices(u64, &.{}, output);
    testing_allocator.free(output);
}

test "default encoder: decoding ID with invalid character" {
    const s = try Squids.init(testing_allocator, .{});
    defer s.deinit();

    const output = try s.decode("*");
    try testing.expectEqualSlices(u64, &.{}, output);
    testing_allocator.free(output);
}

test "default encoder: encode out-of-range numbers" {
    // Unnecessary: type system enforce u64 range.
}
