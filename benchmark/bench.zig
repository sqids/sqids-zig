const std = @import("std");
const sqids = @import("sqids");
const mem = std.mem;

const numbers_file = @import("numbers.zig");
const numbers = numbers_file.numbers;

const Sqids = sqids.Sqids;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    var ids = try allocator.alloc([]const u8, numbers.len);
    defer allocator.free(ids);

    // Using the default Sqids, encode the numbers to a Sqids ID.
    const s = try Sqids.init(.{ .blocklist = &.{} });

    for (numbers, 0..) |ns, i| {
        const id = try s.encode(allocator, &ns);
        ids[i] = id;
    }

    for (ids) |id| {
        allocator.free(id);
    }
}
