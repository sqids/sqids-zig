//! Module sqids-zig implements encoding and decoding of sqids identifiers. See sqids.org.
const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const ArrayList = std.ArrayList;
const ArrayListUnmanaged = std.ArrayListUnmanaged;

pub const Error = error{
    TooShortAlphabet,
    NonASCIICharacter,
    RepeatingAlphabetCharacter,
    ReachedMaxAttempts,
};

const blocklist_module = @import("blocklist.zig");
pub const default_blocklist = blocklist_module.default_blocklist;

/// The default alphabet for sqids.
pub const default_alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

/// Options controls the configuration of the sqid encoder.
pub const Options = struct {
    alphabet: []const u8 = default_alphabet,
    blocklist: []const []const u8 = &default_blocklist,
    min_length: u8 = 0,
};

/// Sqids encoder.
/// Must be initialized with init and free with deinit methods.
pub const Sqids = struct {
    allocator: mem.Allocator,
    alphabet: []const u8,
    arena: std.heap.ArenaAllocator,
    blocklist: []const []const u8,
    min_length: u8,

    pub fn init(allocator: mem.Allocator, opts: Options) !Sqids {
        // Check alphabet.
        // TODO(lvignoli): it would be better to "parse not validate", for both the alphabet and the blocklist.
        if (opts.alphabet.len < 3) {
            return Error.TooShortAlphabet;
        }
        for (opts.alphabet) |c| {
            if (!std.ascii.isASCII(c)) {
                return Error.NonASCIICharacter;
            }
            if (mem.count(u8, opts.alphabet, &.{c}) > 1) {
                return Error.RepeatingAlphabetCharacter;
            }
        }

        // Create blocklist from provided words.
        // We use an arena to manage the memory of the blocklist
        var arena = std.heap.ArenaAllocator.init(allocator);
        const b = try blocklist_from_words(arena.allocator(), opts.alphabet, opts.blocklist);
        return Sqids{
            .allocator = allocator,
            .alphabet = opts.alphabet,
            .arena = arena,
            .blocklist = b,
            .min_length = opts.min_length,
        };
    }

    pub fn deinit(self: Sqids) void {
        self.arena.deinit();
    }

    /// Encodes a list of numbers into a sqids ID. Caller owns the memory.
    pub fn encode(self: Sqids, numbers: []const u64) ![]const u8 {
        if (numbers.len == 0) {
            return "";
        }
        // Allocate ID buffer and working alphabet.
        const estimated_buffer_size = estimateEncodingBufferSize(self.alphabet, numbers, self.min_length);
        const buf = try self.allocator.alloc(u8, estimated_buffer_size);
        errdefer self.allocator.free(buf);

        const alphabet = try self.allocator.dupe(u8, self.alphabet);
        defer self.allocator.free(alphabet);
        shuffle(alphabet);

        const increment = 0;

        // We ignore the returned value, as we know we have allocated the correct length.
        const n = try encodeNumbers(
            self.allocator,
            buf,
            numbers,
            alphabet,
            increment,
            self.min_length,
            self.blocklist,
        );
        if (n != estimated_buffer_size) {
            @branchHint(.cold);
            @panic("This should not happenned");
            // I am not quite sure it is unreachable, Latchezar labelled his function an
            // estimation..., so we panic here for now, but we should do better.
        }

        return buf;
    }

    /// Decodes an ID into numbers using alphabet. Caller owns the memory.
    pub fn decode(self: Sqids, id: []const u8) ![]const u64 {
        return try decodeID(self.allocator, id, self.alphabet);
    }
};

/// blocklist_from_words constructs a sanitized blocklist from a list of words.
fn blocklist_from_words(
    allocator: mem.Allocator,
    alphabet: []const u8,
    words: []const []const u8,
) ![]const []const u8 {
    // Clean up blocklist:
    // 1. all blocklist words should be lowercase,
    // 2. no words less than 3 chars,
    // 3. if some words contain chars that are not in the alphabet, remove those.

    const lowercase_alphabet = try std.ascii.allocLowerString(allocator, alphabet);
    defer allocator.free(lowercase_alphabet);

    var filtered_blocklist = try ArrayList([]const u8).initCapacity(allocator, words.len);
    errdefer filtered_blocklist.deinit();

    for (words) |word| {
        if (word.len < 3) {
            continue;
        }
        const lowercased_word = try std.ascii.allocLowerString(allocator, word);
        if (!validInAlphabet(lowercased_word, lowercase_alphabet)) {
            allocator.free(lowercased_word);
            continue;
        }
        filtered_blocklist.appendAssumeCapacity(lowercased_word);
    }

    return try filtered_blocklist.toOwnedSlice();
}

