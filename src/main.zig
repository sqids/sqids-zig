const std = @import("std");
const sqids = @import("sqids");
const mem = std.mem;

const Sqids = sqids.Sqids;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const numbers = &.{ 1, 2, 3 };

    const opts = sqids.Options{
        // .blocklist = new_blocklist(allocator, alphabet, blocked_words),
        // .alphabet = alphabet,
    };

    // Using the default Sqids, encode the numbers to a Sqids ID.
    const s = try Sqids.new(opts);
    defer s.deinit();
    const id = try s.encode(numbers);
    defer allocator.free(id);

    // Print to stdout.
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{id});
}
