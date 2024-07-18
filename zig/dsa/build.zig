const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("./src/main.zig"),
        .target = b.host,
    });

    exe.root_module.addImport("singlyLinkedList", b.createModule(.{ .root_source_file = .{ .path = "lib/singlyLinkedList.zig" } }));

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
