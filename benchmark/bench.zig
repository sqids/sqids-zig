const std = @import("std");
const sqids = @import("sqids");
const mem = std.mem;

const numbers_file = @import("numbers.zig");
const numbers = numbers_file.numbers;

const Sqids = sqids.Sqids;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const opts = sqids.Options{ .blocklist = undefined };

    var ids = try allocator.alloc([]const u8, numbers.len);

    // Using the default Sqids, encode the numbers to a Sqids ID.
    const s = try Sqids.init(allocator, opts);
    defer s.deinit();

    for (numbers, 0..) |ns, i| {
        const id = try s.encode(&ns);
        ids[i] = id;
    }

    allocator.free(ids);
}
