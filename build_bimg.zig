const std = @import("std");
const bx = @import("build_bx.zig");
const bimg_path = "3rdparty/bimg/";

pub fn link(exe: *std.Build.Step.Compile) void {
    const lib = buildLibrary(exe);
    addBimgIncludes(exe);
    exe.linkLibrary(lib);
}

fn buildLibrary(exe: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const target = exe.root_module.resolved_target.?;
    const b = exe.step.owner;

    const cxx_options = [_][]const u8{
        "-fno-strict-aliasing",
        "-fno-exceptions",
        "-fno-rtti",
        "-ffast-math",
        "-DBX_CONFIG_DEBUG",
    };

    const bimg_lib = exe.step.owner.addStaticLibrary(.{
        .name = "bimg",
        .target = target,
        .optimize = exe.root_module.optimize.?,
    });
    addBimgIncludes(bimg_lib);
    bimg_lib.addIncludePath(b.path(bimg_path ++ "3rdparty/"));
    bimg_lib.addIncludePath(b.path(bimg_path ++ "3rdparty/astc-encoder/"));
    bimg_lib.addIncludePath(b.path(bimg_path ++ "3rdparty/astc-encoder/include/"));
    bimg_lib.addCSourceFiles(.{
        .files = &.{
            "src/image.cpp",
            "src/image_gnf.cpp",
            "3rdparty/astc-encoder/source/astcenc_averages_and_directions.cpp",
            "3rdparty/astc-encoder/source/astcenc_block_sizes.cpp",
            "3rdparty/astc-encoder/source/astcenc_color_quantize.cpp",
            "3rdparty/astc-encoder/source/astcenc_color_unquantize.cpp",
            "3rdparty/astc-encoder/source/astcenc_compress_symbolic.cpp",
            "3rdparty/astc-encoder/source/astcenc_compute_variance.cpp",
            "3rdparty/astc-encoder/source/astcenc_decompress_symbolic.cpp",
            "3rdparty/astc-encoder/source/astcenc_diagnostic_trace.cpp",
            "3rdparty/astc-encoder/source/astcenc_entry.cpp",
            "3rdparty/astc-encoder/source/astcenc_find_best_partitioning.cpp",
            "3rdparty/astc-encoder/source/astcenc_ideal_endpoints_and_weights.cpp",
            "3rdparty/astc-encoder/source/astcenc_image.cpp",
            "3rdparty/astc-encoder/source/astcenc_integer_sequence.cpp",
            "3rdparty/astc-encoder/source/astcenc_mathlib.cpp",
            "3rdparty/astc-encoder/source/astcenc_mathlib_softfloat.cpp",
            "3rdparty/astc-encoder/source/astcenc_partition_tables.cpp",
            "3rdparty/astc-encoder/source/astcenc_percentile_tables.cpp",
            "3rdparty/astc-encoder/source/astcenc_pick_best_endpoint_format.cpp",
            "3rdparty/astc-encoder/source/astcenc_platform_isa_detection.cpp",
            "3rdparty/astc-encoder/source/astcenc_quantization.cpp",
            "3rdparty/astc-encoder/source/astcenc_symbolic_physical.cpp",
            "3rdparty/astc-encoder/source/astcenc_weight_align.cpp",
            "3rdparty/astc-encoder/source/astcenc_weight_quant_xfer_tables.cpp",
        },
        .flags = &cxx_options,
        .root = b.path(bimg_path),
    });
    bimg_lib.want_lto = false;
    bimg_lib.linkSystemLibrary("c");
    bimg_lib.linkSystemLibrary("c++");
    bx.link(bimg_lib);

    const bimg_lib_artifact = exe.step.owner.addInstallArtifact(bimg_lib, .{});
    exe.step.owner.getInstallStep().dependOn(&bimg_lib_artifact.step);

    return bimg_lib;
}

fn addBimgIncludes(exe: *std.Build.Step.Compile) void {
    const b = exe.step.owner;

    exe.addIncludePath(b.path(bimg_path ++ "include/"));
}
