const std = @import("std");
const proflib = @import("proflib.zig");
const nccl = @cImport({
    @cInclude("nccl.h");
});

pub const std_options = .{
    .log_level = .info,
    .logFn = proflib.zccl_log_fn,
};

fn msize(count: usize, dtype: nccl.ncclDataType_t) usize {
    switch (dtype) {
        // nccl.ncclDataType_t.ncclInt8, nccl.ncclDataType_t.char, nccl.ncclDataType_t.nccuUint8
        0, 1 => return count,
        // nccl.ncclDataType_t.ncclFloat16, nccl.ncclDataType_t.nccuHalf
        6 => return count * 2,
        // nccl.ncclDataType_t.ncclFloat32, nccl.ncclDataType_t.nccuFloat
        2, 3, 7 => return count * 4,
        // nccl.ncclDataType_t.ncclInt64, nccl.ncclDataType_t.nccuUint64
        // nccl.ncclDataType_t.ncclFloat64, nccl.ncclDataType_t.nccuDouble
        4, 5, 8 => return count * 8,
        else => return std.math.maxInt(usize),
    }
}

const ncclGetUniqueId_fnt = *const fn ([*c]nccl.ncclUniqueId) callconv(.C) nccl.ncclResult_t;
const ncclCommInitRank_fnt = *const fn ([*c]nccl.ncclComm_t, c_int, nccl.ncclUniqueId, c_int) callconv(.C) nccl.ncclResult_t;
const ncclCommInitRankConfig_fnt = *const fn ([*c]nccl.ncclComm_t, c_int, nccl.ncclUniqueId, c_int, [*c]nccl.ncclConfig_t) callconv(.C) nccl.ncclResult_t;
const ncclCommInitAll_fnt = *const fn ([*c]nccl.ncclComm_t, c_int, *const c_int) callconv(.C) nccl.ncclResult_t;

const AllReduce_fnt = *const fn (?*const anyopaque, ?*anyopaque, usize, nccl.ncclDataType_t, nccl.ncclRedOp_t, nccl.ncclComm_t, nccl.cudaStream_t) callconv(.C) nccl.ncclResult_t;
const Bcast_fnt = *const fn (?*anyopaque, usize, nccl.ncclDataType_t, c_int, nccl.ncclComm_t, nccl.cudaStream_t) callconv(.C) nccl.ncclResult_t;
const Broadcast_fnt = *const fn (?*const anyopaque, ?*anyopaque, usize, nccl.ncclDataType_t, c_int, nccl.ncclComm_t, nccl.cudaStream_t) callconv(.C) nccl.ncclResult_t;
const Reduce_fnt = *const fn (?*const anyopaque, ?*anyopaque, usize, nccl.ncclDataType_t, nccl.ncclRedOp_t, c_int, nccl.ncclComm_t, nccl.cudaStream_t) callconv(.C) nccl.ncclResult_t;
const AllGather_fnt = *const fn (?*const anyopaque, ?*anyopaque, usize, nccl.ncclDataType_t, nccl.ncclComm_t, nccl.cudaStream_t) callconv(.C) nccl.ncclResult_t;
const ReduceScatter_fnt = *const fn (?*const anyopaque, ?*anyopaque, usize, nccl.ncclDataType_t, nccl.ncclRedOp_t, nccl.ncclComm_t, nccl.cudaStream_t) callconv(.C) nccl.ncclResult_t;

export fn ncclGetUniqueId(uniqueId: [*c]nccl.ncclUniqueId) nccl.ncclResult_t {
    proflib.init_proflib() catch return nccl.ncclSystemError;
    const fname = "ncclGetUniqueId";
    const origfn = proflib.grab_fn(fname, ncclGetUniqueId_fnt) catch return nccl.ncclSystemError;
    std.log.info("Intercepted {s}", .{fname});
    return origfn(uniqueId);
}
export fn ncclCommInitAll(comm: [*c]nccl.ncclComm_t, ndev: c_int, devlist: *const c_int) nccl.ncclResult_t {
    proflib.init_proflib() catch return nccl.ncclSystemError;
    const fname = "ncclCommInitAll";
    const origfn = proflib.grab_fn(fname, ncclCommInitAll_fnt) catch return nccl.ncclSystemError;

    std.log.info("Intercepted {s}", .{fname});
    return origfn(comm, ndev, devlist);
}

