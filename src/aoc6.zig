const std = @import("std");
const print = std.debug.print;

pub fn run(file: *const std.fs.File) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;

    const stat = try file.stat();
    var map = Map.init(gpa.allocator(), stat.size);
    defer map.deinit();

    var rd = std.io.bufferedReader(file.reader());
    var idx: usize = 0;
    while (try rd.reader().readUntilDelimiterOrEof(map.buf[idx..], '\n')) |line| {
        if (line.len == 0)
            continue;

        map.height += 1;
        map.width = line.len;
        idx += line.len;
    }

    // map.print();
    //
    const origin = map.findGuard();
    _ = map.findExit(origin);

    const xcount = cal_x: {
        var acc: usize = 0;
        for (map.buf) |c| {
            if (std.ascii.isDigit(c))
                acc += 1;
        }
        break :cal_x acc;
    };

    print("Part 1={}\n", .{xcount});

    map.reset(origin);

    const ocount = cal_o: {
        var acc: usize = 0;
        for (map.buf) |*c| {
            if (Map.isPath(c.*)) {
                c.* = Map.Temp;
                if (!map.findExit(origin)) {
                    acc += 1;
                }
            }

            map.reset(origin);
        }
        break :cal_o acc;
    };

    print("Part 2={}\n", .{ocount});
}

// x, y
const Direction = std.meta.Tuple(&.{ i8, i8 });
const Directions = [_]Direction{
    .{ 1, 0 },
    .{ 0, 1 },
    .{ -1, 0 },
    .{ 0, -1 },
};

fn nextDir(d: usize) usize {
    return if (d >= Directions.len - 1) 0 else d + 1;
}

fn getDir(c: u8) usize {
    return switch (c) {
        '>' => 0,
        'v' => 1,
        '<' => 2,
        '^' => 3,
        else => unreachable,
    };
}

const Map = struct {
    buf: []u8,
    allocator: std.mem.Allocator,
    width: usize = 0,
    height: usize = 0,

    const This = @This();
    const Coord = std.meta.Tuple(&.{ isize, isize });
    const Obs = '#';
    const Path = '.';
    const Visited = 'X';
    const Guard = '^';
    const Temp = 'O';

    pub fn isPath(c: u8) bool {
        if (std.ascii.isDigit(c)) return true;
        return switch (c) {
            Obs => false,
            Temp => false,
            Path => true,
            Visited => true,
            Guard => false,
            else => false,
        };
    }

    pub fn print(this: *const This) void {
        for (0..this.height) |y| {
            std.debug.print("{s}\n", .{this.buf[(y * this.height)..(y * this.height + this.width)]});
        }
    }

    pub fn init(allocator: std.mem.Allocator, size: usize) This {
        return .{
            .allocator = allocator,
            .buf = allocator.alloc(u8, size) catch @panic("OOM"),
        };
    }

    pub fn visit(this: *This, x: isize, y: isize) bool {
        const c = this.at(x, y);
        this.buf[this.index(x, y)] = if (std.ascii.isDigit(c)) c + 1 else '1';

        return this.at(x, y) - '0' < 5;
    }

    pub fn index(this: *const This, x: isize, y: isize) usize {
        return @intCast(y * @as(isize, @intCast(this.width)) + x);
    }

    pub fn inRange(this: *const This, x: isize, y: isize) bool {
        return 0 <= y and y < this.height and 0 <= x and x < this.width;
    }

    pub fn reset(this: *This, origin: Coord) void {
        for (this.buf) |*c| {
            if (std.ascii.isDigit(c.*) or c.* == Map.Temp)
                c.* = Map.Path;
        }

        this.buf[this.index(origin[0], origin[1])] = Map.Guard;
    }

    pub fn findGuard(this: *const This) Coord {
        for (0..this.height) |y| {
            for (0..this.width) |x| {
                if (this.at(@intCast(x), @intCast(y)) == Guard)
                    return .{ @intCast(x), @intCast(y) };
            }
        }

        return .{ -1, -1 };
    }

    pub fn findExit(this: *This, origin: Coord) bool {
        var ix, var iy = origin;
        var dir = getDir(this.at(ix, iy));

        return while (this.inRange(ix, iy)) {
            if (!this.visit(ix, iy)) {
                break false;
            }
            const dx, const dy = Directions[dir];
            const x = ix + dx;
            const y = iy + dy;

            if (!this.inRange(x, y))
                break true;

            if (!Map.isPath(this.at(x, y))) {
                dir = nextDir(dir);
                continue;
            }

            ix = x;
            iy = y;
        } else true;
    }

    pub fn at(this: *const This, x: isize, y: isize) u8 {
        return this.buf[this.index(x, y)];
    }

    pub fn deinit(this: *This) void {
        this.allocator.free(this.buf);
    }
};
