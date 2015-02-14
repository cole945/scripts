#!/bin/bash

set -e

##################################################################
## Target-independent Configurations
##################################################################

SRC_BASE=$HOME/snapshot
J="-j 12"

# Host-tools
BUILD_HOST_TOOLS=no
GMP_SRC=$SRC_BASE/gmp-5.1.2
MPFR_SRC=$SRC_BASE/mpfr-3.1.2
MPC_SRC=$SRC_BASE/mpc-1.0.1
CLOOG_SRC=$SRC_BASE/cloog-0.18.0

# Tool-chain
BINUTILS_SRC=$SRC_BASE/binutils-2.24
GCC_SRC=$SRC_BASE/gcc-4.9.2
GCC_LANGUAGES=c,c++
GLIBC_SRC=$SRC_BASE/glibc-2.20
LINUX_SRC=$SRC_BASE/linux-3.12.4

# Target Configurations
TARGET=
LINUX_DEFAULT_CONFIG=
# GCC_CONFIG="--enable-checking=no"
GCC_CONFIG=
ARCH=

source build.conf

### DO NOT EDIT FOLLOWING ###

WORKDIR=$PWD
HOST_TOOLS=$WORKDIR/host-tools
PREFIX=$WORKDIR/sysroot-$TARGET
SYSROOT=$PREFIX/$TARGET/libc
LOG=$WORKDIR/build.log

##################################################################
## Build Functions
##################################################################

#
# Check Settings
#
function require_settings() {
    for x in $@; do
        eval val="\$$x"

        if [ -z "$val" ]; then
          echo "Missing configuration, $x."
          exit 1
        fi
    done
}

#
# Dump Settings
#
function dump_settings() {
    for x in $@; do
        eval val="\$$x"
        echo $x=$val
    done
}

#
# Host Tools
#

#
# Build GMP
#
function build_gmp() {
    echo `date ` $FUNCNAME | tee -a $LOG
    mkdir -p $WORKDIR/build-gmp
    cd $WORKDIR/build-gmp

    test -f config.status ||
    $GMP_SRC/configure \
      --prefix=$HOST_TOOLS \
      --enable-cxx \
      --disable-shared

    make ${J}
    make install
}


#
# Build MPFR
#
function build_mpfr() {
    echo `date ` $FUNCNAME | tee -a $LOG
    mkdir -p $WORKDIR/build-mpfr
    cd $WORKDIR/build-mpfr

    test -f config.status ||
    $MPFR_SRC/configure \
      --prefix=$HOST_TOOLS \
      --with-gmp=$HOST_TOOLS \
      --disable-shared
    make ${J}
    make install
}


#
# Build MPC
#
function build_mpc() {
    echo `date ` $FUNCNAME | tee -a $LOG
    mkdir -p $WORKDIR/build-mpc
    cd $WORKDIR/build-mpc

    test -f config.status ||
    $MPC_SRC/configure \
      --prefix=$HOST_TOOLS \
      --with-gmp=$HOST_TOOLS \
      --with-mpfr=$HOST_TOOLS \
      --disable-shared

    make ${J}
    make install
}

#
# Build CLooG-isl
#
function build_cloogisl () {
    echo `date ` $FUNCNAME | tee -a $LOG
    mkdir -p $WORKDIR/build-cloog-isl
    cd $WORKDIR/build-cloog-isl

    test -f config.status ||
    $CLOOG_SRC/configure \
      --prefix=$HOST_TOOLS \
      --with-gmp=build \
      --with-gmp-builddir=$WORKDIR/build-gmp \
      --with-isl=bundled \
      --with-bits=gmp \
      --with-host-libstdcxx="-lstdc++ -lsupc++" \
      --disable-shared

    make ${J}
    make install
}

#
# prepare linux headers
#
# headers_check ???
function build_linux_headers() {
    echo `date ` $FUNCNAME | tee -a $LOG

    mkdir -p $WORKDIR/build-linux-headers
    cd $LINUX_SRC
    make ARCH=$ARCH \
         O=$WORKDIR/build-linux-headers \
         INSTALL_HDR_PATH=$SYSROOT/usr \
         $LINUX_DEFAULT_CONFIG \
         headers_install
}

#
# Build binutils
#
function build_binutils() {
    echo `date ` $FUNCNAME | tee -a $LOG

    mkdir -p $WORKDIR/build-binutils
    cd $WORKDIR/build-binutils

    test -f config.status ||
    $BINUTILS_SRC/configure \
      --target=$TARGET \
      --with-sysroot=$SYSROOT \
      --prefix=$PREFIX \
      --disable-werror \
      --disable-nls

    make ${J}
    make install
}

#
# Build Stage 1 GCC
#
function build_gcc_bootstrap() {
    echo `date ` $FUNCNAME | tee -a $LOG

    # For arm, libgcc must be built with optimization.
    mkdir -p $WORKDIR/build-gcc-bootstrap
    cd $WORKDIR/build-gcc-bootstrap

    test -f config.status ||
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
       --disable-libssp \
       --disable-libgomp \
       --disable-decimal-float \
       --disable-libffi \
       --disable-libmudflap \
       --with-headers \
       $WITH_HOST_TOOLS \
       $GCC_CONFIG

    make all-gcc ${J}
    make install-gcc
}

