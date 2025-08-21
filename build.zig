const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sqids_module = b.addModule("sqids", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

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

    const exe = b.addExecutable(.{ .name = "squidify", .root_module = exe_module });
    b.installArtifact(exe);

    const exe_step = b.step("run", "Run executable");
    exe_step.dependOn(&b.addRunArtifact(exe).step);
}
