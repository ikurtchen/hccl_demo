#!/bin/bash
MY_SCRIPT_DIR="$( cd "$(dirname "$0")" && pwd )"

set -x

#1.13
#export LIBFABRIC_ROOT=/opt/libfabric
#1.14
export LIBFABRIC_ROOT=/opt/habanalabs/libfabric-1.20.0
export LD_LIBRARY_PATH=${LIBFABRIC_ROOT}/lib:$LD_LIBRARY_PATH
export HCCL_OVER_OFI=1
export HCCL_GAUDI_DIRECT=1

# config
USE_MPI=0
#CLEAN=""
CLEAN="-clean"
LOOP=1000
RANKS=8
RANKS_PERNODE=8
COMM_ID="198.10.1.11:5555"
MPI_HOSTS="198.10.1.11:8,198.10.1.12:8"
MPI_SIZE_RANGE_MIN=33554432
MPI_SIZE_RANGE_MAX=1073741824
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
        # TODO requires verification
        python3 run_hccl_demo.py --test ${TEST_CASE} --loop ${LOOP} -mpi -x HCCL_SIZE_RANGE_MIN=${MPI_SIZE_RANGE_MIN} -x HCCL_SIZE_RANGE_MAX=${MPI_SIZE_RANGE_MAX} -x LIBFABRIC_ROOT=${LIBFABRIC_ROOT} -x LD_LIBRARY_PATH=${LIBFABRIC_ROOT}/lib:$LD_LIBRARY_PATH -x HCCL_OVER_OFI=1 -x HCCL_GAUDI_DIRECT=1 --host ${MPI_HOSTS} -x HCCL_COMM_ID=${COMM_ID}
    else
        HCCL_COMM_ID=${COMM_ID} python3 run_hccl_demo.py --nranks ${RANKS} --node_id ${NODE_ID}  ${SIZE} ${SIZE_RANGE} --test ${TEST} --loop ${LOOP} --ranks_per_node ${RANKS_PERNODE} ${CLEAN}
    fi
done
