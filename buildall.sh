#!/bin/bash

# Pass in one arg to specify the install directory.
# Default = ../install/rv32i

if [ "$1" = "" ]; then
	INSTALL_DIR=$HOME/opt/rv32i_qemu
else
	INSTALL_DIR=$1
fi

echo "Installing into: $INSTALL_DIR"


# FYI - These should have already been run once before the first time this script is run:
# ./installdeps.sh
# ./setup.sh

# configure and build gcc & friends
cd riscv-gnu-toolchain
./configure --prefix=$INSTALL_DIR --with-arch=rv32i --with-multilib-generator="rv32i-ilp32--;rv32ima-ilp32--;rv32imafd-ilp32--"
# use double core to compile
make -j 2


# configure and build qemu
cd ../qemu
./configure --target-list=aarch64-softmmu,arm-softmmu,aarch64-linux-user,arm-linux-user,riscv32-softmmu,riscv64-softmmu,riscv64-linux-user,riscv32-linux-user --prefix=$INSTALL_DIR
# use double core to compile
make -j 2
make install
