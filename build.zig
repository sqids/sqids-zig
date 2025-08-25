const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sqids_module = b.addModule("sqids", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{ .root_module = sqids_module, .name = "sqids" });
    const docs_step = b.step("docs", "Emit docs");
    docs_step.dependOn(&b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    }).step);

    const test_module = b.createModule(.{
        .root_source_file = b.path("src/tests/tests.zig"),
        .target = target,
        .optimize = optimize,
    });
    test_module.addImport("sqids", sqids_module);

    const tests = b.addTest(.{
        .root_module = test_module,
        .test_runner = .{ .path = b.path("src/tests/test_runner.zig"), .mode = .simple },
    });
    const root_tests = b.addTest(.{
        .root_module = sqids_module,
        .test_runner = .{ .path = b.path("src/tests/test_runner.zig"), .mode = .simple },
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
    test_step.dependOn(&b.addRunArtifact(root_tests).step);

    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });
    exe_module.addImport("sqids", sqids_module);

    const bench_module = b.createModule(.{ .root_source_file = b.path("benchmark/bench.zig"), .target = target, .optimize = optimize });
    bench_module.addImport("sqids", sqids_module);

    const bench_exe = b.addExecutable(.{ .name = "bench-encode-random-uuids", .root_module = bench_module });

    const bench_gen_step = b.step("gen-bench-encode", "Generate benchmark executable");
    bench_gen_step.dependOn(&b.addInstallArtifact(bench_exe, .{}).step);
}
