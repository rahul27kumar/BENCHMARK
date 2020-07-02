#!/usr/bin/bash
if [ ! `rpm -qa | grep telegraf` > /dev/null 2>&1 ]; then 
  cd /root/BENCHMARK
  sh setup_telegraf.sh 
else 
   echo "Telegraf is already installed"
fi
