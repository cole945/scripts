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
# GLIBC_SRC=$SRC_BASE/glibc-2.17
# LINUX_SRC=$HOME/Downloads/linux
# NEWLIB_SRC=/srv/snapshot/newlib-1.20.0
NEWLIB_SRC=$SRC_BASE/newlib-2.0.0

#
# Target Configurations
#
TARGET=
LINUX_DEFAULT_CONFIG=
GCC_CONFIG=
source build.conf

### DO NOT EDIT FOLLOWING ###

WORKDIR=$PWD
HOST_TOOLS=$WORKDIR/host-tools
PREFIX=$WORKDIR/sysroot-$TARGET
SYSROOT=$PREFIX/$TARGET/libc
LOG=$WORKDIR/build.log

# Check settings
for x in TARGET ; do
  eval val="\$$x"
  echo $x=$val

  if [ -z "$val" ]; then
    echo Missing configuration.
    exit 1
  fi
done

for x in GMP_SRC MPFR_SRC MPC_SRC CLOOG_SRC BINUTILS_SRC GCC_SRC ; do
  eval val="\$$x"
  echo $x=$val
done

# ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ----

#
# Reset PATH
#

export PATH=$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
hash -r


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



# ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ---- >8 ----

#
# Reset PATH
#

export PATH=$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Clean-up PATH hash cache.
hash -r

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
# Build GCC
#

# Don't use --enable-multilib
# It's enabled by default, and it break zlib.
# http://gcc.gnu.org/bugzilla/show_bug.cgi?id=45174
mkdir -p $WORKDIR/build-gcc-final
cd $WORKDIR/build-gcc-final
$GCC_SRC/configure \
   --target=$TARGET \
   --prefix=$PREFIX \
   --disable-nls \
   --disable-shared \
   --enable-languages=c,c++ \
   --enable-__cxa_atexit \
   --enable-c99 \
   --enable-long-long \
   --disable-multilib \
   --disable-threads \
   --disable-libssp \
   --disable-libgomp \
   --disable-decimal-float \
   --disable-libffi \
   --disable-libmudflap \
   --with-gmp=$HOST_TOOLS \
   --with-mpfr=$HOST_TOOLS \
   --with-mpc=$HOST_TOOLS \
   --with-cloog=$HOST_TOOLS \
   --without-headers \
   --with-newlib \
   $GCC_CONFIG \
   CFLAGS_FOR_HOST="-g3 -O0" &&
make -j 8 all-gcc &&
make install-gcc || exit 1
hash -r

#
# Build Target libgcc
#

echo `date ` Build Target libgcc | tee -a $LOG
cd $WORKDIR/build-gcc-bootstrap
make all-target-libgcc -j 8 &&
make install-target-libgcc || exit 1

#
# Build Newlib
#

mkdir -p $WORKDIR/build-newlib
cd $WORKDIR/build-newlib
$NEWLIB_SRC/configure \
   --target=$TARGET \
   --prefix=$PREFIX \
   --disable-newlib-supplied-syscalls \
   CFLAGS_FOR_TARGET="-O2 -falign-functions=8" &&
make -j 8 &&
make install

echo "export PATH=$PREFIX/bin:\$PATH" > $WORKDIR/env.sh

echo `date ` Done | tee -a $LOG
