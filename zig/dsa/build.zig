const std = @import("std");

const pname = "dsa";
const version = "0.1.0";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = pname,
        .root_source_file = b.path("./src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("singlyLinkedList", b.createModule(.{ 
        .root_source_file = b.path("lib/singlyLinkedList.zig"),
        .target = target,
        .optimize = optimize,
    }));

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);

    const test_step = b.step("test", "Run unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("lib/singlyLinkedList.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
