const std = @import("std");
const math = std.math;
const print = std.log.info;
const assert = std.debug.assert;
const panic = std.debug.panic;
const bgfx = @import("bgfx");
const zsdl = @import("zsdl2");

const zm = @import("zmath");

const builtin = @import("builtin");

const WIDTH = 1280;
const HEIGHT = 720;

const aspect_ratio = @as(f32, @floatFromInt(WIDTH)) / HEIGHT;

const PosColorVertex = struct {
    x: f32,
    y: f32,
    z: f32,
    abgr: u32,

    fn init(x: f32, y: f32, z: f32, abgr: u32) PosColorVertex {
        return .{
            .x = x,
            .y = y,
            .z = z,
            .abgr = abgr,
        };
    }

    fn layoutInit() bgfx.VertexLayout {
        // static local
        const L = struct {
            var posColorLayout = std.mem.zeroes(bgfx.VertexLayout);
        };

        L.posColorLayout.begin(bgfx.RendererType.Noop)
            .add(bgfx.Attrib.Position, 3, bgfx.AttribType.Float, false, false)
            .add(bgfx.Attrib.Color0, 4, bgfx.AttribType.Uint8, true, false)
            .end();

        return L.posColorLayout;
    }
};

const cube_vertices = [_]PosColorVertex{
    PosColorVertex.init(-1.0, 1.0, 1.0, 0xff000000),
    PosColorVertex.init(1.0, 1.0, 1.0, 0xff0000ff),
    PosColorVertex.init(-1.0, -1.0, 1.0, 0xff00ff00),
    PosColorVertex.init(1.0, -1.0, 1.0, 0xff00ffff),
    PosColorVertex.init(-1.0, 1.0, -1.0, 0xffff0000),
    PosColorVertex.init(1.0, 1.0, -1.0, 0xffff00ff),
    PosColorVertex.init(-1.0, -1.0, -1.0, 0xffffff00),
    PosColorVertex.init(1.0, -1.0, -1.0, 0xffffffff),
};

const cube_tri_list = [_]u16{
    0, 1, 2, // 0
    1, 3, 2,
    4, 6, 5, // 2
    5, 6, 7,
    0, 2, 4, // 4
    4, 2, 6,
    1, 5, 3, // 6
    5, 7, 3,
    0, 4, 1, // 8
    4, 5, 1,
    2, 3, 6, // 10
    6, 3, 7,
};