fn validInAlphabet(word: []const u8, alphabet: []const u8) bool {
    for (word) |c| {
        if (mem.indexOf(u8, alphabet, &.{c}) == null) {
            return false;
        }
    }
    return true;
}

/// encodeNumbers performs the actual encoding processing.
fn encodeNumbers(
    allocator: mem.Allocator,
    buf: []u8,
    numbers: []const u64,
    original_alphabet: []const u8,
    increment: u64,
    min_length: u64,
    blocklist: []const []const u8,
) !usize {
    if (increment > original_alphabet.len) {
        return Error.ReachedMaxAttempts;
    }

    // Everything is ASCII, so the alphabet is 256 characters at max.
    var alphabet_buffer: [256]u8 = undefined;
    @memcpy(alphabet_buffer[0..original_alphabet.len], original_alphabet);
    var alphabet = alphabet_buffer[0..original_alphabet.len];

    // Get semi-random offset.
    var offset: u64 = numbers.len;
    for (numbers, 0..) |n, i| {
        offset += i;
        offset += alphabet[n % alphabet.len];
    }
    offset %= alphabet.len;
    offset = (offset + increment) % alphabet.len;

    // Prefix and alphabet.
    mem.rotate(u8, alphabet, offset);
    const prefix = alphabet[0];
    mem.reverse(u8, alphabet);

    // Build the ID.
    var ret = ArrayListUnmanaged(u8).initBuffer(buf);

    ret.appendAssumeCapacity(prefix);

    for (numbers, 0..) |n, i| {
        // NOTE(lvignoli): In the reference implementation, the ID letters are inserted
        // at index 0 in a helper buffer, which then extend the main squid ID buffer.
        // Here, we append them to the squid ID buffer for efficiency, so we reverse the
        // slice corresponding to the current number at the end.
        const start = ret.items.len;
        var result = n;
        while (true) {
            ret.appendAssumeCapacity(alphabet[1 + result % (alphabet.len - 1)]);
            result = result / (alphabet.len - 1);
            if (result == 0) break;
        }
        mem.reverse(u8, ret.items[start..]);

        if (i < numbers.len - 1) {
            ret.appendAssumeCapacity(alphabet[0]);
            shuffle(alphabet);
        }
    }

    // Handle min_length requirements.
    if (min_length > ret.items.len) {
        ret.appendAssumeCapacity(alphabet[0]);
        while (min_length > ret.items.len) {
            shuffle(alphabet);
            const n = @min(min_length - ret.items.len, alphabet.len);
            ret.appendSliceAssumeCapacity(alphabet[0..n]);
        }
    }

    const ID = ret.items;
    var len = ID.len;

    // Handle blocklist.
    const blocked = try isBlockedID(allocator, blocklist, ID);
    if (blocked) {
        @memset(buf, undefined);
        len = try encodeNumbers(
            allocator,
            buf,
            numbers,
            original_alphabet,
            increment + 1,
            min_length,
            blocklist,
        );
    }
    return len;
}

/// Estimate the size of the buffer necessary for encoding.
/// It is a an overestimation, so it is safe to assume capacity when constructing
/// the ID.
///
/// Ported from github.com/sqids/sqids-c, by Latchezar Tzvetkoff.
fn estimateEncodingBufferSize(
    alphabet: []const u8,
    numbers: []const u64,
    min_length: u64,
) usize {
    var r: f64 = 0; // f64 as working type up to final usize cast

    const log2len = @log2(@as(f64, @floatFromInt(alphabet.len)) - 1);

    for (numbers) |n| {
        const x = @as(f64, @floatFromInt(n));
        switch (n) {
            0 => r += 2,
            std.math.maxInt(u64) => r += @ceil(@log2(x) / log2len) + 1,
            else => r += @ceil(@log2(x + 1) / log2len) + 1,
        }
    }

    var res = @as(usize, @intFromFloat(r));
    res = @max(res, min_length);

    return res;
}

/// isBlockedID returns true if id collides with the blocklist.
fn isBlockedID(
    allocator: mem.Allocator,
    blocklist: []const []const u8,
    id: []const u8,
) !bool {
    const lower_id = try std.ascii.allocLowerString(allocator, id);
    defer allocator.free(lower_id);

    for (blocklist) |word| {
        if (word.len > lower_id.len) {
            continue;
        }
        if (lower_id.len <= 3 or word.len <= 3) {
            if (mem.eql(u8, id, word)) {
                return true;
            }
        } else if (containsNumber(word)) {
            if (mem.startsWith(u8, lower_id, word) or mem.endsWith(u8, lower_id, word)) {
                return true;
            }
        } else if (mem.indexOf(u8, lower_id, word)) |_| {
            return true;
        }
    }

    return false;
}

