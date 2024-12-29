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
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = "cclprof",
        .root_source_file = b.path("src/compat.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibC();
    lib.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = CUDA_HEADER_INSTALL } });
    lib.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = ROCM_HEADER_INSTALL } });
    lib.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = CCL_HEADER_INSTALL } });

    const ccl_flavour = b.option(CCL_Flavour, "CCL_FLAVOUR", "ccl lib to buld against") orelse CCL_Flavour.nccl;
    const opts = b.addOptions();
    opts.addOption([]const u8, "ccl_flavour", ccl_flavour.str());
    lib.root_module.addOptions("config", opts);

    b.installArtifact(lib);

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/testing.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
