#!/bin/bash

set -ex

MY_SCRIPT_DIR="$( cd "$(dirname "$0")" && pwd )"

#TEST_CASES="broadcast all_reduce reduce_scatter all_gather send_recv reduce all2all"
TEST_CASES="all_reduce"

for t in ${TEST_CASES}; do
    # mpi
    bash ${MY_SCRIPT_DIR}/run_test.sh -t ${t} --mpi --clean --loop 1000 --size 32M --hostsfile "${MY_SCRIPT_DIR}/hostsfile"
    #bash ${MY_SCRIPT_DIR}/run_test.sh -t ${t} --mpi --clean --loop 1000 --size_range "128K 128M" --hostsfile "${MY_SCRIPT_DIR}/hostsfile"
    # no mpi
    #bash ${MY_SCRIPT_DIR}/run_test.sh -t ${t} --clean --ranks 8 --ranks_pernode 8 --comm_id "192.168.1.101:5555" --node_id 0 --loop 1000 --size 32M
    #bash ${MY_SCRIPT_DIR}/run_test.sh -t ${t} --clean --ranks 8 --ranks_pernode 8 --comm_id "192.168.1.101:5555" --node_id 0 --loop 1000 --size_range "128K 128M"
done
