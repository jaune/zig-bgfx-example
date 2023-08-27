const std = @import("std");

const bx = @import("build_bx.zig");
const bimg = @import("build_bimg.zig");
const bgfx = @import("build_bgfx.zig");
const sc = @import("build_shader_compiler.zig");
// const tp = @import("build_texture_packer.zig");

const LibExeObjStep = std.build.LibExeObjStep;
const Builder = std.build.Builder;
const CrossTarget = std.zig.CrossTarget;
const Pkg = std.build.Pkg;

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    // EXE
     const exe = b.addExecutable(.{
        .name = "ziggy",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // sdl2
    if (target.isDarwin()){
        // Add SDL2 (OSX only version, install via Homebrew)
        exe.addIncludePath(.{ .path = "/usr/local/include/SDL2"});
        exe.linkSystemLibrary("sdl2");

        // exe.addFrameworkPath(.{ .path = "3rdparty/sdl2/osx"});
        // exe.linkFramework("sdl2");
        exe.linkFramework("Foundation");
        exe.linkFramework("CoreFoundation");
        exe.linkFramework("Cocoa");
        exe.linkFramework("QuartzCore");
        exe.linkFramework("OpenGL");
        exe.linkFramework("IOKit");
        exe.linkFramework("Metal");
    }
    else if (target.isWindows()) {
        exe.addIncludePath(.{ .path = "3rdparty/sdl2/windows/include"});
        exe.addLibraryPath(.{ .path = "3rdparty/sdl2/windows/win64"});
        exe.linkSystemLibrary("sdl2");
        exe.linkSystemLibrary("opengl32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("winmm");
        exe.linkSystemLibrary("setupapi");
        exe.linkSystemLibrary("ole32");
        exe.linkSystemLibrary("oleaut32");
        exe.linkSystemLibrary("imm32");
        exe.linkSystemLibrary("version");
    }

    // zmath and zmath_options
    const zmath_options_step = b.addOptions();
    zmath_options_step.addOption(
        bool,
        "enable_cross_platform_determinism",
        true,
    );

    const zmath_options = zmath_options_step.createModule();
    const zmath = b.addModule("zmath", .{
        .source_file = .{ .path = "3rdparty/zmath/src/zmath.zig" },
        .dependencies = &.{
            .{ .name = "zmath_options", .module = zmath_options },
        },
    });
    exe.addModule("zmath", zmath);

    const zigstr = b.dependency("zigstr", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("zigstr", zigstr.module("zigstr"));

    bx.link(exe);
    bimg.link(exe);
    bgfx.link(exe);

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("c++");

    const install_exe = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_exe.step);

    // shader compiler
    _ = sc.build(b, target, optimize);

    // texture packer
    // _ = tp.build(b, target, optimize);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const exe_tests = b.addTest("src/main.zig");
    // exe_tests.setTarget(target);
    // exe_tests.setBuildMode(mode);
    //
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&exe_tests.step);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
