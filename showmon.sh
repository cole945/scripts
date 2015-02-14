#!/bin/bash


function showmon ()
{
  STAMP=$1
  RES=$2
  TH=$3

  ps -eo $RES,user --sort=user | \
  	awk 'NR>2{if (name == $2) {sum+=$1} else {print name,sum; name=$2; sum=$1}} END{ print name,sum}' | \
  	sort -n -k2,2 -r | \
  while read LINE; do
    VAL=$(echo $LINE | cut -f2 -d' ') # | cut -f1 -d.)

    test x"$VAL" == x && VAL=0

    # Skip if VAL usage is relative small
    test $(echo "$VAL < $TH" | bc) == "1" && break
  
    # Get user display name
    USER=$(echo $LINE | cut -f1 -d' ')
    NAME=$(getent passwd $USER | cut -d':' -f5 | cut -d' ' -f1)
    test -z "$NAME" && NAME=$USER
    test x"$NAME" == x",,," && NAME=$USER

    echo "${STAMP},${RES},${NAME},${VAL}"
  done
}

function showio ()
{
  STAMP=$1
  DEV=$2
  # Display 'R' reports at 'S' second(s)
  S=$3
  R=$4

  VAL=$(iostat -m ${S} ${R} /dev/$DEV | grep $DEV | awk 'NR==2 {print $3 "," $4 }')
  echo "${STAMP},${DEV},${VAL}"
}

function showfree ()
{
  STAMP=$1

  # VAL=$(free -o | grep Mem | tr -s ' :' ',')
  echo -n "${STAMP},free,"

  free -o | grep ":" | tr -s ' :' ',' | while read LINE; do
    echo -n "$LINE,"
  done
  echo ""
}


while true; do
  STAMP=$(date +%Y%m%d%H%M%S)
  showmon "$STAMP" pcpu 2
  showmon "$STAMP" rss 2

  showfree "$STAMP"

  showio "$STAMP" sdb 1 2
  showio "$STAMP" sda 1 2

  # showio will sleep 3 + 3 seconds.
  sleep 8
done
