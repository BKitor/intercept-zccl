const std = @import("std");
const bconfig = @import("config");

pub fn merge_outfiles() void {}

pub fn main() !void {
    var aa = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer aa.deinit();

    var arg_iter = try std.process.argsWithAllocator(aa.allocator());
    defer arg_iter.deinit();

    var cp_argv_list = std.ArrayList([]const u8).init(aa.allocator());
    var runner_argv_list = std.ArrayList([]const u8).init(aa.allocator());
    defer cp_argv_list.deinit();
    defer runner_argv_list.deinit();

    const p_bin_name = arg_iter.next().?; // runner bin name
    std.debug.print("bin name: {s}\n", .{p_bin_name});
    while (arg_iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "--")) {
            break;
        }
        try runner_argv_list.append(arg);
    }
    while (arg_iter.next()) |arg|
        try cp_argv_list.append(arg);

    std.debug.print("parent argv: {s}\n", .{runner_argv_list.items});
    std.debug.print("child argv: {s}\n", .{cp_argv_list.items});

    var cp_env_map = try std.process.getEnvMap(aa.allocator());
    defer cp_env_map.deinit();

    std.debug.print("Pre-loading .so : {s}\n", .{bconfig.lib_dest_dir});
    try cp_env_map.put("LD_PRELOAD", bconfig.lib_dest_dir);

    var cp = std.process.Child.init(cp_argv_list.items, aa.allocator());
    cp.env_map = &cp_env_map;
    const cp_term = try cp.spawnAndWait();

    std.debug.print("child_res {any}\n", .{cp_term});
}
