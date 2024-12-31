const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("uuid", .{
        .root_source_file = b.path("uuid.zig"),
    });

    const test_exe = b.addTest(.{
        .root_source_file = b.path("uuid.zig"),
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&test_exe.step);
}
