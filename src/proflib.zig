const std = @import("std");
const config = @import("config");

var libncclso: std.DynLib = undefined;
var initialized: bool = false;
var myrank: i32 = -1;

const libcclso_str: []const u8 = config.ccl_flavour;
var hname = [_]u8{0} ** std.c.HOST_NAME_MAX;

pub const Coll = enum(u8) {
    broadcast = 0,
    all_gather,
    all_reduce,
    reduce,
    reduce_scatter,
    fn str(s: Coll) []const u8 {
        return switch (s) {
            Coll.broadcast => "broadcast",
            Coll.all_gather => "all_gather",
            Coll.all_reduce => "all_reduce",
            Coll.reduce => "reduce",
            Coll.reduce_scatter => "reduce_scatter",
        };
    }
};
const CollEvent = struct {
    coll: Coll,
    time: i128,
    msize: usize,
    fn str(e: CollEvent, a: std.mem.Allocator) []u8 {
        return std.fmt.allocPrint(a, "{{ \"pid\":{}, \"coll\": {s}, \"time\": {}, \"msize\": {}}}\n", .{ std.os.linux.getpid(), e.coll.str(), e.time, e.msize }) catch @constCast("CollEvent.str() OutOfMemError");
    }
};
var coll_events = std.ArrayList(CollEvent).init(std.heap.c_allocator);

fn lvlstr(comptime lvl: std.log.Level) []const u8 {
    return switch (lvl) {
        .err => "ERROR",
        .warn => "WARN",
        .info => "INFO",
        .debug => "DEBUG",
    };
}

pub fn zccl_log_fn(comptime level: std.log.Level, comptime scope: @TypeOf(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    _ = scope;

    const prefix = std.fmt.comptimePrint("[ZCCL-PROF::{{s}}::{{}}::{s}] {s} \n", .{ comptime lvlstr(level), format });

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix, .{ hname, std.os.linux.getpid() } ++ args) catch unreachable;
}

pub fn init_proflib() !void {
    if (initialized)
        return;
    libncclso = try std.DynLib.open(libcclso_str);

    _ = std.c.gethostname(&hname, hname.len);
    std.log.info("{s} initialized", .{hname});

    initialized = true;
}

pub fn grab_fn(fname: [:0]const u8, comptime fn_type: type) !fn_type {
    const dlobj = libncclso.lookup(fn_type, fname);
    if (dlobj == null) {
        std.log.info("Failed to find {s}", .{fname});
        return error.LDError;
    }
    return dlobj.?;
}

pub fn prof_coll(coll: Coll, msize: usize) void {
    coll_events.append(CollEvent{ .coll = coll, .time = std.time.nanoTimestamp(), .msize = msize }) catch {
        std.log.err("Error appending event", .{});
    };
}

fn sum_stats(a: std.mem.Allocator) ![]u8 {
    return std.fmt.allocPrint(a, "{{ \"pid\": {}, \"nevents\": {} }}, \n", .{
        std.os.linux.getpid(), coll_events.items.len,
    });
}

fn gen_output_csv(a: std.mem.Allocator, d: std.ArrayList(CollEvent)) ![]u8 {
    var output: []u8 = @constCast("msize");
    const colls = std.meta.fields(Coll);
    inline for (colls) |c| {
        output = try std.fmt.allocPrint(a, "{s}, {s}", .{ output, c.name });
    }
    output = try std.fmt.allocPrint(a, "{s}\n", .{output});
    for (0..35) |shift| {
        // const ms_prev = std.math.pow(usize, 2, shift - 1);
        const ms = std.math.pow(usize, 2, shift);
        const ms_next = std.math.pow(usize, 2, shift + 1);
        var em = std.enums.EnumArray(Coll, usize).initFill(0);
        for (d.items) |ce| {
            if (ce.msize >= ms and ce.msize < ms_next) {
                em.getPtr(ce.coll).* += 1;
            }
        }
        output = try std.fmt.allocPrint(a, "{s}{}", .{ output, ms });
        inline for (colls) |c| {
            output = try std.fmt.allocPrint(a, "{s}, {}", .{ output, em.get(@enumFromInt(c.value)) });
        }
        output = try std.fmt.allocPrint(a, "{s}\n", .{output});
    }
    return try std.fmt.allocPrint(a, "{s}\n", .{output});
}

fn proflib_destructor() callconv(.C) void {
    if (!initialized) {
        // std.io.getStdOut().writeAll("zccl-inject not initialized") catch @panic("destructor write error");
        return;
    }
    var aa = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    // const output = sum_stats(aa.allocator()) catch @panic("destructor sum_stats error");
    const output = gen_output_csv(aa.allocator(), coll_events) catch @panic("destructor sum_stats error");
    std.io.getStdOut().writeAll(output) catch @panic("destructor write error");

    // for (coll_events.items) |e| {
    //     std.io.getStdOut().writeAll(e.str(aa.allocator())) catch @panic("destructor write error");
    // }
    _ = aa.reset(.free_all);
    aa.deinit();
    coll_events.deinit();
}
export const fini_array: [1]*const fn () callconv(.C) void linksection(".fini_array") = .{&proflib_destructor};
