#!/usr/bin/bash

set -e

CCL_DIR=/home/user/bkitor/rccl/build/debug
export LD_LIBRARY_PATH=$CCL_DIR
CCLTST_DIR=/home/user/bkitor/rccl-tests
AR_TST=$CCLTST_DIR/build/all_reduce_perf
BC_TST=$CCLTST_DIR/build/broadcast_perf
RD_TST=$CCLTST_DIR/build/reduce_perf
AG_TST=$CCLTST_DIR/build/all_gather_perf
RS_TST=$CCLTST_DIR/build/reduce_scatter_perf

CCLTST_FLAGS="-b 16k -e 16k  -g 2 -f 2 -t 1 -w 1 -n 1 -m 1"
INJECT_SO=$PWD/zig-out/lib/libcclprof.so
# export NCCL_CUMEM_ENABLE=0

# export LD_LIBRARY_PATH="/home/user/bkitor/bk_share/nccl/build/lib:$LD_LIBRARY_PATH"
# export LD_LIBRARY_PATH="/home/user/bkitor/bk_share/fabrex-nccl/src/.libs:$LD_LIBRARY_PATH"

# zig build -DCCL_FLAVOUR=rccl
# LD_PRELOAD=$INJECT_SO $AR_TST $CCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $BC_TST $CCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $RD_TST $CCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $AG_TST $CCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $RS_TST $CCLTST_FLAGS

# export NCCL_DEBUG=Trace
CCLTST_FLAGS="-b 1k -e 8k -f 2 -g 4" 
# export LD_PRELOAD=$INJECT_SO
# ldd $AR_TST

# zig build 
zig build run -- --proflib_so new_profilb_sofile --out_file output_file -- $AR_TST $CCLTST_FLAGS
# ./zig-out/bin/cclprofrunner $AR_TST $CCLTST_FLAGS

