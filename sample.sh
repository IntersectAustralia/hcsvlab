#!/bin/bash

PID=`pgrep python`

pidstat 1 10 -p $PID >> "$1_process.txt"
sar -P ALL 1 10 >> "$1_cpu.txt"
sar -n NFS 1 10 >> "$1_nfs.txt"

