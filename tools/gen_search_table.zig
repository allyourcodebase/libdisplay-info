const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const alloc = init.arena.allocator();
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.skip();
    const input_path = args.next() orelse return error.MissingArgument;
    const ident = args.next() orelse return error.MissingArgument;

    const data = try std.Io.Dir.readFileAlloc(.cwd(), init.io, input_path, alloc, .unlimited);

    const Entry = struct { key: [3]u8, value: []const u8 };
    var entries: std.ArrayList(Entry) = .empty;
    var lines = std.mem.splitScalar(u8, data, '\n');
    while (lines.next()) |line| {
        if (line.len < 4 or line[3] != '\t') continue;
        const name = std.mem.trimEnd(u8, line[4..], " \t\r\n");
        if (name.len == 0) continue;
        try entries.append(alloc, .{ .key = line[0..3].*, .value = name });
    }
    std.mem.sort(Entry, entries.items, {}, struct {
        fn cmp(_: void, a: Entry, b: Entry) bool {
            return std.mem.order(u8, &a.key, &b.key) == .lt;
        }
    }.cmp);

    var buf: [8192]u8 = undefined;
    var fw = std.Io.File.stdout().writerStreaming(init.io, &buf);
    const w = &fw.interface;

    try w.print("#include <string.h>\n#include <stdint.h>\n\nconst char *\n{s}(const char *key);\n\nconst char *\n{s}(const char *key)\n{{\n    size_t len = strlen(key);\n    size_t i;\n    uint32_t u = 0;\n\n    if (len > 4)\n        return NULL;\n\n    for (i = 0; i < len; i++)\n        u = (u << 8) | (uint8_t)key[i];\n\n    switch (u) {{\n", .{ ident, ident });

    for (entries.items) |entry| {
        const u: u32 = (@as(u32, entry.key[0]) << 16) | (@as(u32, entry.key[1]) << 8) | entry.key[2];
        try w.print("    case {d}: return \"", .{u});
        for (entry.value) |c| {
            if (std.ascii.isAlphanumeric(c) or c == ' ' or c == '.' or c == ',')
                try w.print("{c}", .{c})
            else
                try w.print("\\{o:0>3}", .{c});
        }
        try w.writeAll("\";\n");
    }

    try w.writeAll("\n    default:\n        return NULL;\n    }\n}\n");
    try fw.flush();
}
