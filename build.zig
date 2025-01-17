const std = @import("std");
const Build = std.Build;
const print = std.debug.print;

const SRC = "src";

pub fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(2);
}

pub fn build(b: *Build) void {
    const day: usize = b.option(usize, "d", "Select day") orelse 1;

    const dir = std.fs.cwd().openDir(SRC, .{}) catch {
        fatal("{s} does not exist", .{SRC});
    };

    const name = b.fmt("aoc{d}.zig", .{day});

    dir.access(name, .{}) catch {
        fatal("{s} does not exist", .{name});
    };

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const main_path = std.fs.path.join(b.allocator, &.{ SRC, "main.zig" }) catch @panic("OOM");
    const exe_mod = b.createModule(.{
        .root_source_file = b.path(main_path),
        .target = target,
        .optimize = optimize,
    });
    const input_name = b.fmt("aoc{d}.txt", .{day});
    const opts = b.addOptions();
    opts.addOption([]const u8, "input", input_name);
    exe_mod.addOptions("day", opts);

    const lib_path = std.fs.path.join(b.allocator, &.{ SRC, name }) catch @panic("OOM");
    const lib_mod = b.createModule(.{
        .root_source_file = b.path(lib_path),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("aoc", lib_mod);

    const lib = b.addStaticLibrary(.{
        .name = "aoc",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .root_module = exe_mod,
        .name = std.fs.path.stem(name),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.default_step = run_step;
}
