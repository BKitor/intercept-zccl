const std = @import("std");

const CUDA_HEADER_INSTALL = "/usr/local/cuda/include";
const ROCM_HEADER_INSTALL = "/opt/rocm/include";
const CCL_HEADER_INSTALL = "src/cinclude";

const CCL_Flavour = enum {
    nccl,
    rccl,
    fn str(f: CCL_Flavour) []const u8 {
        return switch (f) {
            CCL_Flavour.nccl => "nccl",
            CCL_Flavour.rccl => "rccl",
        };
    }
    fn default() CCL_Flavour {
        return CCL_Flavour.rccl;
    }
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_cstep = b.addSharedLibrary(.{
        .name = "cclprof",
        .root_source_file = b.path("src/compat.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_cstep.linkLibC();
    lib_cstep.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = CUDA_HEADER_INSTALL } });
    lib_cstep.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = ROCM_HEADER_INSTALL } });
    lib_cstep.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = CCL_HEADER_INSTALL } });

    const opts = b.addOptions();
    const ccl_flavour = b.option(CCL_Flavour, "CCL_FLAVOUR", "ccl lib to buld against") orelse CCL_Flavour.default();
    opts.addOption([]const u8, "ccl_flavour", ccl_flavour.str());
    const lib_istep = b.addInstallArtifact(lib_cstep, .{});
    opts.addOption([]const u8, "lib_dest_dir", b.getInstallPath(lib_istep.dest_dir.?, lib_istep.dest_sub_path));

    lib_cstep.root_module.addOptions("config", opts);
    b.getInstallStep().dependOn(&lib_istep.step);

    const runner_cstep = b.addExecutable(.{
        .name = "cclprofrunner",
        .root_source_file = b.path("src/runner.zig"),
        .target = target,
        .optimize = optimize,
    });
    runner_cstep.linkLibC();
    runner_cstep.root_module.addOptions("config", opts);
    b.installArtifact(runner_cstep);

    const runner_rstep = b.addRunArtifact(runner_cstep);
    if (b.args) |args| runner_rstep.addArgs(args);
    const run_step = b.step("run", "run the runner");
    runner_rstep.step.dependOn(&lib_istep.step); // make sure the .so exists before firing the runner
    run_step.dependOn(&runner_rstep.step);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/testing.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
