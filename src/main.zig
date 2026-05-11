const std = @import("std");
const sqids = @import("sqids");
const mem = std.mem;

const Sqids = sqids.Sqids;

pub fn main(init: std.process.Init) !void {
    var arena = init.arena;
    const allocator = arena.allocator();

    const numbers = &.{ 1, 2, 3 };

    // Using the default Sqids, encode the numbers to a Sqids ID.
    const s = try Sqids.new(.{});
    const id = try s.encode(allocator, numbers);
    defer allocator.free(id);

    // Print to stdout.
    std.debug.print("{s}\n", .{id});
}
