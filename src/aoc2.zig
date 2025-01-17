const std = @import("std");
const print = std.debug.print;

pub fn run(file: *const std.fs.File) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var reader = std.io.bufferedReader(file.reader());
    var buf: [1024]u8 = undefined;

    var rows = std.ArrayList(std.ArrayList(i32)).init(arena.allocator());

    while (try reader.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenizeAny(u8, line, " ");
        if (it.peek() == null) continue;

        rows.append(std.ArrayList(i32).init(arena.allocator())) catch @panic("OOM");

        while (it.next()) |str| {
            const num = try std.fmt.parseInt(i32, str, 10);
            rows.items[rows.items.len - 1].append(num) catch @panic("OOM");
        }
    }

    var count: u32 = 0;
    for (rows.items) |row| {
        if (check(row.items, null))
            count += 1;
    }

    print("Part 1={}\n", .{count});

    count = 0;
    for (rows.items) |row| {
        var safe = check(row.items, null);

        var i: usize = 0;
        while (!safe and i < row.items.len) : (i += 1) {
            safe = check(row.items, i);
        }

        count += if (safe) 1 else 0;
    }

    print("Part 2={}\n", .{count});
}

inline fn sameSign(a: i32, b: i32) bool {
    return (@intFromBool(a >= 0) ^ @intFromBool(b < 0)) != 0;
}

inline fn check(list: []const i32, ignore: ?usize) bool {
    const startwith: usize = if (ignore != null and ignore.? == 0) 1 else 0;

    if (list.len < startwith + 1)
        return false;

    var prev = list[startwith];
    var diff: i32 = 0;
    return for (list[startwith + 1 ..], (startwith + 1)..) |curr, idx| {
        if (ignore != null and idx == ignore.?)
            continue;

        const new_diff = curr - prev;

        if (diff == 0)
            diff = new_diff;

        if (!sameSign(diff, new_diff)) {
            break false;
        }

        if (!(1 <= @abs(new_diff) and @abs(new_diff) <= 3)) {
            break false;
        }

        diff = new_diff;
        prev = curr;
    } else true;
}
