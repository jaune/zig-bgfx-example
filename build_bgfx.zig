const std = @import("std");

const bx = @import("build_bx.zig");
const bimg = @import("build_bimg.zig");

const bgfx_path = "3rdparty/bgfx/";

var framework_dir: ?[]u8 = null;

pub fn link(exe: *std.build.LibExeObjStep) void {
    const lib = buildLibrary(exe);
    addBgfxIncludes(exe);
    exe.linkLibrary(lib);
}

fn buildLibrary(exe: *std.build.LibExeObjStep) *std.build.LibExeObjStep {
    const cxx_options = [_][]const u8{
        "-fno-strict-aliasing",
        "-fno-exceptions",
        "-fno-rtti",
        "-ffast-math",
        "-DBX_CONFIG_DEBUG",
        "-DBGFX_CONFIG_USE_TINYSTL=0",
    };

    // we are creating our own module here
    var bgfx_module = exe.step.owner.createModule(.{
        // .source_file = .{ .path = "src/main.zig" },
        .source_file = .{ .path = thisDir() ++ "/" ++ bgfx_path ++ "bindings/zig/bgfx.zig"},
    });

    // we name the module duck which will be used later
    // try exe.step.owner.modules.put(b.dupe("bgfx"), bgfx_module);

    const bgfx_lib = exe.step.owner.addStaticLibrary(.{
        .name = "bgfx",
        .target = exe.target,
        .optimize = exe.optimize,
    });

    exe.addModule("bgfx", bgfx_module);
    // const bgfx_lib = exe.builder.addStaticLibrary("bgfx", null);

    // bgfx_lib.setTarget(exe.target);
    // bgfx_lib.setBuildMode(exe.build_mode);

    bgfx_lib.addIncludePath(.{ .path = bgfx_path ++ "include/"});
    bgfx_lib.addIncludePath(.{ .path = bgfx_path ++ "3rdparty/"});
    bgfx_lib.addIncludePath(.{ .path = bgfx_path ++ "3rdparty/directx-headers/include/directx/"});
    bgfx_lib.addIncludePath(.{ .path = bgfx_path ++ "3rdparty/khronos/"});
    bgfx_lib.addIncludePath(.{ .path = bgfx_path ++ "src/"});

    if (bgfx_lib.target.isDarwin()) {
        bgfx_lib.addCSourceFile(.{ .file = .{ .path = bgfx_path ++ "src/amalgamated.mm"}, .flags = &cxx_options});
        // const frameworks_dir = macosFrameworksDir(exe) catch unreachable;
        // exe.addFrameworkDir(frameworks_dir);
        // std.debug.print("Added framework dir: {s}\n", .{framework_dir});
        bgfx_lib.linkFramework("Foundation");
        bgfx_lib.linkFramework("CoreFoundation");
        bgfx_lib.linkFramework("Cocoa");
        bgfx_lib.linkFramework("QuartzCore");
    } else {
        bgfx_lib.addCSourceFile(.{ .file = .{ .path = bgfx_path ++ "src/amalgamated.cpp"}, .flags = &cxx_options});
        // if (bgfx_lib.target.isWindows()) {

        // }
    }

    bgfx_lib.want_lto = false;
    bgfx_lib.linkSystemLibrary("c");
    bgfx_lib.linkSystemLibrary("c++");
    bx.link(bgfx_lib);
    bimg.link(bgfx_lib);

    // bgfx_lib.install();
    const bgfx_lib_artifact = exe.step.owner.addInstallArtifact(bgfx_lib, .{});
    exe.step.owner.getInstallStep().dependOn(&bgfx_lib_artifact.step);

    return bgfx_lib;
}

fn addBgfxIncludes(exe: *std.build.LibExeObjStep) void {
    exe.addIncludePath(.{ .path = thisDir() ++ "/" ++ bgfx_path ++ "include/"});
    // exe.addPackagePath(.{ .path = thisDir() ++ "/" ++ bgfx_path ++ "bindings/zig/bgfx.zig"});
    // exe.addPackage(.{ .path = "blah"});
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}

// /// helper function to get SDK path on Mac
// fn macosFrameworksDir(exe: *std.build.LibExeObjStep) ![]u8 {
//     if (framework_dir) |dir| return dir;

//     var str = try exe.builder.exec(&[_][]const u8{ "xcrun", "--show-sdk-path" });
//     const strip_newline = std.mem.lastIndexOf(u8, str, "\n");
//     if (strip_newline) |index| {
//         str = str[0..index];
//     }
//     framework_dir = try std.mem.concat(exe.builder.allocator, u8, &[_][]const u8{ str, "/System/Library/Frameworks" });
//     return framework_dir.?;
// }
