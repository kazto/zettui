# Runtime Event Loop Guide

The Zettui runtime is split across reusable utilities:

- `animation/animator.zig` – easing helpers and frame progression state.
- `task.zig` – a cooperative scheduler for short-lived async work.
- `loop.zig` – a frame driver that ticks callbacks at a target cadence.
- `captured_mouse.zig` – tracks exclusive mouse grabs and coordinates.
- `screen_interactive.zig` – event queue + animation pump that dispatches `component.Event` values to a root component.

## Minimal setup

```zig
var event_loop = zettui.screen_interactive.EventLoop.init(allocator);
defer event_loop.deinit();
// default loop spins forever; use target_frame_ms or your own stop criteria
event_loop.loop.target_frame_ms = 0;
try event_loop.postEvent(.{ .key = .{ .codepoint = ' ' } });
try event_loop.run(root_component);
```

`EventLoop.run` processes queued events, runs scheduled tasks, advances the animator, and posts a synthetic `custom` event tagged `"animation-frame"`. Call `loop.stop()` from a component or task when you want to exit the loop.

Use `CapturedMouse` if you need exclusive pointer dragging:

```zig
var mouse = zettui.captured_mouse.CapturedMouse{};
event_loop.bindMouse(&mouse);
// inside your component
mouse.capture(.{ .x = event.position.x, .y = event.position.y });
```

## Sample application

`examples/runtime_demo.zig` combines DOM styling, tables/scroll indicators, `CanvasBuilder`, and component decorators with the interactive loop. Run it with:

```
zig build run:runtime-demo
```

The demo prints a styled dashboard, then enqueues key/custom events into `screen_interactive.EventLoop` to toggle a widget. `docs/runtime_event_loop.md` and the example share the same hyperlinks rendered via `RenderContext.allow_hyperlinks`.

## Tips

- `CanvasBuilder.toNode()` transfers ownership of its buffers; do not call `deinit()` afterward.
- Wrap expensive rendering work in `task.Scheduler` jobs so UI input stays responsive.
- Pair `component.decorators.maybe()` with the event loop to enable/disable sections without rebuilding the component tree.
- Always set `ZIG_GLOBAL_CACHE_DIR=./.zig-cache` (or the equivalent env var) when running builds/tests under the repo-local cache described in `AGENTS.md`.
