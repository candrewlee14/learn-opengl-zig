const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

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

    while (!window.shouldClose()) {
        // input
        processInput(&window);

        // render commands
        gl.ClearColor(0.2, 0.3, 0.3, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        // check and call events and swap the buffers
        window.swapBuffers();
        glfw.pollEvents();
    }
}
