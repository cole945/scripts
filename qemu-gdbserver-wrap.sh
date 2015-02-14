#!/bin/bash


QEMU=$(basename $0)
QEMU=${QEMU%%-*}

while (($#)); do
  case $1 in
  --once)
      IGNORE=IGNORE
      ;;
  :*)
      GDB="-g ${1##*:}"
      ;;
  *)
      break
      ;;
  esac
  shift
done

if [ x"${GDB}" != x ]; then
  echo "Listening on $PORT"
fi


case ${QEMU} in
  ppc64le)
    SYSROOT="-L $HOME/build/build-gcc-powerpc64le-linux-gnu/sysroot-powerpc64le-linux-gnu/powerpc64le-linux-gnu/libc"
    SYSROOT="-L /usr/powerpc64le-linux-gnu"
    SYSROOT="-L $HOME/Downloads/at8.0-ppc64le/opt/at8.0/ppc64le"
    ;;
  ppc64)
    SYSROOT="-L $HOME/Downloads/at8.0-ppc64/opt/at8.0/ppc"
    ;;
  ppc)
    SYSROOT="-L $HOME/Downloads/at8.0-ppc64/opt/at8.0/ppc"
    ;;
esac

qemu-${QEMU} ${SYSROOT} ${GDB}  "$@"
