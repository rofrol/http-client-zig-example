const std = @import("std");
const http = std.http;

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const arena = arena_instance.allocator();
    const gpa = arena;

    const args = try std.process.argsAlloc(arena);

    var client: http.Client = .{
        .allocator = gpa,
    };
    defer client.deinit();

    const url = try std.Uri.parse(args[1]);
    var req = try client.request(url, .{}, .{});
    defer req.deinit();

    const stdout = if (args.len >= 3)
        try std.fs.cwd().createFile(args[2], .{})
    else
        std.io.getStdOut();

    var bw = std.io.bufferedWriter(stdout.writer());
    const w = bw.writer();

    var total: usize = 0;
    var buf: [20000]u8 = undefined;
    while (true) {
        const amt = try req.readAll(&buf);
        total += amt;
        if (amt == 0) break;
        std.debug.print("got {d} bytes (total {d})\n", .{ amt, total });
        try w.writeAll(buf[0..amt]);
    }

    try bw.flush();
}
