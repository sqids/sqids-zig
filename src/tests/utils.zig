const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const sqids = @import("sqids");
const Squids = sqids.Sqids;

pub fn expectEncodeDecode(
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
