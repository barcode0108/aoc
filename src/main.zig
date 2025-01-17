const std = @import("std");
const fatal = @import("fatal.zig").fatal;

const aoc = @import("aoc");
const input = "input/" ++ @import("day").input;

pub fn main() void {
    const file = std.fs.cwd().openFile(input, .{}) catch {
        fatal("input not found\n", .{});
    };

    defer file.close();

    aoc.run(&file) catch |err| {
        fatal("{}\n", .{err});
    };
}