export fn ncclCommInitRankConfig(comm: [*c]nccl.ncclComm_t, nranks: c_int, commId: nccl.ncclUniqueId, rank: c_int, config: [*c]nccl.ncclConfig_t) nccl.ncclResult_t {
    proflib.init_proflib() catch return nccl.ncclSystemError;
    const fname = "ncclCommInitRankConfig";
    const origfn = proflib.grab_fn(fname, ncclCommInitRankConfig_fnt) catch return nccl.ncclSystemError;

    std.log.info("Intercepted {s}(rank: {}/{})", .{ fname, rank, nranks });

    return origfn(comm, nranks, commId, rank, config);
}

export fn ncclCommInitRank(comm: [*c]nccl.ncclComm_t, nranks: c_int, commId: nccl.ncclUniqueId, rank: c_int) nccl.ncclResult_t {
    proflib.init_proflib() catch return nccl.ncclSystemError;
    const fname = "ncclCommInitRank";
    const origfn = proflib.grab_fn(fname, ncclCommInitRank_fnt) catch return nccl.ncclSystemError;

    std.log.info("Intercepted {s}(rank: {}/{})", .{ fname, rank, nranks });
    return origfn(comm, nranks, commId, rank);
}

export fn ncclAllReduce(sendbuff: ?*const anyopaque, recvbuff: ?*anyopaque, count: usize, datatype: nccl.ncclDataType_t, op: nccl.ncclRedOp_t, comm: nccl.ncclComm_t, stream: nccl.cudaStream_t) nccl.ncclResult_t {
    const fname = "ncclAllReduce";
    const origfn = proflib.grab_fn(fname, AllReduce_fnt) catch return nccl.ncclSystemError;
    proflib.prof_coll(proflib.Coll.all_reduce, msize(count, datatype));
    return origfn(sendbuff, recvbuff, count, datatype, op, comm, stream);
}

export fn ncclBcast(buff: ?*anyopaque, count: usize, datatype: nccl.ncclDataType_t, root: c_int, comm: nccl.ncclComm_t, stream: nccl.cudaStream_t) nccl.ncclResult_t {
    const fname = "ncclBcast";
    const origfn = proflib.grab_fn(fname, Bcast_fnt) catch return nccl.ncclSystemError;
    proflib.prof_coll(proflib.Coll.broadcast, msize(count, datatype));
    return origfn(buff, count, datatype, root, comm, stream);
}

export fn ncclBroadcast(sendbuff: ?*const anyopaque, recvbuff: ?*anyopaque, count: usize, datatype: nccl.ncclDataType_t, root: c_int, comm: nccl.ncclComm_t, stream: nccl.cudaStream_t) nccl.ncclResult_t {
    const fname = "ncclBroadcast";
    const origfn = proflib.grab_fn(fname, Broadcast_fnt) catch return nccl.ncclSystemError;
    proflib.prof_coll(proflib.Coll.broadcast, count);
    return origfn(sendbuff, recvbuff, count, datatype, root, comm, stream);
}

export fn ncclReduce(sendbuff: ?*const anyopaque, recvbuff: ?*anyopaque, count: usize, datatype: nccl.ncclDataType_t, op: nccl.ncclRedOp_t, root: c_int, comm: nccl.ncclComm_t, stream: nccl.cudaStream_t) nccl.ncclResult_t {
    const fname = "ncclReduce";
    const origfn = proflib.grab_fn(fname, Reduce_fnt) catch return nccl.ncclSystemError;
    proflib.prof_coll(proflib.Coll.reduce, count);
    return origfn(sendbuff, recvbuff, count, datatype, op, root, comm, stream);
}

export fn ncclAllGather(sendbuff: ?*const anyopaque, recvbuff: ?*anyopaque, sendcount: usize, datatype: nccl.ncclDataType_t, comm: nccl.ncclComm_t, stream: nccl.cudaStream_t) nccl.ncclResult_t {
    const fname = "ncclAllGather";
    const origfn = proflib.grab_fn(fname, AllGather_fnt) catch return nccl.ncclSystemError;
    proflib.prof_coll(proflib.Coll.all_gather, sendcount);
    return origfn(sendbuff, recvbuff, sendcount, datatype, comm, stream);
}

export fn ncclReduceScatter(sendbuff: ?*const anyopaque, recvbuff: ?*anyopaque, recvcount: usize, datatype: nccl.ncclDataType_t, op: nccl.ncclRedOp_t, comm: nccl.ncclComm_t, stream: nccl.cudaStream_t) nccl.ncclResult_t {
    const fname = "ncclReduceScatter";
    const origfn = proflib.grab_fn(fname, ReduceScatter_fnt) catch return nccl.ncclSystemError;
    proflib.prof_coll(proflib.Coll.reduce_scatter, msize(recvcount, datatype));
    return origfn(sendbuff, recvbuff, recvcount, datatype, op, comm, stream);
}
