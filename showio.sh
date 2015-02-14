#!/bin/bash

DEV=$1
if [ -z "$DEV" ]; then
  DEV=sdb
fi

iostat -m 1 2 /dev/$DEV | grep $DEV | awk 'NR==2 {print $3 "MB|" $4 "MB"}'
