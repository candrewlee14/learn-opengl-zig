const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

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
    else => unreachable,
};

pub const Shader = struct {
    id: gl.uint,

    pub fn init(vert_src: [:0]const u8, frag_src: [:0]const u8) !Shader {
        var shader: Shader = .{ .id = 0 };
        const vert_shader = gl.CreateShader(gl.VERTEX_SHADER);
        gl.ShaderSource(
            vert_shader,
            2,
            &[_][*]const u8{ shader_source_preamble, @ptrCast(vert_src.ptr) },
            &[_]gl.int{ shader_source_preamble.len, @intCast(vert_src.len) },
        );
        gl.CompileShader(vert_shader);

        var success: gl.int = 0;
        gl.GetShaderiv(vert_shader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var info_log: [512]u8 = undefined;
            gl.GetShaderInfoLog(vert_shader, 512, null, @ptrCast(&info_log));
            return error.VertexShaderCompilationFailed;
        }

        const frag_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
        gl.ShaderSource(
            frag_shader,
            2,
            &[_][*]const u8{ shader_source_preamble, @ptrCast(frag_src.ptr) },
            &[_]gl.int{ shader_source_preamble.len, @intCast(frag_src.len) },
        );
        gl.CompileShader(frag_shader);
        gl.GetShaderiv(frag_shader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var info_log: [512]u8 = undefined;
            gl.GetShaderInfoLog(frag_shader, 512, null, @ptrCast(&info_log));
            return error.FragmentShaderCompilationFailed;
        }

        shader.id = gl.CreateProgram();
        gl.AttachShader(shader.id, vert_shader);
        gl.AttachShader(shader.id, frag_shader);
        gl.LinkProgram(shader.id);
        gl.GetProgramiv(shader.id, gl.LINK_STATUS, &success);
        if (success == 0) {
            var info_log: [512]u8 = undefined;
            gl.GetProgramInfoLog(shader.id, 512, null, @ptrCast(&info_log));
            return error.ShaderLinkingFailed;
        }
        gl.DeleteShader(vert_shader);
        gl.DeleteShader(frag_shader);
        return shader;
    }

    pub fn initFromFiles(alloc: std.mem.Allocator, vertex_path: []const u8, fragment_path: []const u8) !Shader {
        const vert_f = try std.fs.cwd().openFile(vertex_path);
        defer vert_f.close();
        const frag_f = try std.fs.cwd().openFile(fragment_path);
        defer frag_f.close();

        const vert_src: [:0]const u8 = blk: {
            const buf = try vert_f.readToEndAlloc(alloc, 4_000_000);
            break :blk try alloc.dupeZ(u8, buf);
        };
        defer alloc.free(vert_src.ptr);
        const frag_src: [:0]const u8 = blk: {
            const buf = try frag_f.readToEndAlloc(alloc, 4_000_000);
            break :blk try alloc.dupeZ(u8, buf);
        };
        defer alloc.free(frag_src.ptr);
        return try init(vert_src, frag_src);
    }

    pub fn use(self: *const Shader) void {
        gl.UseProgram(self.id);
    }

    pub fn setBool(self: *const Shader, name: [:0]const u8, value: bool) void {
        gl.Uniform1i(gl.GetUniformLocation(self.id, @ptrCast(name.ptr)), if (value) 1 else 0);
    }

    pub fn setInt(self: *const Shader, name: [:0]const u8, value: gl.int) void {
        gl.Uniform1i(gl.GetUniformLocation(self.id, @ptrCast(name.ptr)), value);
    }

    pub fn setFloat(self: *const Shader, name: [:0]const u8, value: gl.float) void {
        gl.Uniform1f(gl.GetUniformLocation(self.id, @ptrCast(name.ptr)), value);
    }
};
