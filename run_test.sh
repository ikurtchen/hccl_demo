#!/bin/bash
MY_SCRIPT_DIR="$( cd "$(dirname "$0")" && pwd )"

TEST_CASE=
USE_MPI=0
CLEAN=0
LOOP=1000
SIZE=
SIZE_RANGE=
SIZE_RANGE_INC=1
LOG_LEVEL=-1
LOG_DIR="${MY_SCRIPT_DIR}/habana_logs"
HOSTS_FILE="${MY_SCRIPT_DIR}/hostsfile"
# when not using MPI
RANKS=8
RANKS_PERNODE=8
COMM_ID="198.10.1.11:5555"
NODE_ID=0

show_help() {
    echo "Usage: $0 [OPTIONS]
This script is used to run hccl demo.

Options:
-t, --test <test>                   Test case: broadcast, all_reduce, reduce_scatter, all_gather, send_recv, reduce, all2all.
--mpi                               Use mpirun to do the test.
--clean                             Do clean when make.
--loop <loop>                       Test loop, e.g. 1000.
--size <size>                       Communication size, e.g. 32M.
--size_range <range>                Communication size range, e.g. 1M 2G.
--size_range_inc <step>             Step: 2^SIZE_RANGE_INC, e.g. 1.
--hostsfile <file>                  Hosts file for mpirun.
--ranks <ranks>                     Ranks.
--ranks_pernode <ranks>             Ranks per node.
--comm_id <comm>                    Comm id, e.g. 192.168.1.101:5555.
--node_id <node>                    Node id, e.g. 0.
--log_level <level>                 Capture HCL log if level >= 0.
--log_dir <dir>                     HCL log save dir if enabled, default: ${MY_SCRIPT_DIR}/habana_logs.
-h, --help                          Show this help text.
"
}

die(){
    local _EXIT_CODE=$(( $? == 0 ? 99 : $? ))
    echo "ERROR: $*"
    exit ${_EXIT_CODE}
}

while [ $# -gt 0 ] ; do
    case "$1" in
        -t|--test)
            TEST_CASE="${2:-}"
            shift; shift;;
        --mpi)
            USE_MPI=1
            shift;;
        --clean)
            CLEAN=1
            shift;;
        --loop)
            LOOP="${2:-${LOOP}}"
            shift; shift;;
        --size)
            SIZE="${2:-}"
            shift; shift;;
        --size_range)
            SIZE_RANGE="${2:-}"
            shift; shift;;
        --size_range_inc)
            SIZE_RANGE_INC="${2:-${SIZE_RANGE_INC}}"
            shift; shift;;
        --hostsfile)
            HOSTS_FILE="${2:-${HOSTS_FILE}}"
            shift; shift;;
        --ranks)
            RANKS="${2:-${RANKS}}"
            shift; shift;;
        --ranks_pernode)
            RANKS_PERNODE="${2:-${RANKS_PERNODE}}"
            shift; shift;;
        --comm_id)
            COMM_ID="${2:-${COMM_ID}}"
            shift; shift;;
        --node_id)
            NODE_ID="${2:-${NODE_ID}}"
            shift; shift;;
        --log_level)
            LOG_LEVEL="${2:-${LOG_LEVEL}}"
            shift; shift;;
        --log_dir)
            LOG_DIR="${2:-${LOG_DIR}}"
            shift; shift;;
        -h|--help)
            show_help
            exit 0;;
        *)
            show_help && die "Unknown parameter '$1'"
    esac
done

if [ -z "${TEST_CASE}" ]; then
    die "Test case is required."
fi

convert_to_bytes() {
  local size_str="$1"
  local size_number
  local unit

  # Extract the numeric part and the unit
  size_number=$(echo "$size_str" | grep -oP '^\d+')
  unit=$(echo "$size_str" | grep -oP '[A-Za-z]+$')

  # Convert to bytes based on the unit
  case "$unit" in
    B|b)
      echo $((size_number))
      ;;
    K|k)
      echo $((size_number * 1024))
      ;;
    M|m)
      echo $((size_number * 1024 * 1024))
      ;;
    G|g)
      echo $((size_number * 1024 * 1024 * 1024))
      ;;
    *)
      echo $((size_number))
      ;;
  esac
}

