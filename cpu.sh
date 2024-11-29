#!/bin/bash
CPU_LOG=/home/chanyas/Documents/cronweather/cpu.log

echo "CPU Usage:"
#top -bn1 | grep "Cpu(s)" | awk '{print "User: "$2"% Sys: "$4"% Idle: "$8"%"}' (this is a grep soution)
#This is an awk and sed solution:
log_cpu_and_disk() {
  echo "$(date): CPU Usage:" >> $CPU_LOG
  top -bn1 | sed -n '/Cpu(s)/p' | awk -F ',' '{print "User: " $1+0 "% Sys: " $2+0 "% Idle: " $4+0 "%"}'
  echo "Disk Usage:" >> $CPU_LOG
  df -h | grep '^/dev/' >> $CPU_LOG
  echo "------------------------" >> $CPU_LOG
}
