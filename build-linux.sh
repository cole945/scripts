#!/bin/bash

#
# Target-independent Configurations
#
SRC_BASE=${HOME}/snapshot
# Host-tools
GMP_SRC=$SRC_BASE/gmp-5.1.2
MPFR_SRC=$SRC_BASE/mpfr-3.1.2
MPC_SRC=$SRC_BASE/mpc-1.0.1
# ISL_SRC=$SRC_BASE/isl-0.11.1
CLOOG_SRC=$SRC_BASE/cloog-0.18.0

# Tool-chain
BINUTILS_SRC=$SRC_BASE/binutils-2.24
GCC_SRC=$SRC_BASE/gcc-4.8.2
# GCC_SRC=$HOME/repos/gcc
GLIBC_SRC=$SRC_BASE/glibc-2.18
LINUX_SRC=$SRC_BASE/linux-3.12.4

# Other config
RUN_GCC_TESTSUITE=

#
# Target Configurations
#
TARGET=
LINUX_DEFAULT_CONFIG=
GCC_CONFIG=
ARCH=
source build.conf

### DO NOT EDIT FOLLOWING ###

WORKDIR=$PWD
HOST_TOOLS=$WORKDIR/host-tools
PREFIX=$WORKDIR/sysroot-$TARGET
SYSROOT=$PREFIX/$TARGET/libc
LOG=$WORKDIR/build.log

# Check settings
for x in ARCH TARGET LINUX_DEFAULT_CONFIG ; do
  eval val="\$$x"
  echo $x=$val

  if [ -z "$val" ]; then
    echo Missing configuration.
    exit 1
  fi
done

for x in GMP_SRC MPFR_SRC MPC_SRC CLOOG_SRC BINUTILS_SRC GCC_SRC GLIBC_SRC LINUX_SRC; do
  eval val="\$$x"
  echo $x=$val
done

# ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ----

#
# Reset PATH
#

OLD_PATH="$PATH"
export PATH=$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/sysroot/bin

#
# Build host tools
#

# Build GMP

echo `date ` Build GMP | tee -a $LOG
mkdir -p $WORKDIR/build-gmp
cd $WORKDIR/build-gmp
$GMP_SRC/configure \
  --prefix=$HOST_TOOLS \
  --enable-cxx \
  --disable-shared &&
make -j 8 &&
make install || exit 1


# Build MPFR

echo `date ` Build MPFR | tee -a $LOG
mkdir -p $WORKDIR/build-mpfr
cd $WORKDIR/build-mpfr
$MPFR_SRC/configure \
  --prefix=$HOST_TOOLS \
  --with-gmp=$HOST_TOOLS \
  --disable-shared &&
make -j 8 &&
make install || exit 1


# Build MPC

echo `date ` Build MPC | tee -a $LOG
mkdir -p $WORKDIR/build-mpc
cd $WORKDIR/build-mpc
$MPC_SRC/configure \
  --prefix=$HOST_TOOLS \
  --with-gmp=$HOST_TOOLS \
  --with-mpfr=$HOST_TOOLS \
  --disable-shared &&
make -j 8 &&
make install || exit 1


# Build CLooG-isl

echo `date ` Build ClooG-isl | tee -a $LOG
mkdir -p $WORKDIR/build-cloog-isl
cd $WORKDIR/build-cloog-isl
$CLOOG_SRC/configure \
  --prefix=$HOST_TOOLS \
  --with-gmp=build \
  --with-gmp-builddir=$WORKDIR/build-gmp \
  --with-isl=bundled \
  --with-bits=gmp \
  --with-host-libstdcxx="-lstdc++ -lsupc++" \
  --disable-shared &&
make -j 8 &&
make install || exit 1

# # # # # # # # #

#
# prepare linux headers
#
# headers_check ???

echo `date ` Build Linux Headers | tee -a $LOG
mkdir -p $SYSROOT
mkdir -p $WORKDIR/build-linux-headers
cd $LINUX_SRC
make ARCH=$ARCH \
     O=$WORKDIR/build-linux-headers \
     INSTALL_HDR_PATH=$SYSROOT/usr \
     $LINUX_DEFAULT_CONFIG \
     headers_install || exit 1

#
# Build binutils
#