#export HABANA_PROFILE=1
#export HABANA_PROFILE=profile_api_with_nics

# logs
if [ ${LOG_LEVEL} -ge 0 ]; then
    export HABANA_LOGS=${LOG_DIR}
    export LOG_LEVEL_HCL=${LOG_LEVEL}
fi

CURRENT_TIME=$(date "+%Y.%m.%d-%H.%M.%S")
LOG_FILE="${MY_SCRIPT_DIR}/log_hccl_demo_${TEST_CASE}_mpi${USE_MPI}_s${SIZE}_${SIZE_RANGE// /_}_l${LOOP}_${CURRENT_TIME}.txt"

if [ ${USE_MPI} -eq 1 ]; then
    if [ -n "${SIZE}" ]; then
        SIZE_ARGS="-x HCCL_DEMO_TEST_SIZE=${SIZE}"
        SIZE_RANGE_ARGS=
    else
        SIZE_ARGS=
        SIZE_RANGE_MIN=$(echo "${SIZE_RANGE}" | awk '{print $1}')
        SIZE_RANGE_MAX=$(echo "${SIZE_RANGE}" | awk '{print $2}')
        SIZE_RANGE_MIN_IN_BYTES=$(convert_to_bytes ${SIZE_RANGE_MIN})
        SIZE_RANGE_MAX_IN_BYTES=$(convert_to_bytes ${SIZE_RANGE_MAX})
        SIZE_RANGE_ARGS="-x HCCL_SIZE_RANGE_MIN=${SIZE_RANGE_MIN_IN_BYTES} -x HCCL_SIZE_RANGE_MAX=${SIZE_RANGE_MAX_IN_BYTES} -x HCCL_SIZE_RANGE_INC=${SIZE_RANGE_INC}"
    fi
    if [ ${CLEAN} -eq 0 ]; then
        CLEAN_ARGS=
    else
        CLEAN_ARGS="-clean"
    fi

    python3 run_hccl_demo.py \
        --test ${TEST_CASE} \
        --loop ${LOOP} \
        ${CLEAN_ARGS} \
        -mpi \
        -x MPICC=/opt/openmpi/bin/mpicc \
        -x OPAL_PREFIX=/opt/openmpi \
        -x MPI_ROOT=/opt/openmpi \
        -x PATH=/opt/openmpi/bin:${PATH} \
        -x PKG_CONFIG_PATH \
        ${SIZE_ARGS} \
        ${SIZE_RANGE_ARGS} \
        -x LIBFABRIC_ROOT=/opt/habanalabs/libfabric-1.20.0 \
        -x LD_LIBRARY_PATH=/opt/habanalabs/libfabric-1.20.0/lib:$LD_LIBRARY_PATH \
        -x HCCL_OVER_OFI=1 -x HCCL_GAUDI_DIRECT=1 \
        --hostfile ${HOSTS_FILE}
        # --mca plm_rsh_args \"-p 3223\"
        # --host 192.168.1.101:8,192.168.1.109:8
else
    if [ -n "${SIZE}" ]; then
        SIZE_ARGS="--size ${SIZE}"
        SIZE_RANGE_ARGS=
    else
        SIZE_ARGS=
        SIZE_RANGE_ARGS="--size_range ${SIZE_RANGE} --size_range_inc ${SIZE_RANGE_INC}"
    fi
    if [ ${CLEAN} -eq 0 ]; then
        CLEAN_ARGS=
    else
        CLEAN_ARGS="-clean"
    fi

    HCCL_COMM_ID=${COMM_ID} python3 run_hccl_demo.py \
        --nranks ${RANKS} \
        --node_id ${NODE_ID} \
        ${SIZE_ARGS} \
        ${SIZE_RANGE_ARGS} \
        --test ${TEST_CASE} \
        --loop ${LOOP} \
        --ranks_per_node ${RANKS_PERNODE} ${CLEAN_ARGS} 2>&1 | tee ${LOG_FILE}
fi


