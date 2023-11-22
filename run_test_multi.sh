#!/bin/bash
MY_SCRIPT_DIR="$( cd "$(dirname "$0")" && pwd )"

export LIBFABRIC_ROOT=/opt/libfabric
export LD_LIBRARY_PATH=/opt/libfabric/lib:$LD_LIBRARY_PATH
export HCCL_OVER_OFI=1
export HCCL_GAUDI_DIRECT=1

# config
USE_MPI=0
#CLEAN=""
CLEAN="-clean"

# tests
#TEST_CASE=broadcast
TEST_CASE=all_reduce
#TEST_CASE=reduce_scatter
#TEST_CASE=all_gather
#TEST_CASE=send_recv
#TEST_CASE=reduce
#TEST_CASE=all2all

# SynapseAI Profile
#hl-prof-config -e off -gaudi2 --use-template profile_api_with_nics
#hl-prof-config -e on -gaudi2 -phase=multi-enq -g 1-20 -s profiling_session_hccl_demo
#hl-prof-config -gaudi -e on -s profiling_session_hccl_demo \
#    --mme0_acc on --mme0_sbab on --mme0_ctrl off \
#    --mme1_acc off --mme1_sbab off --mme1_ctrl off \
#    --mme2_acc off --mme2_sbab off --mme2_ctrl off \
#    --mme3_acc off --mme3_sbab off --mme3_ctrl off \
#    --tpc0 on --tpc1 off --tpc2 off --tpc3 off --tpc4 off --tpc5 off --tpc6 off --tpc7 off \
#    --dma_ch0 on --dma_ch1 off --dma_ch2 off --dma_ch3 off --dma_ch4 off --dma_ch5 on --dma_ch6 off --dma_ch7 off  \
#    -g 1-10 --nic on

#export HABANA_PROFILE=1
#export HABANA_PROFILE=profile_api_with_nics

# logs
#export HABANA_LOGS=~/.habana_logs
#export LOG_LEVEL_ALL_HCL=0


if [ ${USE_MPI} -eq 1 ]; then
    python3 run_hccl_demo.py --test ${TEST_CASE} --loop 1000 --size 32m -mpi --hostfile hostfile.txt ${CLEAN}
else
    HCCL_COMM_ID=198.10.1.11:5555 python3 run_hccl_demo.py --test ${TEST_CASE} --nranks 16 --loop 1000 --node_id 0 --size 32m --ranks_per_node 8 ${CLEAN}
fi


