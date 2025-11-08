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

    // Layout demo using DOM + Screen drawer
    const layout_module = b.createModule(.{
        .root_source_file = b.path("examples/layout_demo.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const layout_exe = b.addExecutable(.{
        .name = "zettui-layout",
        .root_module = layout_module,
    });
    b.installArtifact(layout_exe);
    const run_layout = b.addRunArtifact(layout_exe);
    const run_layout_step = b.step("run:layout", "Run the layout demo (DOM -> Screen drawer)");
    run_layout_step.dependOn(&run_layout.step);

    // Widgets demo (slider and radio group)
    const widgets_module = b.createModule(.{
        .root_source_file = b.path("examples/widgets_demo.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const widgets_exe = b.addExecutable(.{
        .name = "zettui-widgets",
        .root_module = widgets_module,
    });
    b.installArtifact(widgets_exe);
    const run_widgets = b.addRunArtifact(widgets_exe);
    const run_widgets_step = b.step("run:widgets", "Run the widgets demo (slider and radio group)");
    run_widgets_step.dependOn(&run_widgets.step);

    // Interactive widgets demo
    const widgets_interactive_module = b.createModule(.{
        .root_source_file = b.path("examples/widgets_interactive.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const widgets_interactive_exe = b.addExecutable(.{
        .name = "zettui-widgets-interactive",
        .root_module = widgets_interactive_module,
    });
    b.installArtifact(widgets_interactive_exe);
    const run_widgets_interactive = b.addRunArtifact(widgets_interactive_exe);
    const run_widgets_interactive_step = b.step("run:widgets-interactive", "Run the interactive widgets demo");
    run_widgets_interactive_step.dependOn(&run_widgets_interactive.step);

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
