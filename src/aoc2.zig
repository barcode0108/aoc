const std = @import("std");
const print = std.debug.print;

const Arr = std.ArrayList(u32);

pub fn run(file: *const std.fs.File) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var reader = std.io.bufferedReader(file.reader());
    var buf: [1024]u8 = undefined;

    while (try reader.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        _ = line;
    }
}
