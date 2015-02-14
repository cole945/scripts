#!/bin/bash


GMP_SRC=/srv/snapshot/gmp-4.3.2
MPFR_SRC=/srv/snapshot/mpfr-2.4.2
MPC_SRC=/srv/snapshot/mpc-0.8.1
PPL_SRC=/srv/snapshot/ppl-0.11.2
CLOOG_PPL_SRC=/srv/snapshot/cloog-ppl-0.15.11

GCC_SRC=/srv/snapshot/gcc-4.7.3
BINUTILS_SRC=/srv/snapshot/binutils-2.23.2
MING_W64_SRC=/srv/snapshot/mingw-w64-v2.0.8

TARGET=i686-w64-mingw32
WORKING=$PWD/build
PREFIX=$PWD/sysroot
SYSROOT=$PREFIX/$TARGET
HOST_TOOLS=$PWD/host-tools

export PATH=$PREFIX/bin:$PATH

#
# Build host tools
#

# Build GMP

mkdir -p $WORKING/build-gmp
cd $WORKING/build-gmp
$GMP_SRC/configure \
  --prefix=$HOST_TOOLS \
  --enable-cxx \
  --disable-shared &&
make -j 8 &&
make install || exit 1


# Build MPFR

mkdir -p $WORKING/build-mpfr
cd $WORKING/build-mpfr
$MPFR_SRC/configure \
  --prefix=$HOST_TOOLS \
  --with-gmp=$HOST_TOOLS \
  --disable-shared &&
make -j 8 &&
make install || exit 1


# Build MPC

mkdir -p $WORKING/build-mpc
cd $WORKING/build-mpc
$MPC_SRC/configure \
  --prefix=$HOST_TOOLS \
  --with-gmp=$HOST_TOOLS \
  --with-mpfr=$HOST_TOOLS \
  --disable-shared &&
make -j 8 &&
make install || exit 1


# Build PPL

mkdir -p $WORKING/build-ppl
cd $WORKING/build-ppl
$PPL_SRC/configure \
  --prefix=$HOST_TOOLS \
  --with-gmp-prefix=$HOST_TOOLS \
  --disable-shared &&
make -j 8 &&
make install || exit 1


# Build CLooG-PPL

mkdir -p $WORKING/build-cloog-ppl
cd $WORKING/build-cloog-ppl
$CLOOG_PPL_SRC/configure \
  --prefix=$HOST_TOOLS \
  --with-gmp=$HOST_TOOLS \
  --with-ppl=$HOST_TOOLS \
  --with-host-libstdcxx="-lstdc++ -lsupc++" \
  --disable-shared &&
make -j 8 &&
make install || exit 1

#
# Build toolchain
#

# Build binutils

mkdir -p $WORKING/build-binutils
cd $WORKING/build-binutils
$BINUTILS_SRC/configure \
  --prefix=$PREFIX \
  --with-sysroot=$SYSROOT \
  --target=$TARGET &&
make -j 8 &&
make install || exit 1


# Build MinGW headers

mkdir -p $WORKING/build-headers
cd $WORKING/build-headers
$MING_W64_SRC/mingw-w64-headers/configure \
  --host=$TARGET \
  --prefix=$PREFIX &&
make install || exit 1

# gcc find system headers under mingw instead of $TARGET,
# so we manually create a link to $TARGET
#    The directory that should contain system headers does not exist:
#      /playground/cole/build/mingw32-w64/sysroot/mingw/include
cd $PREFIX
ln -s $TARGET mingw


# Build core gcc
#  --with-host-libstdcxx, because we are linking against static host-tools.

mkdir -p $WORKING/build-gcc
cd $WORKING/build-gcc
$GCC_SRC/configure \
   --target=$TARGET \
   --prefix=$PREFIX  \
   --with-sysroot=$PREFIX  \
   --with-mpc=$HOST_TOOLS \
   --with-mpfr=$HOST_TOOLS \
   --with-gmp=$HOST_TOOLS \
   --with-ppl=$HOST_TOOLS \
   --with-cloog=$HOST_TOOLS \
   --with-host-libstdcxx="-lstdc++ -lsupc++" \
   --enable-version-specific-runtime-libs \
   --enable-shared \
   --enable-languages=c,c++ \
   --enable-c99 \
   --enable-long-long \
   --enable-threads=win32 \
   --enable-sjlj-exceptions \
   --disable-multilib \
   --disable-libssp \
   --disable-nls \
   --disable-libgomp \
   --disable-decimal-float \
   --disable-libffi \
   --disable-libmudflap &&
make -j 8 all-gcc &&
make install-gcc || exit 1

# Rehash PATH, so newly built tool-chain is used.
hash -r


# Build MinGW C Run-time

mkdir -p $WORKING/build-mingw-w64
cd $WORKING/build-mingw-w64
$MING_W64_SRC/configure \
  --host=$TARGET \
  --prefix=$PREFIX &&
make -j 8 &&
make install || exit 1


# Built libgcc and rest of gcc.

cd $WORKING/build-gcc
make &&
make install || exit 1
