const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Library linkage type") orelse .static;
    const hwdata_dir = b.option([]const u8, "hwdata-dir", "Path to hwdata data dir") orelse "/usr/share/hwdata";

    const upstream = b.dependency("upstream", .{});
    const src = upstream.path("");

    const gen_wf = b.addWriteFiles();
    const gen = b.addRunArtifact(b.addExecutable(.{
        .name = "gen_search_table",
        .root_module = b.createModule(.{ .root_source_file = b.path("tools/gen_search_table.zig"), .target = b.graph.host }),
    }));
    gen.addArg(b.fmt("{s}/pnp.ids", .{hwdata_dir}));
    gen.addArg("pnp_id_table");
    _ = gen_wf.addCopyFile(gen.captureStdOut(.{}), "pnp-id-table.c");

    const mod = b.createModule(.{ .target = target, .optimize = optimize, .link_libc = true });
    mod.addIncludePath(src.path(b, "include"));
    mod.addCSourceFiles(.{ .root = src, .files = sources, .flags = &.{"-D_POSIX_C_SOURCE=200809L"} });
    mod.addCSourceFiles(.{ .root = gen_wf.getDirectory(), .files = &.{"pnp-id-table.c"}, .flags = &.{} });

    const lib = b.addLibrary(.{ .name = "display-info", .root_module = mod, .linkage = linkage });
    lib.installHeadersDirectory(src.path(b, "include/libdisplay-info"), "libdisplay-info", .{});
    b.installArtifact(lib);
}

const sources: []const []const u8 = &.{
    "cta.c",       "cta-vic-table.c", "cvt.c",
    "displayid.c", "displayid2.c",    "dmt-table.c",
    "edid.c",      "gtf.c",           "hdmi-vic-table.c",
    "info.c",      "log.c",           "memory-stream.c",
};
