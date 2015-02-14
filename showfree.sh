#!/bin/sh

free -ho | grep Mem | awk '{print $4}'
