const std = @import("std");
const zflecs = @import("zflecs");

const Prog = struct {
    run_name: []const u8,
    name: []const u8,
    root: []const u8,
};

const progs = [_]Prog{
    .{ .run_name = "00", .name = "hello-window", .root = "src/00_hello_window.zig" },
    .{ .run_name = "01.0", .name = "hello-triangle-pt1", .root = "src/01.0_hello_triangle.zig" },
    .{ .run_name = "01.1", .name = "hello-triangle-pt2", .root = "src/01.1_hello_triangle.zig" },
};

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // const zflecs_pkg = zflecs.package(b, target, optimize, .{});
    // zflecs_pkg.link(exe);

    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    const mach_glfw_dep = b.dependency("mach-glfw", .{
        .target = target,
        .optimize = optimize,
    });

    const all_step = b.step("all", "Build all examples");
    const test_step = b.step("test", "Run unit tests");

    for (progs) |prog| {
        const exe = b.addExecutable(.{
            .name = prog.name,
            .root_source_file = .{ .path = prog.root },
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("glfw", mach_glfw_dep.module("mach-glfw"));
        exe.root_module.addImport("gl", gl_bindings);

        const build_step = b.addInstallArtifact(exe, .{});

        all_step.dependOn(&build_step.step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&build_step.step);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step(prog.run_name, b.fmt("Run {s}", .{prog.name}));
        run_step.dependOn(&run_cmd.step);

        const exe_unit_tests = b.addTest(.{
            .root_source_file = .{ .path = prog.root },
            .target = target,
            .optimize = optimize,
        });

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        test_step.dependOn(&run_exe_unit_tests.step);
    }
}
