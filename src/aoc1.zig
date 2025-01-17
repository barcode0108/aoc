const std = @import("std");
const print = std.debug.print;

const Arr = std.ArrayList(u32);

pub fn run(file: *const std.fs.File) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var reader = std.io.bufferedReader(file.reader());
    var buf: [1024]u8 = undefined;

    var left = Arr.init(arena.allocator());
    var right = Arr.init(arena.allocator());

    while (try reader.reader().readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.tokenizeAny(u8, line, " ");

        // while (it.next()) |str| {
        //     print("{s}  ", .{str});
        // }
        // print("{s}", .{it.first()});
        var n = try std.fmt.parseInt(u32, it.next().?, 10);
        left.append(n) catch @panic("OOM");

        n = try std.fmt.parseInt(u32, it.next().?, 10);
        right.append(n) catch @panic("OOM");
    }

    std.debug.assert(left.items.len == right.items.len);

    std.mem.sort(u32, left.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, right.items, {}, std.sort.asc(u32));

    var sum: u64 = 0;
    for (left.items, right.items) |l, r| {
        sum += if (l > r) l - r else r - l;
    }

    print("Part 1: {d}\n", .{sum});

    var left_idx: usize = 0;
    var right_start: usize = 0;

    var prev: u32 = undefined;
    var count: u32 = 0;
    sum = 0;
    while (left_idx < left.items.len) : (left_idx += 1) {
        const l = left.items[left_idx];

        if (prev != l) {
            prev = l;
        } else {
            sum += l * count;
            continue;
        }

        count = 0;

        for (right_start..right.items.len) |right_idx| {
            const r = right.items[right_idx];

            if (r < l) {
                continue;
            } else if (r > l) {
                right_start = right_idx;
                break;
            } else {
                count += 1;
            }
        }
        sum += l * count;
    }

    print("Part 2: {d}\n", .{sum});
}
