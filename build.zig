const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sqids_module = b.addModule("sqids", .{ .root_source_file = b.path("src/root.zig") });

    const tests = b.addTest(.{
        .root_source_file = b.path("src/tests/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.root_module.addImport("sqids", sqids_module);

    const run_main_tests = b.addRunArtifact(tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
