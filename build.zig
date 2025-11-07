const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zettui_module = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "zettui",
        .root_module = zettui_module,
    });
    b.installArtifact(lib);

    const demo_module = b.createModule(.{
        .root_source_file = b.path("examples/demo.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });

    const demo = b.addExecutable(.{
        .name = "zettui-demo",
        .root_module = demo_module,
    });
    b.installArtifact(demo);

    const run_demo = b.addRunArtifact(demo);
    if (b.args) |args| {
        run_demo.addArgs(args);
    }
    const run_step = b.step("run", "Run the demo application");
    run_step.dependOn(&run_demo.step);

    // Spinner animation example
    const spin_module = b.createModule(.{
        .root_source_file = b.path("examples/spinner_loop.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const spin = b.addExecutable(.{
        .name = "zettui-spin",
        .root_module = spin_module,
    });
    b.installArtifact(spin);
    const run_spin = b.addRunArtifact(spin);
    const run_spin_step = b.step("run:spin", "Run the spinner animation demo");
    run_spin_step.dependOn(&run_spin.step);

    const tests_module = b.createModule(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib_tests = b.addTest(.{
        .root_module = tests_module,
    });
    const test_step = b.step("test", "Run zettui unit tests");
    test_step.dependOn(&lib_tests.step);

    const fmt_step = b.step("fmt", "Format Zig sources");
    const fmt = b.addFmt(.{
        .paths = &.{
            "src",
            "examples",
            "docs",
            "build.zig",
        },
    });
    fmt_step.dependOn(&fmt.step);
}