pub fn main() !void {
    try zsdl.init(.{
        .video = true,
        .events = true,
    });
    defer zsdl.quit();

    std.log.info("Creating SDL Window", .{});

    const window = try zsdl.createWindow(
        "BGFX Zig Test",
        zsdl.Window.pos_undefined,
        zsdl.Window.pos_undefined,
        WIDTH,
        HEIGHT,
        .{
            .shown = true,
            .allow_highdpi = true,
            .opengl = true,
        },
    );
    defer window.destroy();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.log.info("Creating BGFX Init State", .{});

    var bgfxInit = std.mem.zeroes(bgfx.Init);
    bgfxInit.type = bgfx.RendererType.Metal;
    bgfxInit.resolution.width = WIDTH;
    bgfxInit.resolution.height = HEIGHT;
    bgfxInit.limits.transientIbSize = 1 << 20;
    bgfxInit.limits.transientVbSize = 1 << 20;
    bgfxInit.debug = true;

    var wmi: zsdl.SysWMInfo = std.mem.zeroes(zsdl.SysWMInfo);
    if (!zsdl.getWindowWMInfo(window, &wmi)) {
        return error.GetWindowWMInfoError;
    }

    if (builtin.target.os.tag == .windows) {
        bgfxInit.platformData.nwh = wmi.info.win.window;
    } else if (builtin.os.tag == .macos) {
        bgfxInit.platformData.nwh = wmi.info.cocoa.window;
    }

    // Initialize bgfx
    std.log.info("BGFX Initializing", .{});

    const success = bgfx.init(&bgfxInit);
    defer bgfx.shutdown();
    assert(success);

    // Enable Vsync
    std.log.info("BGFX - Enabling Vsync", .{});
    bgfx.reset(WIDTH, HEIGHT, bgfx.ResetFlags_Vsync, bgfxInit.resolution.format);

    // Enable debug text.
    bgfx.setDebug(bgfx.DebugFlags_Text);

    // Set view 0 clear state.
    bgfx.setViewClear(0, bgfx.ClearFlags_Color | bgfx.ClearFlags_Depth, 0x303030ff, 1.0, 0);

    std.log.info("Creating buffers", .{});

    const vertex_layout = PosColorVertex.layoutInit();
    const vbh = bgfx.createVertexBuffer(bgfx.makeRef(&cube_vertices, cube_vertices.len * @sizeOf(PosColorVertex)), &vertex_layout, bgfx.BufferFlags_None);
    defer bgfx.destroyVertexBuffer(vbh);

    const ibh = bgfx.createIndexBuffer(bgfx.makeRef(&cube_tri_list, cube_tri_list.len * @sizeOf(u16)), bgfx.BufferFlags_None);
    defer bgfx.destroyIndexBuffer(ibh);

    std.log.info("Loading Shaders", .{});

    const compiledVertexShaderBuffer = try loadCompiledShader("assets/shaders/cubes/vs_cubes.sc.bin", allocator);
    defer allocator.free(compiledVertexShaderBuffer);

    const compiledFragmentShaderBuffer = try loadCompiledShader("assets/shaders/cubes/fs_cubes.sc.bin", allocator);
    defer allocator.free(compiledFragmentShaderBuffer);

    const vsh = bgfx.createShader(bgfx.makeRef(compiledVertexShaderBuffer.ptr, @intCast(compiledVertexShaderBuffer.len)));
    assert(vsh.idx != std.math.maxInt(c_ushort));

    const fsh = bgfx.createShader(bgfx.makeRef(compiledFragmentShaderBuffer.ptr, @intCast(compiledFragmentShaderBuffer.len)));
    assert(fsh.idx != std.math.maxInt(c_ushort));

    const programHandle = bgfx.createProgram(vsh, fsh, true);
    defer bgfx.destroyProgram(programHandle);

    // Create view matrices
    const viewMtx = zm.lookAtRh(
        zm.f32x4(0.0, 0.0, -50.0, 1.0),
        zm.f32x4(0.0, 0.0, 0.0, 1.0),
        zm.f32x4(0.0, 1.0, 0.0, 0.0),
    );

    const projMtx = zm.perspectiveFovRhGl(
        0.25 * math.pi,
        aspect_ratio,
        0.1,
        100.0,
    );
    const state = 0 | bgfx.StateFlags_WriteRgb | bgfx.StateFlags_WriteA | bgfx.StateFlags_WriteZ | bgfx.StateFlags_DepthTestLess | bgfx.StateFlags_CullCcw | bgfx.StateFlags_Msaa;

    var quit = false;
    const start_time: i64 = std.time.milliTimestamp();

    std.log.info("Main Loop Starting", .{});

    while (!quit) {
        var event: zsdl.Event = undefined;
        while (zsdl.pollEvent(&event)) {
            switch (event.type) {
                .quit => {
                    std.log.info("Main Loop Stopping", .{});
                    quit = true;
                },
                else => {},
            }
        }

        bgfx.setViewTransform(0, &zm.matToArr(viewMtx), &zm.matToArr(projMtx));
        bgfx.setViewRect(0, 0, 0, WIDTH, HEIGHT);
        bgfx.touch(0);
        bgfx.dbgTextClear(0, false);

        var yy: f32 = 0;
        const time: f32 = @as(f32, @floatFromInt(std.time.milliTimestamp() - start_time)) / std.time.ms_per_s;
        while (yy < 11) : (yy += 1.0) {
            var xx: f32 = 0;
            while (xx < 11) : (xx += 1.0) {
                const trans = zm.translation(-15.0 + xx * 3.0, -15 + yy * 3.0, 3.0 * @sin(3.0 * time + xx + yy));
                const rotX = zm.rotationX(@sin(1.5 * time) + xx * 0.21);
                const rotY = zm.rotationY(@sin(1.5 * time) + yy * 0.37);
                const rotXY = zm.mul(rotX, rotY);
                const modelMtx = zm.mul(rotXY, trans);
                _ = bgfx.setTransform(&zm.matToArr(modelMtx), 1);
                bgfx.setVertexBuffer(0, vbh, 0, cube_vertices.len);
                bgfx.setIndexBuffer(ibh, 0, cube_tri_list.len);
                bgfx.setState(state, 0);
                bgfx.submit(0, programHandle, 0, 255);
            }
        }

        _ = bgfx.frame(false);
    }

    std.log.info("Shutting down", .{});
}

pub fn loadCompiledShader(path: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const compiled_shader_file = try std.fs.cwd().openFile(path, .{});
    const compiled_shader_buffer = try compiled_shader_file.readToEndAlloc(allocator, 5 * 1024 * 1024);
    compiled_shader_file.close();
    return compiled_shader_buffer;
}
