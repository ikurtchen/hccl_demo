#!/bin/bash
MY_SCRIPT_DIR="$( cd "$(dirname "$0")" && pwd )"

export HCCL_OVER_OFI=0

# config
USE_MPI=0
CLEAN=""
#CLEAN="-clean"

# tests
TEST_CASE=broadcast
#TEST_CASE=all_reduce
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
#export LOG_LEVEL_ALL=0


if [ ${USE_MPI} -eq 1 ]; then
    python3 run_hccl_demo.py --size 32m --test ${TEST_CASE} --loop 1000 -mpi -np 8 ${CLEAN}
else
    HCCL_COMM_ID=127.0.0.1:5555 python3 run_hccl_demo.py --nranks 8 --node_id 0 --size 32m --test ${TEST_CASE} --loop 1000 --ranks_per_node 8 ${CLEAN}
fi
