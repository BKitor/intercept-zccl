#!/usr/bin/bash

set -e

NCCLTST_DIR=/home/user/bkitor/bk_share/rccl-tests
AR_TST=$NCCLTST_DIR/build/all_reduce_perf
BC_TST=$NCCLTST_DIR/build/broadcast_perf
RD_TST=$NCCLTST_DIR/build/reduce_perf
AG_TST=$NCCLTST_DIR/build/all_gather_perf
RS_TST=$NCCLTST_DIR/build/reduce_scatter_perf

NCCLTST_FLAGS="-b 16k -e 16k  -g 2 -f 2 -t 1 -w 1 -n 1 -m 1"
INJECT_SO=$PWD/zig-out/lib/libcclprof.so
export NCCL_CUMEM_ENABLE=0

export LD_LIBRARY_PATH="/home/user/bkitor/bk_share/nccl/build/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/home/user/bkitor/bk_share/fabrex-nccl/src/.libs:$LD_LIBRARY_PATH"

zig build -Dccl_flavour=rccl
echo "LD_PRELOAD=$INJECT_SO $AR_TST $NCCLTST_FLAGS"
# LD_PRELOAD=$INJECT_SO $AR_TST $NCCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $BC_TST $NCCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $RD_TST $NCCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $AG_TST $NCCLTST_FLAGS
# LD_PRELOAD=$INJECT_SO $RS_TST $NCCLTST_FLAGS

# export NCCL_DEBUG=Trace
# mpirun -np 2 -host bigtwin1d:1,bigtwin1c:1 -env LD_PRELOAD $INJECT_SO ldd $AR_TST 
mpirun -np 2 -host bigtwin1d:1,bigtwin1c:1 -env LD_PRELOAD $INJECT_SO $AR_TST $NCCLTST_FLAGS
mpirun -np 2 -host bigtwin1d:1,bigtwin1c:1 -env LD_PRELOAD $INJECT_SO $BC_TST $NCCLTST_FLAGS
mpirun -np 2 -host bigtwin1d:1,bigtwin1c:1 -env LD_PRELOAD $INJECT_SO $RS_TST $NCCLTST_FLAGS

# NCCLTST_FLAGS="-b 16k -e 16k  -g 1 -f 2 -t 1 -w 1 -n 1 -m 1"
# mpirun -np 4 -host bigtwin1d:2,bigtwin1c:2 -env LD_PRELOAD $INJECT_SO $AR_TST $NCCLTST_FLAGS