#
# Prepare Glibc Headers
#
function build_glibc_headers() {
    echo `date ` $FUNCNAME | tee -a $LOG

    # configure: error: forced unwind support is required
    #   Set libc_cv_forced_unwind=yes
    SUFFIX=$1
    mkdir -p $WORKDIR/build-glibc${SUFFIX}
    cd $WORKDIR/build-glibc${SUFFIX}

    test -f config.status ||
    libc_cv_forced_unwind=yes \
    libc_cv_ld_gnu_indirect_function=yes \
    libc_cv_ssp=no \
    $GLIBC_SRC/configure \
      --prefix=/usr \
      --host=$TARGET \
      --without-cvs \
      --disable-profile \
      --enable-multi-arch \
      --without-selinux \
      --with-tls \
      --with-headers=$SYSROOT/usr/include \
      --enable-kernel=2.6.20

    make install_root=$SYSROOT install-headers ${J}
}


#
# Create dummy gnu/stubs.h
#
function build_gnu_stubs () {
    touch $SYSROOT/usr/include/gnu/stubs.h
    # This is for ppc
    touch $SYSROOT/usr/include/gnu/stubs-32.h

    # Workaround for aarch64 lib64 issue
    mkdir -p $SYSROOT/usr/lib
}

#
# Build Target libgcc
#
function build_target_libgcc() {
    echo `date ` $FUNCNAME | tee -a $LOG
    cd $WORKDIR/build-gcc-bootstrap

    make all-target-libgcc ${J}
    make install-target-libgcc
}

#
# Build Glibc
#
function build_glibc() {
    echo `date ` $FUNCNAME | tee -a $LOG

    SUFFIX=$1
    cd $WORKDIR/build-glibc${SUFFIX}

    make ${J}
    make install_root=$SYSROOT install
}

#
# Build Final GCC
#
function build_gcc_final() {
    echo `date ` $FUNCNAME | tee -a $LOG

    mkdir -p $WORKDIR/build-gcc-final
    cd $WORKDIR/build-gcc-final

    test -f config.status ||
    $GCC_SRC/configure \
       --target=$TARGET \
       --prefix=$PREFIX \
       --disable-nls \
       --enable-shared \
       --enable-languages=${GCC_LANGUAGES} \
       --enable-__cxa_atexit \
       --enable-c99 \
       --enable-long-long \
       --disable-libssp \
       --disable-libgomp \
       --disable-decimal-float \
       --disable-libffi \
       --disable-libmudflap \
       --disable-libsanitizer \
       $GCC_CONFIG
       $WITH_HOST_TOOLS

    make all ${J}
    make install
    hash -r
}

#
# Build Newlib
#
function build_newlib() {
    echo `date ` $FUNCNAME | tee -a $LOG
    mkdir -p $WORKDIR/build-newlib
    cd $WORKDIR/build-newlib

    test -f config.status ||
    $NEWLIB_SRC/configure \
       --target=$TARGET \
       --prefix=$PREFIX \
       --disable-newlib-supplied-syscalls \
       CFLAGS_FOR_TARGET="-O2 -falign-functions=8"

    make ${J}
    make install
}

################################################################
## Build Main
################################################################

#
# Reset PATH
#

OLD_PATH="$PATH"
export PATH=$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/sysroot/bin

dump_settings ARCH TARGET TARGET_M32 LINUX_DEFAULT_CONFIG \
              GMP_SRC MPFR_SRC MPC_SRC CLOOG_SRC \
              BINUTILS_SRC GCC_SRC GLIBC_SRC LINUX_SRC

WITH_HOST_TOOLS=""
if [ x"$BUILD_HOST_TOOLS" = x"yes" ]; then
    WITH_HOST_TOOLS="
       --with-gmp=$HOST_TOOLS \
       --with-mpfr=$HOST_TOOLS \
       --with-mpc=$HOST_TOOLS \
       --with-cloog=$HOST_TOOLS"

    build_gmp
    build_mpfr
    build_mpc
    build_cloogisl
fi

case $TARGET in
    *-linux*)
        # Build Linux Toolchain

        GCC_CONFIG="$GCC_CONFIG --enable-threads=posix 
                                --with-headers 
                                --with-sysroot=$SYSROOT"

        require_settings ARCH TARGET LINUX_DEFAULT_CONFIG
        build_linux_headers
        build_binutils
        build_gcc_bootstrap
        build_glibc_headers
        build_gnu_stubs
        build_target_libgcc

	# If this is a multilib toolchain supporting m32,
	# build m32 glibc first.
        if $PREFIX/bin/$TARGET-gcc -print-multi-lib | grep m32 ; then
            CC="$TARGET-gcc -m32" libdir="/usr/lib" TARGET=${TARGET_M32} build_glibc_headers "-m32"
            CC="$TARGET-gcc -m32" libdir="/usr/lib" TARGET=${TARGET_M32} build_glibc "-m32"
        fi

        build_glibc
        build_gcc_final
        ;;
    *)
        # Build Newlib Toolchain

        GCC_CONFIG="$GCC_CONFIG --disable-threads 
                                --without-headers 
                                --with-newlib"

        require_settings TARGET
        build_binutils
        build_gcc_bootstrap
        build_target_libgcc
        build_newlib
        # If only C langauge is built, we don't need to build final gcc.
        if [ "$GCC_LANGUAGES" != "c" ]; then
            build_gcc_final
        fi
        ;;
esac

# End of building.  Running post testing.

echo `date ` Done | tee -a $LOG
