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
