const std = @import("std");
const print = std.debug.print;

pub fn run(file: *const std.fs.File) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;

    const stat = try file.stat();
    const buf = try file.readToEndAlloc(gpa.allocator(), stat.size);
    defer gpa.allocator().free(buf);

    var map = Map.init(gpa.allocator());
    defer map.deinit();

    var updates = std.ArrayList(Update).init(gpa.allocator());
    defer {
        for (updates.items) |*update| {
            update.deinit();
        }
        updates.deinit();
    }

    var it = std.mem.splitAny(u8, buf, "\n");
    var sep: bool = false;
    while (it.next()) |line| {
        if (line.len == 0 and !sep) {
            sep = true;
            continue;
        }

        if (line.len == 0) continue;

        if (!sep) {
            var tok = std.mem.tokenizeAny(u8, line, "|");
            const k = if (tok.next()) |t|
                try std.fmt.parseInt(u32, t, 10)
            else
                0;
            const v = if (tok.next()) |t|
                try std.fmt.parseInt(u32, t, 10)
            else
                0;

            if (k != 0)
                try map.put(k, v);
        } else {
            try updates.append(Update.init(gpa.allocator()));
            try updates.items[updates.items.len - 1].set(line);
        }
    }

    for (updates.items) |*update| {
        const valid = validate: for (1..(update.buf.items.len)) |icur| {
            const cur = update.buf.items[icur];
            const check = map.map.get(cur);
            if (check == null)
                continue;

            for (0..icur) |iprev| {
                const prev = update.buf.items[iprev];
                if (find(check.?.items, prev))
                    break :validate false;
            }
        } else true;
        update.valid = valid;
    }

    var sum: u64 = 0;
    for (updates.items) |update| {
        if (update.valid)
            sum += update.mid();
    }
    print("Part 1={}\n", .{sum});

    sum = 0;
    for (updates.items) |*update| {
        if (update.valid)
            continue;

        const list = update.buf.items;

        var i = list.len;
        while (i > 1) {
            i -= 1;

            const check = map.map.get(list[i]);
            if (check == null)
                continue;
            var j = i;
            while (j > 0) {
                j -= 1;

                if (find(check.?.items, list[j])) {
                    std.mem.swap(u32, &list[i], &list[j]);
                    i += 1;
                    break;
                }
            }
        }

        sum += update.mid();
    }
    print("Part 2={}\n", .{sum});
}

fn find(list: []const u32, val: u32) bool {
    for (list) |i| {
        if (i == val) return true;
    }
    return false;
}

const Map = struct {
    allocator: std.mem.Allocator,
    map: Cont,

    const V = std.ArrayListUnmanaged(u32);
    const Cont = std.AutoArrayHashMapUnmanaged(u32, V);
    const This = @This();

    pub fn init(allocator: std.mem.Allocator) This {
        return .{
            .allocator = allocator,
            .map = Cont.empty,
        };
    }

    pub fn deinit(this: *This) void {
        var it = this.map.iterator();
        while (it.next()) |ptr| {
            ptr.value_ptr.deinit(this.allocator);
        }
    }

    pub fn put(this: *This, k: u32, v: u32) !void {
        if (!this.map.contains(k)) {
            try this.map.put(this.allocator, k, V.empty);
        }

        try this.map.getPtr(k).?.append(this.allocator, v);
    }
};

const Update = struct {
    buf: Cont,
    valid: bool = false,

    const Cont = std.ArrayList(u32);
    const This = @This();

    pub fn init(allocator: std.mem.Allocator) This {
        return .{
            .buf = Cont.init(allocator),
        };
    }

    pub fn set(this: *This, str: []const u8) !void {
        this.buf.clearRetainingCapacity();
        var it = std.mem.tokenizeAny(u8, str, ",");

        while (it.next()) |tok| {
            const v = try std.fmt.parseInt(u32, tok, 10);
            try this.buf.append(v);
        }
    }

    pub fn deinit(this: *This) void {
        this.buf.deinit();
    }

    pub fn mid(this: *const This) u32 {
        const idx = this.buf.items.len / 2;
        return this.buf.items[idx];
    }
};
