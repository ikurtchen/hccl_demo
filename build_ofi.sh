#!/bin/bash

mv /opt/amazon /opt/amazon.bak

export LIBFABRIC_VERSION=1.18.0
export UCX_VERSION=1.13.1
export OPENMPI_VERSION=4.1.5

unset MPICC
unset OPAL_PREFIX
unset MPI_ROOT

export NEW_PKGS_DIR=/opt/amazon

mkdir -p $NEW_PKGS_DIR
wget https://github.com/ofiwg/libfabric/releases/download/v${LIBFABRIC_VERSION}/libfabric-${LIBFABRIC_VERSION}.tar.bz2 -P /tmp/lib
cd /tmp/lib
tar -xf ./libfabric-${LIBFABRIC_VERSION}.tar.bz2
cd ./libfabric-${LIBFABRIC_VERSION}
./configure --prefix=$NEW_PKGS_DIR/efa/ --enable-psm3-verbs --enable-verbs=yes --enable-debug
make all -j 40
make install
$NEW_PKGS_DIR/efa/bin/fi_info -l

wget https://github.com/openucx/ucx/releases/download/v${UCX_VERSION}/ucx-${UCX_VERSION}.tar.gz -P /tmp/ucx
cd /tmp/ucx
tar -xf ./ucx-${UCX_VERSION}.tar.gz
cd ./ucx-${UCX_VERSION}
./configure --prefix=$NEW_PKGS_DIR/ucx
make -j 40
make install

wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-${OPENMPI_VERSION}.tar.bz2 -P /tmp/openmpi
cd /tmp/openmpi
tar -xf ./openmpi-${OPENMPI_VERSION}.tar.bz2
cd ./openmpi-${OPENMPI_VERSION}
./configure --prefix=$NEW_PKGS_DIR/openmpi --with-sge --disable-builtin-atomics --enable-orterun-prefixby-default --with-ucx=$NEW_PKGS_DIR/ucx --with-verbs
make -j 40
make install
export MPICC=$NEW_PKGS_DIR/openmpi/bin/mpicc
export OPAL_PREFIX=$NEW_PKGS_DIR/openmpi
export MPI_ROOT=$NEW_PKGS_DIR/openmpi
