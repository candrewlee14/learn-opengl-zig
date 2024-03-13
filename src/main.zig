const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

var gl_procs: gl.ProcTable = undefined;

const State = struct {
    wireframe_mode: bool = false,
    wireframe_latch: bool = false,

    fn processInput(self: *State, window: *const glfw.Window) void {
        if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
            window.setShouldClose(true);
        }
        switch (window.getKey(glfw.Key.f)) {
            glfw.Action.press => {
                if (self.wireframe_latch) return;
                self.wireframe_latch = true;
                self.wireframe_mode = !self.wireframe_mode;
                if (self.wireframe_mode) {
                    gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);
                } else {
                    gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL);
                }
            },
            glfw.Action.release => {
                self.wireframe_latch = false;
            },
            else => {},
        }
    }
};

pub fn main() !void {
    if (!glfw.init(.{})) return error.InitFailed;
    defer glfw.terminate();

    var state: State = .{};

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

    gl.ClearColor(0.2, 0.3, 0.3, 1.0);

    // now create a vertex array object
    // this stores the vertex attribute calls
    // so we can just bind the vertex array object
    // and then we can draw the object
    var vao: gl.uint = undefined;
    gl.GenVertexArrays(1, @ptrCast(&vao));
    gl.BindVertexArray(vao);

    // normalized device coordinates
    // 0,0 is the center of the window
    // 1 is the edge of the window
    const vertices = [_]gl.float{
        0.5, 0.5, 0.0, // top right
        0.5, -0.5, 0.0, // bottom right
        -0.5, -0.5, 0.0, // bottom left
        -0.5, 0.5, 0.0, // top left
    };
    const indices = [_]gl.uint{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };
    // vertex buffer object
    // this stores the vertex data
    var vbo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&vbo));
    // bind that buffer so we can set data on it
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    // set the data on the buffer
    // first param is the type of buffer
    // second param is the size of the data
    // third param is the data
    // fourth param is the usage of the buffer
    // - stream draw means the data is set once and used at most a few times
    // - static draw means the data is set once and used many times
    // - dynamic draw means the data is changed a lot and used many times
    gl.BufferData(gl.ARRAY_BUFFER, vertices.len * @sizeOf(gl.float), @ptrCast(&vertices), gl.STATIC_DRAW);

    // element buffer object
    // this stores the indices of the vertices
    // so we can draw the vertices in a different order
    var ebo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&ebo));
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(gl.uint), @ptrCast(&indices), gl.STATIC_DRAW);

    // we need to tell the vertex shader how to interpret the data
    // so now we set the vertex attributes pointers
    // - first param is the location of the attribute in the shader
    // - second param is the size of the attribute
    // - third param is the type of the attribute
    // - fourth param is if the data should be normalized (which means integer data is converted to float data)
    // - fifth param is the size of the data
    // - last param is the offset of the data
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(gl.float), 0);
    gl.EnableVertexAttribArray(0);

    const shader_source_preamble = switch (gl.info.api) {
        .gl => (
            \\#version 410 core
            \\
        ),
        .gles => (
            \\#version 300 es
            \\precision highp float;
            \\
        ),
        else => comptime unreachable,
    };

    const vertex_shader_source =
        \\layout (location = 0) in vec3 aPos;
        \\
        \\void main() {
        \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
        \\}
    ;
    const vertex_shader = gl.CreateShader(gl.VERTEX_SHADER);
    gl.ShaderSource(
        vertex_shader,
        2,
        &[_][*]const u8{ shader_source_preamble, vertex_shader_source },
        &[_]gl.int{ shader_source_preamble.len, vertex_shader_source.len },
    );
    gl.CompileShader(vertex_shader);
    var success: gl.int = undefined;
    var info_log: [512]gl.char = undefined;
    gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success);
    if (success != 1) {
        gl.GetShaderInfoLog(vertex_shader, 512, null, &info_log);
        std.debug.print("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n", .{info_log[0..]});
    }

    const fragment_shader_source =
        \\out vec4 FragColor;
        \\
        \\void main() {
        \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
        \\}
    ;
    const fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
    gl.ShaderSource(
        fragment_shader,
        2,
        &[_][*]const u8{ shader_source_preamble, fragment_shader_source },
        &[_]gl.int{ shader_source_preamble.len, fragment_shader_source.len },
    );
    gl.CompileShader(fragment_shader);
    gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success);
    if (success != 1) {
        gl.GetShaderInfoLog(fragment_shader, 512, null, &info_log);
        std.debug.print("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n", .{info_log[0..]});
    }

    // now we create a shader program
    // this is a program that runs on the GPU
    // it is made up of a vertex shader and a fragment shader
    // we then link the two together
    // and then we can use the program to draw things
    const shader_program = gl.CreateProgram();
    gl.AttachShader(shader_program, vertex_shader);
    gl.AttachShader(shader_program, fragment_shader);
    gl.LinkProgram(shader_program);
    gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success);
    if (success != 1) {
        gl.GetProgramInfoLog(shader_program, 512, null, &info_log);
        std.debug.print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{info_log[0..]});
    }

    // delete the shaders as they are no longer needed, we only use the program now
    gl.DeleteShader(vertex_shader);
    gl.DeleteShader(fragment_shader);

    while (!window.shouldClose()) {
        // input
        state.processInput(&window);

        // render commands
        gl.Clear(gl.COLOR_BUFFER_BIT);
        gl.UseProgram(shader_program);
        gl.BindVertexArray(vao);
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);

        // check and call events and swap the buffers
        window.swapBuffers();
        glfw.pollEvents();
    }
}
