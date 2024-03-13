const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

const vert_src = @embedFile("02_shaders/vert.glsl");
const frag_src = @embedFile("02_shaders/frag.glsl");

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

    var nr_attributes: gl.int = undefined;
    gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, @ptrCast(&nr_attributes));
    std.debug.print("Maximum nr of vertex attributes supported: {}\n", .{nr_attributes});

    const shader = try utils.Shader.init(vert_src, frag_src);

    const vertices = [_]gl.float{
        // positions    // colors
        0.5, -0.5, 0.0, 1.0, 0.0, 0.0, // bottom right
        -0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // bottom left
        0.0, 0.5, 0.0, 0.0, 0.0, 1.0, // top
    };

    var vbo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&vbo));
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(gl.float), @ptrCast(&vertices), gl.STATIC_DRAW);

    var vao: gl.uint = undefined;
    gl.GenVertexArrays(1, @ptrCast(&vao));
    gl.BindVertexArray(vao);

    // position attribute
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(gl.float), 0);
    gl.EnableVertexAttribArray(0);
    // color attribute
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(gl.float), 3 * @sizeOf(gl.float));
    gl.EnableVertexAttribArray(1);

    while (!window.shouldClose()) {
        // input
        processInput(&window);

        // render commands
        gl.ClearColor(0.2, 0.3, 0.3, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        shader.use();

        gl.BindVertexArray(vao);
        gl.DrawArrays(gl.TRIANGLES, 0, vertices.len / 6);

        // check and call events and swap the buffers
        window.swapBuffers();
        glfw.pollEvents();
    }
}
