const std = @import("std");
const sqids = @import("sqids");
const mem = std.mem;

const Sqids = sqids.Sqids;

pub fn main() !void {
    // const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const opts = sqids.Options{};

    const n = 1000;
    var ids = try allocator.alloc([]const u8, n);

    // Using the default Sqids, encode the numbers to a Sqids ID.
    const s = try Sqids.init(allocator, opts);
    defer s.deinit();
    for (0..n, 0..) |x, i| {
        const id = try s.encode(&.{ x, x + 1, x + 2 });
        ids[i] = id;

        // Print to stdout.
        // try stdout.print("{s}\n", .{id});
    }

    allocator.free(ids);
}
