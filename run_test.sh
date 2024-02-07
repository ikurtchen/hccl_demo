#!/bin/bash
MY_SCRIPT_DIR="$( cd "$(dirname "$0")" && pwd )"

export HCCL_OVER_OFI=0

# config
USE_MPI=0
#CLEAN=""
CLEAN="-clean"
LOOP=1000
RANKS=8
RANKS_PERNODE=8
COMM_ID="127.0.0.1:5555"
NODE_ID=0
#SIZE=
SIZE="--size 32M"
SIZE_RANGE=
#SIZE_RANGE="--size_range 1M 2G --size_range_inc 1" # Step: 2^${SIZE_RANGE_INC}

# tests
#TEST_CASE=broadcast
TEST_CASE=all_reduce
#TEST_CASE=reduce_scatter
#TEST_CASE=all_gather
#TEST_CASE=send_recv
#TEST_CASE=reduce
#TEST_CASE=all2all
#TEST_CASE="broadcast all_reduce reduce_scatter all_gather send_recv reduce all2all"

# logs
#export HABANA_LOGS=${MY_SCRIPT_DIR}/habana_logs
#export LOG_LEVEL_ALL_HCL=0


for TEST in "${TEST_CASE}"; do
    if [ ${USE_MPI} -eq 1 ]; then
        python3 run_hccl_demo.py --test ${TEST} ${SIZE} ${SIZE_RANGE} --loop ${LOOP} -mpi -np ${RANKS} ${CLEAN}
    else
        HCCL_COMM_ID=${COMM_ID} python3 run_hccl_demo.py --nranks ${RANKS} --node_id ${NODE_ID}  ${SIZE} ${SIZE_RANGE} --test ${TEST} --loop ${LOOP} --ranks_per_node ${RANKS_PERNODE} ${CLEAN}
    fi
done
