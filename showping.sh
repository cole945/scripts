#!/bin/bash

HOST=$1
if [ -z "$1" ]; then
  HOST=172.22.81.23
fi

if ! T=$(ping $HOST -c 1 -W 2 | grep -o "time=.*" 2>/dev/null); then
  echo "*TIMEOUT*"
fi

T=$(echo $T | cut -f2 -d= | cut -f1 -d' ')
echo $T
