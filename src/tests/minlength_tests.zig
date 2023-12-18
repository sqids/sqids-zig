const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const utils = @import("utils.zig");

const sqids = @import("sqids");
const Squids = sqids.Sqids;
const testing_allocator = testing.allocator;

test "min length: incremental min length" {
    var map = std.AutoHashMap(u8, []const u8).init(testing_allocator);
    defer map.deinit();

    const numbers = [_]u64{ 1, 2, 3 };

    // Simple.
    try map.put(sqids.default_alphabet.len, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM");

    // Incremental.
    try map.put(6, "86Rf07");
    try map.put(7, "86Rf07x");
    try map.put(8, "86Rf07xd");
    try map.put(9, "86Rf07xd4");
    try map.put(10, "86Rf07xd4z");
    try map.put(11, "86Rf07xd4zB");
    try map.put(12, "86Rf07xd4zBm");
    try map.put(13, "86Rf07xd4zBmi");

    try map.put(sqids.default_alphabet.len + 0, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTM");
    try map.put(sqids.default_alphabet.len + 1, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMy");
    try map.put(sqids.default_alphabet.len + 2, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf");
    try map.put(sqids.default_alphabet.len + 3, "86Rf07xd4zBmiJXQG6otHEbew02c3PWsUOLZxADhCpKj7aVFv9I8RquYrNlSTMyf1");

    var it = map.iterator();
    while (it.next()) |e| {
        const min_length = e.key_ptr.*;
        const id = e.value_ptr.*;
        const s = try Squids.init(testing_allocator, .{ .min_length = min_length });
        defer s.deinit();

        const got_id = try s.encode(&numbers);
        defer testing_allocator.free(got_id);
        try testing.expect(min_length == got_id.len);

        try utils.expectEncodeDecode(testing_allocator, s, &numbers, id);
    }
}

test "min length: incremental numbers" {
    const s = try Squids.init(testing_allocator, .{ .min_length = sqids.default_alphabet.len });
    defer s.deinit();

    var ids = std.StringArrayHashMap([]const u64).init(testing_allocator);
    defer ids.deinit();

    try ids.put("SvIzsqYMyQwI3GWgJAe17URxX8V924Co0DaTZLtFjHriEn5bPhcSkfmvOslpBu", &.{ 0, 0 });
    try ids.put("n3qafPOLKdfHpuNw3M61r95svbeJGk7aAEgYn4WlSjXURmF8IDqZBy0CT2VxQc", &.{ 0, 1 });
    try ids.put("tryFJbWcFMiYPg8sASm51uIV93GXTnvRzyfLleh06CpodJD42B7OraKtkQNxUZ", &.{ 0, 2 });
    try ids.put("eg6ql0A3XmvPoCzMlB6DraNGcWSIy5VR8iYup2Qk4tjZFKe1hbwfgHdUTsnLqE", &.{ 0, 3 });
    try ids.put("rSCFlp0rB2inEljaRdxKt7FkIbODSf8wYgTsZM1HL9JzN35cyoqueUvVWCm4hX", &.{ 0, 4 });
    try ids.put("sR8xjC8WQkOwo74PnglH1YFdTI0eaf56RGVSitzbjuZ3shNUXBrqLxEJyAmKv2", &.{ 0, 5 });
    try ids.put("uY2MYFqCLpgx5XQcjdtZK286AwWV7IBGEfuS9yTmbJvkzoUPeYRHr4iDs3naN0", &.{ 0, 6 });
    try ids.put("74dID7X28VLQhBlnGmjZrec5wTA1fqpWtK4YkaoEIM9SRNiC3gUJH0OFvsPDdy", &.{ 0, 7 });
    try ids.put("30WXpesPhgKiEI5RHTY7xbB1GnytJvXOl2p0AcUjdF6waZDo9Qk8VLzMuWrqCS", &.{ 0, 8 });
    try ids.put("moxr3HqLAK0GsTND6jowfZz3SUx7cQ8aC54Pl1RbIvFXmEJuBMYVeW9yrdOtin", &.{ 0, 9 });

    var it = ids.iterator();
    while (it.next()) |e| {
        const id = e.key_ptr.*;
        const numbers = e.value_ptr.*;
        try utils.expectEncodeDecode(testing_allocator, s, numbers, id);
    }
}

test "min length: various" {
    const min_lengths = [_]u8{ 0, 1, 5, 10, sqids.default_alphabet.len };
    const numbers = [_][]const u64{
        &.{0},
        &.{ 0, 0, 0, 0, 0 },
        &.{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 },
        &.{ 100, 200, 300 },
        &.{ 1_000, 2_000, 3_000 },
        &.{1_000_000},
        &.{std.math.maxInt(u64)},
    };

    for (min_lengths) |min_length| {
        const s = try Squids.init(testing_allocator, .{ .min_length = min_length });
        defer s.deinit();
        for (numbers) |ns| {
            const id = try s.encode(ns);
            defer testing_allocator.free(id);

            try testing.expect(id.len >= min_length);

            const got_numbers = try s.decode(id);
            defer testing_allocator.free(got_numbers);

            try testing.expectEqualSlices(u64, ns, got_numbers);
        }
    }
}
