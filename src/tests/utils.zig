const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const Sqids = @import("sqids").Sqids;

pub fn expectEncode(
    allocator: mem.Allocator,
    s: Sqids,
    numbers: []const u64,
    id: []const u8,
) !void {
    const got = try s.encode(allocator, numbers);
    defer allocator.free(got);

    try testing.expectEqualStrings(id, got);
}

pub fn expectDecode(
    allocator: mem.Allocator,
    s: Sqids,
    id: []const u8,
    numbers: []const u64,
) !void {
    const got = try s.decode(allocator, id);
    defer allocator.free(got);

    try testing.expectEqualSlices(u64, numbers, got);
}

pub fn expectEncodeDecode(
    allocator: mem.Allocator,
    s: Sqids,
    numbers: []const u64,
) !void {
    const id = try s.encode(allocator, numbers);
    defer allocator.free(id);
    const obtained_numbers = try s.decode(allocator, id);
    defer allocator.free(obtained_numbers);

    try testing.expectEqualSlices(u64, numbers, obtained_numbers);
}

pub fn expectEncodeDecodeWithID(
    allocator: mem.Allocator,
    s: Sqids,
    numbers: []const u64,
    id: []const u8,
) !void {
    // Test encoding.
    const obtained_id = try s.encode(allocator, numbers);
    defer allocator.free(obtained_id);
    try testing.expectEqualStrings(id, obtained_id);

    // Test decoding back.
    const obtained_numbers = try s.decode(allocator, obtained_id);
    defer allocator.free(obtained_numbers);
    try testing.expectEqualSlices(u64, numbers, obtained_numbers);
}