fn containsNumber(s: []const u8) bool {
    for (s) |c| {
        if (std.ascii.isDigit(c)) {
            return true;
        }
    }
    return false;
}

/// decodeID decodes an ID into numbers using alphabet. Caller owns the memory.
fn decodeID(
    allocator: mem.Allocator,
    to_decode_id: []const u8,
    decoding_alphabet: []const u8,
) ![]const u64 {
    var id = to_decode_id[0..];
    if (id.len == 0) {
        return &.{};
    }

    // Everything is ASCII, so the alphabet is 256 character at max.
    var buffer: [256]u8 = undefined;
    @memcpy(buffer[0..decoding_alphabet.len], decoding_alphabet);
    var alphabet = buffer[0..decoding_alphabet.len];

    shuffle(alphabet);

    // If a character is not in the alphabet, return an empty array.
    for (id) |c| {
        if (mem.indexOfScalar(u8, alphabet, c) == null) {
            return &.{};
        }
    }

    const prefix = id[0];
    id = id[1..];

    const offset = mem.indexOfScalar(u8, alphabet, prefix).?;
    // NOTE(l.vignoli): We can unwrap safely since all characters are in alphabet.
    mem.rotate(u8, alphabet, offset);
    mem.reverse(u8, alphabet);

    var ret = ArrayList(u64).init(allocator);
    defer ret.deinit();

    while (id.len > 0) {
        const separator = alphabet[0];

        // We need the first part to the left of the separator to decode the number.
        // If there is no separator, we take the whole string.
        const i = mem.indexOfScalar(u8, id, separator) orelse id.len; // TODO: refactor.
        const left = id[0..i];
        const right = if (i == id.len) "" else id[i + 1 ..];

        // If empty, we are done (the rest is junk characters).
        if (left.len == 0) {
            return try ret.toOwnedSlice();
        }

        try ret.append(toNumber(left, alphabet[1..]));

        // If there is still numbers to decode from the ID, shuffle the alphabet.
        if (right.len > 0) {
            shuffle(alphabet);
        }

        // Keep the part to the right of the first separator for the next iteration.
        id = right;
    }

    return try ret.toOwnedSlice();
}

/// toNumber converts a string to an integer using the given alphabet.
fn toNumber(s: []const u8, alphabet: []const u8) u64 {
    var num: u64 = 0;
    for (s) |c| {
        if (mem.indexOfScalar(u8, alphabet, c)) |i| {
            num = num * alphabet.len + i;
        }
    }
    return num;
}

/// shuffle shuffles inplace the given alphabet.
/// It is consistent (or deterministic): it produces the same result given the input.
fn shuffle(alphabet: []u8) void {
    const n = alphabet.len;

    var i: usize = 0;
    var j = alphabet.len - 1;

    while (j > 0) {
        const r = (i * j + alphabet[i] + alphabet[j]) % n;
        mem.swap(u8, &alphabet[i], &alphabet[r]);
        i += 1;
        j -= 1;
    }
}

test "encode" {
    const allocator = testing.allocator;

    const TestCase = struct {
        numbers: []const u64,
        alphabet: []const u8,
        expected: []const u8,
    };

    const cases = [_]TestCase{
        .{
            .numbers = &[_]u64{ 1, 2, 3 },
            .alphabet = "0123456789abcdef",
            .expected = "489158",
        },
        .{
            .numbers = &[_]u64{ 1, 2, 3 },
            .alphabet = default_alphabet,
            .expected = "86Rf07",
        },
    };

    for (cases) |case| {
        const sqids = try Sqids.init(allocator, .{ .alphabet = case.alphabet });
        defer sqids.deinit();
        const id = try sqids.encode(case.numbers);
        defer allocator.free(id);
        try testing.expectEqualStrings(case.expected, id);
    }
}

test "non-empty blocklist" {
    const allocator = testing.allocator;
    const blocklist: []const []const u8 = &.{"ArUO"};

    const sqids = try Sqids.init(allocator, .{ .blocklist = blocklist });
    defer sqids.deinit();

    const actual_numbers = try sqids.decode("ArUO");
    defer allocator.free(actual_numbers);
    try testing.expectEqualSlices(u64, &.{100000}, actual_numbers);

    const got_id = try sqids.encode(&.{100000});
    defer allocator.free(got_id);
    try testing.expectEqualStrings("QyG4", got_id);
}

test "decode" {
    const allocator = testing.allocator;
    const sqids = try Sqids.init(allocator, .{ .alphabet = "0123456789abcdef" });
    defer sqids.deinit();

    const numbers = try sqids.decode("489158");
    defer allocator.free(numbers);
    try testing.expectEqualSlices(u64, &.{ 1, 2, 3 }, numbers);
}