echo `date ` Build Binutils | tee -a $LOG
mkdir -p $WORKDIR/build-binutils
cd $WORKDIR/build-binutils
$BINUTILS_SRC/configure \
  --target=$TARGET \
  --with-sysroot=$SYSROOT \
  --prefix=$PREFIX \
  --disable-werror \
  --disable-nls &&
make -j 8 &&
make install || exit 1

#
# Build Stage 1 GCC
#

echo `date ` Build GCC Stage 1 | tee -a $LOG
# For arm, libgcc must be built with optimization.
mkdir -p $WORKDIR/build-gcc-bootstrap
cd $WORKDIR/build-gcc-bootstrap
$GCC_SRC/configure \
   --target=$TARGET \
   --prefix=$PREFIX \
   --with-sysroot=$SYSROOT \
   --disable-nls \
   --disable-shared \
   --enable-languages=c \
   --enable-__cxa_atexit \
   --enable-c99 \
   --enable-long-long \
   --disable-threads \
   --disable-multilib \
   --disable-libssp \
   --disable-libgomp \
   --disable-decimal-float \
   --disable-libffi \
   --disable-libmudflap \
   --with-gmp=$HOST_TOOLS \
   --with-mpfr=$HOST_TOOLS \
   --with-mpc=$HOST_TOOLS \
   --with-cloog=$HOST_TOOLS \
   --with-headers \
   $GCC_CONFIG &&
make all-gcc -j 8 &&
make install-gcc || exit 1
hash -r

#
# Prepare Glibc Headers
#

echo `date ` Build glibc headers | tee -a $LOG
# configure: error: forced unwind support is required
#   Set libc_cv_forced_unwind=yes
mkdir -p $WORKDIR/build-glibc
cd $WORKDIR/build-glibc
libc_cv_forced_unwind=yes \
$GLIBC_SRC/configure \
  --prefix=/usr \
  --host=$TARGET \
  --without-cvs \
  --enable-add-ons=nptl,ports \
  --disable-profile \
  --without-selinux \
  --with-tls \
  --with-headers=$SYSROOT/usr/include \
  --enable-kernel=2.6.20 &&
make install_root=$SYSROOT install-headers || exit 1


#
# Create dummy gnu/stubs.h
#
touch $SYSROOT/usr/include/gnu/stubs.h || exit 1

#
# Workaround for aarch64 lib64 issue
#
mkdir -p $SYSROOT/usr/lib

#
# Build Target libgcc
#

echo `date ` Build Target libgcc | tee -a $LOG
cd $WORKDIR/build-gcc-bootstrap
make all-target-libgcc -j 8 &&
make install-target-libgcc || exit 1

#
# Build Glibc
#
echo `date ` Build glibc | tee -a $LOG
cd $WORKDIR/build-glibc
make -j 8 &&
make install_root=$SYSROOT install || exit 1

#
# Build Final GCC
#

echo `date ` Build Final GCC | tee -a $LOG
mkdir -p $WORKDIR/build-gcc-final
cd $WORKDIR/build-gcc-final
$GCC_SRC/configure \
   --target=$TARGET \
   --prefix=$PREFIX \
   --with-sysroot=$SYSROOT \
   --disable-nls \
   --enable-shared \
   --enable-languages=c,c++ \
   --enable-__cxa_atexit \
   --enable-c99 \
   --enable-long-long \
   --enable-threads=posix \
   --disable-libssp \
   --disable-libgomp \
   --disable-decimal-float \
   --disable-libffi \
   --disable-libmudflap \
   --with-gmp=$HOST_TOOLS \
   --with-mpfr=$HOST_TOOLS \
   --with-mpc=$HOST_TOOLS \
   --with-cloog=$HOST_TOOLS \
   --with-headers \
   $GCC_CONFIG &&
make all -j 8 &&
make install || exit 1
hash -r

# End of building.  Running post testing.

# Restore PATH, so we have runtest, qemu, etc
export PATH=$OLD_PATH

if [ -n "$RUN_GCC_TESTSUITE" ]; then
  echo `date ` Run gcc-testsuite | tee -a $LOG
  cd $WORKDIR/build-gcc-final/gcc
  make check RUNTESTFLAGS="--target_board=aarch64-qemu"
fi

echo `date ` Done | tee -a $LOG
