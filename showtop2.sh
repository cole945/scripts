#!/bin/bash

RES=$1
if [ x"$RES" == x"" ]; then
  RES=pcpu
fi

FIRST=
SEP=

ps -eo $RES,user --sort=user | \
	awk '{if (name == $2) {sum+=$1} else {print name,sum; name=$2; sum=$1}} END{ print name,sum}' | \
	sort -n -k2,2 -r | \
	head -n 10 | \
while read LINE; do
  VAL=$(echo $LINE | cut -f2 -d' ' | cut -f1 -d.)

  test x"$VAL" == x && VAL=0
  if [ -z "$FIRST" ]; then
    FIRST=$VAL
  else
    SEP=" | "
  fi

  # Skip if VAL usage is relative small
  test $(($FIRST * 6 / 10)) -gt $VAL && break

  # Get user display name
  USER=$(echo $LINE | cut -f1 -d' ')
  NAME=$(getent passwd $USER | cut -d':' -f5 | cut -d' ' -f1)
  test -z "$NAME" && NAME=$USER
  test x"$NAME" == x",,," && NAME=$USER

  case $RES in
  p*)
    test $VAL -lt 80 && break
    VAL="$VAL%"
    ;;
  rs*)
    VAL="$(($VAL / 1024))MB"
    ;;
  esac

  echo -n "${SEP}${NAME}:${VAL}"
done
echo ""

