const std = @import("std");

const bx_path = "3rdparty/bx/";

pub fn link(exe: *std.Build.Step.Compile) void {
    const lib = buildLibrary(exe);
    addBxIncludes(exe);
    exe.linkLibrary(lib);
}

fn buildLibrary(exe: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const cxx_options = [_][]const u8{
        "-fno-strict-aliasing",
        "-fno-exceptions",
        "-fno-rtti",
        "-ffast-math",
        "-DBX_CONFIG_DEBUG",
    };

    const target = exe.root_module.resolved_target.?;
    const b = exe.step.owner;

    const bx_lib = b.addStaticLibrary(.{
        .name = "bx",
        .target = target,
        .optimize = exe.root_module.optimize.?,
    });

    addBxIncludes(bx_lib);
    bx_lib.addIncludePath(b.path(bx_path ++ "3rdparty/"));
    if (target.result.os.tag == .macos) {
        bx_lib.linkFramework("CoreFoundation");
        bx_lib.linkFramework("Foundation");
    }
    bx_lib.addCSourceFile(.{ .file = b.path(bx_path ++ "src/amalgamated.cpp"), .flags = &cxx_options });
    bx_lib.want_lto = false;
    bx_lib.linkSystemLibrary("c");
    bx_lib.linkSystemLibrary("c++");

    const bx_lib_artifact = b.addInstallArtifact(bx_lib, .{});
    b.getInstallStep().dependOn(&bx_lib_artifact.step);
    return bx_lib;
}

fn addBxIncludes(exe: *std.Build.Step.Compile) void {
    const b = exe.step.owner;

    const target = exe.root_module.resolved_target.?;

    var compat_include: []const u8 = "";

    if (target.result.os.tag == .windows) {
        compat_include = bx_path ++ "include/compat/mingw/";
    } else if (target.result.os.tag == .macos) {
        compat_include = bx_path ++ "include/compat/osx/";
    }

    exe.addIncludePath(b.path(compat_include));
    exe.addIncludePath(b.path(bx_path ++ "include/"));
}
