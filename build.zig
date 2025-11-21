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

    const Example = struct {
        name: []const u8,
        path: []const u8,
        description: []const u8,
    };

    const example_definitions = [_]Example{
        .{ .name = "dom-borders", .path = "examples/dom/borders.zig", .description = "DOM border/separator showcase" },
        .{ .name = "dom-layouts", .path = "examples/dom/layouts.zig", .description = "DOM layout combinator showcase" },
        .{ .name = "dom-colors", .path = "examples/dom/colors_and_styles.zig", .description = "DOM color/style gallery" },
        .{ .name = "dom-canvas", .path = "examples/dom/canvas_and_gauges.zig", .description = "DOM canvas/gauge gallery" },
        .{ .name = "dom-text", .path = "examples/dom/text_and_links.zig", .description = "DOM text/link helpers" },
        .{ .name = "component-buttons", .path = "examples/component/buttons.zig", .description = "Component buttons showcase" },
        .{ .name = "component-menus", .path = "examples/component/menus_and_dropdowns.zig", .description = "Component menus/dropdowns" },
        .{ .name = "component-inputs", .path = "examples/component/inputs_and_sliders.zig", .description = "Component inputs/sliders" },
        .{ .name = "component-selectors", .path = "examples/component/selectors.zig", .description = "Component selectors/toggles" },
        .{ .name = "component-layouts", .path = "examples/component/layouts_and_tabs.zig", .description = "Component layouts/tabs" },
        .{ .name = "component-visual", .path = "examples/component/visual_gallery.zig", .description = "Component visual galleries" },
        .{ .name = "component-navigation", .path = "examples/component/navigation_and_scroll.zig", .description = "Component navigation/scroll" },
        .{ .name = "component-composition", .path = "examples/component/composition.zig", .description = "Component renderer/maybe composition" },
        .{ .name = "component-dialogs", .path = "examples/component/dialogs_and_windows.zig", .description = "Component dialogs/windows" },
        .{ .name = "screen-loop", .path = "examples/screen/custom_loop.zig", .description = "ScreenInteractive custom loop demo" },
        .{ .name = "screen-input", .path = "examples/screen/input_logger.zig", .description = "Screen input logger demo" },
        .{ .name = "screen-nested", .path = "examples/screen/nested_screen.zig", .description = "Nested Screen demo" },
        .{ .name = "screen-restored-io", .path = "examples/screen/with_restored_io.zig", .description = "Screen restored IO demo" },
        .{ .name = "integration-gallery", .path = "examples/integration/gallery.zig", .description = "Integration gallery" },
        .{ .name = "integration-homescreen", .path = "examples/integration/homescreen.zig", .description = "Integration homescreen demo" },
    };

    inline for (example_definitions) |ex| {
        const example_module = b.createModule(.{
            .root_source_file = b.path(ex.path),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zettui", .module = zettui_module }},
        });
        const exe = b.addExecutable(.{
            .name = b.fmt("zettui-{s}", .{ex.name}),
            .root_module = example_module,
        });
        b.installArtifact(exe);
        const run_artifact = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_artifact.addArgs(args);
        }
        const run_step = b.step(b.fmt("run:{s}", .{ex.name}), ex.description);
        run_step.dependOn(&run_artifact.step);
    }

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

    // Canvas builder demo
    const canvas_demo_module = b.createModule(.{
        .root_source_file = b.path("examples/canvas_demo.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const canvas_demo_exe = b.addExecutable(.{
        .name = "zettui-canvas-demo",
        .root_module = canvas_demo_module,
    });
    b.installArtifact(canvas_demo_exe);
    const run_canvas_demo = b.addRunArtifact(canvas_demo_exe);
    const run_canvas_step = b.step("run:canvas", "Run the canvas builder demo");
    run_canvas_step.dependOn(&run_canvas_demo.step);

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

    const runtime_demo_module = b.createModule(.{
        .root_source_file = b.path("examples/runtime_demo.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "zettui", .module = zettui_module }},
    });
    const runtime_demo = b.addExecutable(.{
        .name = "zettui-runtime-demo",
        .root_module = runtime_demo_module,
    });
    b.installArtifact(runtime_demo);
    const run_runtime_demo = b.addRunArtifact(runtime_demo);
    const run_runtime_demo_step = b.step("run:runtime-demo", "Run the runtime/event loop demo");
    run_runtime_demo_step.dependOn(&run_runtime_demo.step);
}
