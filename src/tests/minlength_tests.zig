const std = @import("std");
const mem = std.mem;
const testing = std.testing;

// So verbose...
const sqids = @import("main.zig");
const Squids = sqids.Sqids;
const testing_allocator = testing.allocator;
