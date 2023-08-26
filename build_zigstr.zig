const std = @import("std");
const ziglyph = @import("build_ziglyph.zig");

pub fn link(exe: *std.build.LibExeObjStep) void {
    // const lib = buildLibrary(exe);
    // exe.addPackagePath("zigstr", "3rdparty/zigstr/src/Zigstr.zig");
    // exe.linkLibrary(lib);

    const zigstr = exe.step.owner.addModule("zigstr", .{
        .source_file = .{ .path = "3rdparty/zigstr/src/Zigstr.zig" }
    });
    exe.addModule("zigstr", zigstr);
}

// fn buildLibrary(exe: *std.build.LibExeObjStep) *std.build.LibExeObjStep {
//
//     // const lib = exe.step.owner.addStaticLibrary(.{
//     //     .name = "zigstr",
//     //     .target = exe.target,
//     //     .optimize = exe.optimize,
//     // });
//     // const lib = exe.builder.addStaticLibrary("zigstr", "3rdparty/zigstr/src/Zigstr.zig");
//     // lib.setTarget(exe.target);
//     // lib.setBuildMode(exe.build_mode);
//     // ziglyph.link(lib);
//     // lib.install();
//
//     // const zigstr_lib_artifact = exe.step.owner.addInstallArtifact(lib, .{});
//     // exe.step.owner.getInstallStep().dependOn(&zigstr_lib_artifact.step);
//     // return lib;
// }

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
