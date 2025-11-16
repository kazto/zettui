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

    // Style + color gallery demo
    const style_gallery_module = b.createModule(.{
        .root_source_file = b.path("examples/style_gallery.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const style_gallery_exe = b.addExecutable(.{
        .name = "zettui-style-gallery",
        .root_module = style_gallery_module,
    });
    b.installArtifact(style_gallery_exe);
    const run_style_gallery = b.addRunArtifact(style_gallery_exe);
    const run_style_gallery_step = b.step("run:style-gallery", "Run the DOM style/color gallery demo");
    run_style_gallery_step.dependOn(&run_style_gallery.step);

    // Interaction demo (keyboard/mouse simulation)
    const interaction_module = b.createModule(.{
        .root_source_file = b.path("examples/interaction_demo.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const interaction_exe = b.addExecutable(.{
        .name = "zettui-interaction",
        .root_module = interaction_module,
    });
    b.installArtifact(interaction_exe);
    const run_interaction = b.addRunArtifact(interaction_exe);
    const run_interaction_step = b.step("run:interaction", "Run the keyboard + mouse interaction demo");
    run_interaction_step.dependOn(&run_interaction.step);

    // FTXUI parity gallery
    const ftxui_gallery_module = b.createModule(.{
        .root_source_file = b.path("examples/ftxui_gallery.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const ftxui_gallery_exe = b.addExecutable(.{
        .name = "zettui-ftxui-gallery",
        .root_module = ftxui_gallery_module,
    });
    b.installArtifact(ftxui_gallery_exe);
    const run_ftxui_gallery = b.addRunArtifact(ftxui_gallery_exe);
    const run_ftxui_gallery_step = b.step("run:ftxui-gallery", "Run the FTXUI component/graph gallery demo");
    run_ftxui_gallery_step.dependOn(&run_ftxui_gallery.step);

    // FTXUI table showcase
    const ftxui_table_module = b.createModule(.{
        .root_source_file = b.path("examples/ftxui_table.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const ftxui_table_exe = b.addExecutable(.{
        .name = "zettui-ftxui-table",
        .root_module = ftxui_table_module,
    });
    b.installArtifact(ftxui_table_exe);
    const run_ftxui_table = b.addRunArtifact(ftxui_table_exe);
    const run_ftxui_table_step = b.step("run:ftxui-table", "Run the FTXUI table demo");
    run_ftxui_table_step.dependOn(&run_ftxui_table.step);

    // print_key_press style input logger
    const print_key_module = b.createModule(.{
        .root_source_file = b.path("examples/print_key_press.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const print_key_exe = b.addExecutable(.{
        .name = "zettui-print-key-press",
        .root_module = print_key_module,
    });
    b.installArtifact(print_key_exe);
    const run_print_key = b.addRunArtifact(print_key_exe);
    const run_print_key_step = b.step("run:print-key-press", "Run the print_key_press-style event loop");
    run_print_key_step.dependOn(&run_print_key.step);

    // focus_cursor style navigation demo
    const focus_cursor_module = b.createModule(.{
        .root_source_file = b.path("examples/focus_cursor.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const focus_cursor_exe = b.addExecutable(.{
        .name = "zettui-focus-cursor",
        .root_module = focus_cursor_module,
    });
    b.installArtifact(focus_cursor_exe);
    const run_focus_cursor = b.addRunArtifact(focus_cursor_exe);
    const run_focus_cursor_step = b.step("run:focus-cursor", "Run the focus/cursor navigation demo");
    run_focus_cursor_step.dependOn(&run_focus_cursor.step);

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
