# [Sqids Zig](https://sqids.org/zig)

[Sqids](https://sqids.org/zig) (*pronounced "squids"*) is a small library that lets you **generate unique IDs from numbers**. It's good for link shortening, fast & URL-safe ID generation and decoding back into numbers for quicker database lookups.

Features:

- **Encode multiple numbers** - generate short IDs from one or several non-negative numbers
- **Quick decoding** - easily decode IDs back into numbers
- **Unique IDs** - generate unique IDs by shuffling the alphabet once
- **ID padding** - provide minimum length to make IDs more uniform
- **URL safe** - auto-generated IDs do not contain common profanity
- **Randomized output** - Sequential input provides nonconsecutive IDs
- **Many implementations** - Support for [multiple programming languages](https://sqids.org/)

## 🧰 Use-cases

Good for:

- Generating IDs for public URLs (eg: link shortening)
- Generating IDs for internal systems (eg: event tracking)
- Decoding for quicker database lookups (eg: by primary keys)

Not good for:

- Sensitive data (this is not an encryption library)
- User IDs (can be decoded revealing user count)

## 🚀 Getting started

To add sqids-zig to your Zig application or library, follow these steps:

1. Fetch the package at the desired commit:

```terminal
zig fetch --save https://github.com/lvignoli/sqids-zig/archive/<commitID>.tar.gz
```

2. Declare the dependecy in the `build.zig.zon` file:

```zig
.dependencies = .{
    .sqids = .{
        .url = "https://github.com/lvignoli/sqids-zig/archive/<commitID>.tar.gz",
        .hash = "<hash>",
    },
}
```

3. Use it your `build.zig` and add it where needed:

```zig
const sqids_dep = b.dependency("sqids", .{});
const sqids_mod = sqids_dep.module("sqids");

[...]
 
exe.addModule("sqids", sqids_mod); // for an executable
lib.addModule("sqids", sqids_mod); // for a library
tests.addModule("sqids", sqids_mod); // for tests
```

4. Now you can import it in source sode with

```zig
const sqids = @import("sqids");
```

The import string is the one provided in the `addModule` call.

> [!TIP]
> Check [lvignoli/sqidify](https://github.com/lvignoli/sqidify) for a self-contained Zig executable example.

## 👩‍💻 Examples

Simple encode & decode:

```zig
const s = try sqids.Sqids.init(allocator, .{})
defer s.deinit();

const id = try s.encode(&.{1, 2, 3});
defer allocator.free(id); // Caller owns the memory.

const numbers = try s.decode(id);
defer allocator.free(numbers); // Caller owns the memory.
```

> **Note**
> 🚧 Because of the algorithm's design, **multiple IDs can decode back into the same sequence of numbers**. If it's important to your design that IDs are canonical, you have to manually re-encode decoded numbers and check that the generated ID matches.

The `sqids.Options` struct is used at initialization to customize the encoder.

Enforce a *minimum* length for IDs:

```zig
const id = try s.encode(&.{1, 2, 3}, .{.min_length = 10});
```

Randomize IDs by providing a custom alphabet:

```zig
const id = try s.encode(&.{1, 2, 3}, .{.alphabet = "FxnXM1kBN6cuhsAvjW3Co7l2RePyY8DwaU04Tzt9fHQrqSVKdpimLGIJOgb5ZE"});
```

Prevent specific words from appearing anywhere in the auto-generated IDs:

```zig
const id = try s.encode(&.{1, 2, 3}, .{.blocklist = .{"86Rf07"}});
```

## 📝 License

[MIT](LICENSE)
