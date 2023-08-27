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
        // Add SDL2, include path may vary
        // exe.addIncludePath(.{ .path = "/usr/local/include/SDL2"});
        // exe.linkSystemLibrary("sdl2");

        exe.addFrameworkPath(.{ .path = "3rdparty/sdl2/osx"});
        exe.linkSystemLibrary("sdl2");
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

    // zmath - not a package yet, so manually make the module
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

    // zigstr dependency, pulled via build.zig.zon
    const zigstr = b.dependency("zigstr", .{
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("zigstr", zigstr.module("zigstr"));

    // Link the bgfx libs
    bx.link(exe);
    bimg.link(exe);
    bgfx.link(exe);

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("c++");

    const install_exe = b.addInstallArtifact(exe, .{});
    b.getInstallStep().dependOn(&install_exe.step);

    // build the shader compiler
    const shader_compiler_exe = sc.build(b, target, optimize);
    _ = shader_compiler_exe;

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // const compile_shaders_step = b.step("shaders", "Compile Shaders");
    // compile_shaders_step.makeFn = compileShaders;
    // compile_shaders_step.dependOn(&install_exe.step);
}

// fn compileShaders(self: *std.build.Step, progress: *std.Progress.Node) !void {
//     std.debug.print("Compiling Shaders\n", .{});
//
//     var files = std.ArrayList([]const u8).init(self.owner.allocator);
//     defer files.deinit();
//
//     // Find all of the shader files
//     var dir = try std.fs.cwd().openIterableDir("assets/shaders/cubes", .{});
//     var it = dir.iterate();
//     while (try it.next()) |file| {
//         if (file.kind != .file) {
//             continue;
//         }
//
//         std.debug.print("Compiling shader {s}\n", .{file.name});
//
//         var compiler_args_list = std.ArrayList([]const u8).init(self.owner.allocator);
//         defer compiler_args_list.deinit();
//
//         var compiler_args = std.ArrayList(u8).init(self.owner.allocator);
//         defer compiler_args.deinit();
//
//         // Shader compiler exe
//         try compiler_args_list.append("shaderc");
//
//         try compiler_args_list.append("-f");
//         try compiler_args_list.append(file.name);
//
//         // get binary path from path
//         // var bin_path = try str.fromBytes(allocator, path[0..mem.lastIndexOfScalar(u8, path, '.').?]);
//         // defer bin_path.deinit();
//         // try bin_path.concat(".bin");
//
//         try compiler_args_list.append("-o");
//         try compiler_args_list.append("test-out.bin");
//
//         try compiler_args_list.append("-i");
//         try compiler_args_list.append("assets/shaders/include");
//
//         try compiler_args_list.append("--varyingdef");
//         try compiler_args_list.append("assets/shaders/cube/varying.def.sc");
//
//         try compiler_args_list.append("--type");
//
//         if(file.name .)
//         try compiler_args_list.append("fragment");
//
//         // for now assume OSX
//         // TODO get compile time platform
//         try compiler_args_list.append("--platform");
//         try compiler_args_list.append("osx");
//
//         // for now we assume GLSL 400
//         try compiler_args_list.append("--profile");
//         try compiler_args_list.append("150");
//
//         for (compiler_args_list.items) |arg| {
//             try compiler_args.appendSlice(arg);
//             try compiler_args.append(' ');
//         }
//
//         // try files.append(self.owner.dupe(file.name));
//     }
//
//     _ = progress;
//     // _ = self;
// }

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
