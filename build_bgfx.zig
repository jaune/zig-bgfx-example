const std = @import("std");

const bx = @import("build_bx.zig");
const bimg = @import("build_bimg.zig");

const bgfx_path = "3rdparty/bgfx/";

var framework_dir: ?[]u8 = null;

pub fn link(exe: *std.Build.Step.Compile) void {
    const lib = buildLibrary(exe);
    addBgfxIncludes(exe);
    exe.linkLibrary(lib);
}

fn buildLibrary(exe: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const b = exe.step.owner;
    const target = exe.root_module.resolved_target.?;

    const cxx_options = [_][]const u8{
        "-fno-strict-aliasing",
        "-fno-exceptions",
        "-fno-rtti",
        "-ffast-math",
        "-DBX_CONFIG_DEBUG",
        "-DBGFX_CONFIG_USE_TINYSTL=0",
        "-DBGFX_CONFIG_MULTITHREADED=0", // OSX does not support multithreaded rendering
    };

    const bgfx_module = b.createModule(.{
        .root_source_file = b.path(bgfx_path ++ "bindings/zig/bgfx.zig"),
    });
    exe.root_module.addImport("bgfx", bgfx_module);

    const bgfx_lib = b.addStaticLibrary(.{
        .name = "bgfx",
        .target = target,
        .optimize = exe.root_module.optimize.?,
    });

    bgfx_lib.addIncludePath(b.path(bgfx_path ++ "include/"));
    bgfx_lib.addIncludePath(b.path(bgfx_path ++ "3rdparty/"));
    bgfx_lib.addIncludePath(b.path(bgfx_path ++ "3rdparty/directx-headers/include/directx/"));
    bgfx_lib.addIncludePath(b.path(bgfx_path ++ "3rdparty/khronos/"));
    bgfx_lib.addIncludePath(b.path(bgfx_path ++ "src/"));

    if (target.result.isDarwin()) {
        bgfx_lib.addCSourceFile(.{ .file = b.path(bgfx_path ++ "src/amalgamated.mm"), .flags = &cxx_options });
        bgfx_lib.linkFramework("Foundation");
        bgfx_lib.linkFramework("CoreFoundation");
        bgfx_lib.linkFramework("Cocoa");
        bgfx_lib.linkFramework("QuartzCore");
    } else {
        bgfx_lib.addCSourceFile(.{ .file = b.path(bgfx_path ++ "src/amalgamated.cpp"), .flags = &cxx_options });
    }

    bgfx_lib.want_lto = false;
    bgfx_lib.linkSystemLibrary("c");
    bgfx_lib.linkSystemLibrary("c++");
    bx.link(bgfx_lib);
    bimg.link(bgfx_lib);

    const bgfx_lib_artifact = exe.step.owner.addInstallArtifact(bgfx_lib, .{});
    exe.step.owner.getInstallStep().dependOn(&bgfx_lib_artifact.step);

    return bgfx_lib;
}

fn addBgfxIncludes(exe: *std.Build.Step.Compile) void {
    const b = exe.step.owner;

    exe.addIncludePath(b.path(bgfx_path ++ "include/"));
}
