const std = @import("std");
const print = std.debug.print;

const IdxPair = std.meta.Tuple(&.{ u32, usize });

const Mul = struct {
    x: u32,
    y: u32,
};

pub fn run(file: *const std.fs.File) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var reader = std.io.bufferedReader(file.reader());

    var arr = std.ArrayList(Mul).init(arena.allocator());

    var arr2 = std.ArrayList(Mul).init(arena.allocator());

    const content = try reader.reader().readAllAlloc(arena.allocator(), std.math.maxInt(usize));
    var idx: usize = 0;
    var enable = true;

    while (idx < content.len) : (idx += 1) {
        if (content[idx] == 'd') {
            const dont: []const u8 = "don't()";
            if (startsWith(content[idx..], dont)) {
                idx += dont.len - 1;
                enable = false;
                continue;
            }
            const do: []const u8 = "do()";
            if (startsWith(content[idx..], do)) {
                idx += do.len - 1;
                enable = true;
                continue;
            }
        }
        if (content[idx] != 'm') {
            continue;
        }

        if (startsWith(content[idx..], "mul(")) {
            idx += 4;
            const val1, var off = parseInt(content[idx..]) catch {
                continue;
            };
            idx += off;

            if (content[idx] != ',')
                continue;
            idx += 1;

            const val2, off = parseInt(content[idx..]) catch {
                continue;
            };
            idx += off;

            if (content[idx] != ')')
                continue;

            arr.append(.{
                .x = val1,
                .y = val2,
            }) catch @panic("OOM");

            if (enable) {
                arr2.append(.{
                    .x = val1,
                    .y = val2,
                }) catch @panic("OOM");
            }
        }
    }

    var sum: u128 = 0;

    print("len={d}\n", .{arr.items.len});

    for (arr.items, 0..) |*mul, i| {
        _ = i;
        sum += mul.x * mul.y;
    }

    print("Part 1={d}\n", .{sum});

    sum = 0;
    for (arr2.items, 0..) |*mul, i| {
        _ = i;
        sum += mul.x * mul.y;
    }
    print("Part 2={d}\n", .{sum});
}

fn startsWith(str: []const u8, match: []const u8) bool {
    if (match.len > str.len)
        return false;
    return std.mem.eql(u8, match, str[0..match.len]);
}

fn parseInt(str: []const u8) std.fmt.ParseIntError!IdxPair {
    var idx: usize = 0;
    while (idx < str.len and std.ascii.isDigit(str[idx])) : (idx += 1) {}
    return if (idx > 0) .{ try std.fmt.parseInt(u32, str[0..idx], 10), idx } else std.fmt.ParseIntError.InvalidCharacter;
}
