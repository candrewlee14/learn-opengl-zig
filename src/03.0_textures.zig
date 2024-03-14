const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const zstbi = @import("zstbi");

const vert_src = @embedFile("03_textures/vert.glsl");
const frag_src = @embedFile("03_textures/frag.glsl");

const utils = @import("utils.zig");

var gl_procs: gl.ProcTable = undefined;

fn processInput(window: *const glfw.Window) void {
    if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}

pub fn main() !void {
    if (!glfw.init(.{})) return error.InitFailed;
    defer glfw.terminate();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    zstbi.init(alloc);
    defer zstbi.deinit();

    const window = glfw.Window.create(640, 480, "Triangle!", null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        // This example supports both OpenGL (Core profile) and OpenGL ES.
        // (Toggled by building with '-Dgles')
        .opengl_profile = switch (gl.info.api) {
            .gl => .opengl_core_profile,
            .gles => .opengl_any_profile,
            else => comptime unreachable,
        },
        // The forward compat hint should only be true when using regular OpenGL.
        .opengl_forward_compat = gl.info.api == .gl,
    }) orelse return error.InitFailed;
    defer window.destroy();

    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    if (!gl_procs.init(glfw.getProcAddress)) return error.InitFailed;

    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    const shader = try utils.Shader.init(vert_src, frag_src);

    var img = try zstbi.Image.loadFromFile("./assets/container.jpg", 0);
    var texture: gl.uint = undefined;
    gl.GenTextures(1, @ptrCast(&texture));
    gl.BindTexture(gl.TEXTURE_2D, texture);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, @intCast(img.width), @intCast(img.height), 0, gl.RGB, gl.UNSIGNED_BYTE, @ptrCast(img.data.ptr));
    gl.GenerateMipmap(gl.TEXTURE_2D);
    img.deinit();
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.MIRRORED_REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    // texture magnification filter
    // - using mipmap doesn't make sense for magnification (since mipmap is about downscaling)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    const vertices = [_]gl.float{
        // zig fmt: off
        // positions      // colors       // texture coords
        0.5, 0.5, 0.0,    1.0, 0.0, 0.0,  1.0, 1.0, // top right
        0.5, -0.5, 0.0,   0.0, 1.0, 0.0,  1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0,  0.0, 0.0, 1.0,  0.0, 0.0, // bottom left
        -0.5, 0.5, 0.0,   1.0, 1.0, 0.0,  0.0, 1.0, // top left
        // zig fmt: on
    };

    const indices = [_]gl.uint{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };
    var ebo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&ebo));
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(gl.uint), @ptrCast(&indices), gl.STATIC_DRAW);

    var vbo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&vbo));
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(gl.float), @ptrCast(&vertices), gl.STATIC_DRAW);

    var vao: gl.uint = undefined;
    gl.GenVertexArrays(1, @ptrCast(&vao));
    gl.BindVertexArray(vao);

    // position attribute
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(gl.float), 0);
    gl.EnableVertexAttribArray(0);
    // color attribute
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(gl.float), 3 * @sizeOf(gl.float));
    gl.EnableVertexAttribArray(1);
    // texture coord attribute
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(gl.float), 6 * @sizeOf(gl.float));
    gl.EnableVertexAttribArray(2);

    while (!window.shouldClose()) {
        // input
        processInput(&window);

        // render commands
        gl.ClearColor(0.2, 0.3, 0.3, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        shader.use();

        gl.BindTexture(gl.TEXTURE_2D, texture);
        gl.BindVertexArray(vao);
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
        gl.DrawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, 0);

        // check and call events and swap the buffers
        window.swapBuffers();
        glfw.pollEvents();
    }
}
