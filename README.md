# libdisplay-info zig

[libdisplay-info](https://gitlab.freedesktop.org/emersion/libdisplay-info), packaged for the Zig build system.

## Using

First, update your `build.zig.zon`:

```
zig fetch --save git+https://github.com/allyourcodebase/libdisplay-info.git
```

Then in your `build.zig`:

```zig
const di = b.dependency("libdisplay_info", .{ .target = target, .optimize = optimize });
exe.linkLibrary(di.artifact("display-info"));
```
