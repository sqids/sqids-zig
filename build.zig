const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sqids_module = b.addModule("sqids", .{ .source_file = .{ .path = "src/main.zig" } });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests/tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_main_tests = b.addRunArtifact(tests);

    tests.addModule("sqids", sqids_module);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
