const std = @import("std");
const print = std.debug.print;

const XMAS = "XMAS";
const Map = std.ArrayList([]const u8);
const IndexPair = std.meta.Tuple(&.{ usize, usize });


pub fn run(file: *const std.fs.File) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const stat = try file.stat();
    const buf = try file.readToEndAlloc(arena.allocator(), stat.size);

    var lines = std.mem.splitAny(u8, buf, "\n");

    var rows = Map.init(arena.allocator());
    while (lines.next()) |line| {
        if (line.len > 0)
            try rows.append(line);
    }

    const xend = rows.items[0].len;
    const yend = rows.items.len;

    var total: usize = 0;

    // horizontal
    for (0..yend) |y| {
        total += search(.{ 0, y }, .{ .x = 1, .y = 0 }, &rows);
        total += search(.{ xend - 1, y }, .{ .x = -1, .y = 0 }, &rows);
    }
    // vertical
    for (0..xend) |x| {
        total += search(.{ x, 0 }, .{ .x = 0, .y = 1 }, &rows);
        total += search(.{ x, yend - 1 }, .{ .x = 0, .y = -1 }, &rows);
    }
    // diagonal ⇘
    for (0..yend) |y| {
        total += search(.{ 0, y }, .{ .x = 1, .y = 1 }, &rows);
    }
    for (1..xend) |x| {
        total += search(.{ x, 0 }, .{ .x = 1, .y = 1 }, &rows);
    }
    // ⇖
    for (0..yend) |y| {
        total += search(.{ xend - 1, y }, .{ .x = -1, .y = -1 }, &rows);
    }
    for (0..(xend - 1)) |x| {
        total += search(.{ x, yend - 1 }, .{ .x = -1, .y = -1 }, &rows);
    }

    // ⇗
    for (0..yend) |y| {
        total += search(.{ 0, y }, .{ .x = 1, .y = -1 }, &rows);
    }
    for (1..xend) |x| {
        total += search(.{ x, yend - 1 }, .{ .x = 1, .y = -1 }, &rows);
    }
    // ⇙
    for (0..yend) |y| {
        total += search(.{ xend - 1, y }, .{ .x = -1, .y = 1 }, &rows);
    }
    for (0..(xend - 1)) |x| {
        total += search(.{ x, 0 }, .{ .x = -1, .y = 1 }, &rows);
    }

    print("Part 1={d}\n", .{total});

    const count = mas(&rows);
    print("Part 2={d}\n", .{count});
}

const Direction = struct {
    x: i8,
    y: i8,
};

inline fn inRange(map: *const Map, x: isize, y: isize) bool {
    if (!(0 <= y and y < map.items.len)) return false;
    return 0 <= x and x < map.items[@intCast(y)].len;
}

fn search(start: IndexPair, dir: Direction, map: *const Map) usize {
    // print("start: ({d}, {d})", .{ start[0], start[1] });
    var ix: isize = @intCast(start[0]);
    var iy: isize = @intCast(start[1]);

    var idx: usize = 0;
    var ret: usize = 0;

    while (inRange(map, ix, iy)) : ({
        ix += dir.x;
        iy += dir.y;
    }) {
        const c = map.items[@intCast(iy)][@intCast(ix)];

        if (c == XMAS[idx]) {
            idx += 1;
        } else {
            idx = if (c == XMAS[0]) 1 else 0;
        }

        if (idx == XMAS.len) {
            ret += 1;
            idx = 0;
        }
    }

    return ret;
}

fn checkMSPair(a: u8, b: u8) bool {
    var mcount: usize = 0;
    var scount: usize = 0;
    inline for ([2]u8{ a, b }) |m| {
        switch (m) {
            'M' => mcount += 1,
            'S' => scount += 1,
            else => break,
        }
    }

    return mcount == 1 and scount == 1;
}

fn mas(map: *const Map) usize {
    if (map.items.len < 3 or map.items[0].len < 3) return 0;
    var ret: usize = 0;
    for (1..(map.items.len - 1)) |iy| {
        for (1..(map.items[iy].len - 1)) |ix| {
            const cur = map.items[iy][ix];
            if (cur == 'A') {
                const topleft = map.items[iy - 1][ix - 1];
                const topright = map.items[iy - 1][ix + 1];
                const bottomleft = map.items[iy + 1][ix - 1];
                const bottomright = map.items[iy + 1][ix + 1];
                if (checkMSPair(topleft, bottomright) and checkMSPair(topright, bottomleft))
                    ret += 1;
            }
        }
    }

    return ret;
}
