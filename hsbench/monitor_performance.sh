#!/bin/bash
INFLUXDB=`cat /etc/telegraf/telegraf.conf | grep -A 3 outputs.influxdb | grep urls | cut -d "=" -f2 | tr -d '"[]' | tr -d ' '`
URL="$INFLUXDB/write?db=testdb"
host=`hostname`
OBJECT_SIZE=$1
BENCHMARK=$3
line=$(tail -n 1 $2)
update_value_1=
update_value_2=
update_value_3=

if [[ "$line" != *"Running"*  ]]
then
    if [[ "$line" = *"PUT"* ]]  || [[ "$line" = *"GET"* ]]
    then
        ops=$(echo "$line" | cut -f 10 -d ' ' | tr -d ',' | tr -d ' ')
        echo "Operation Types: $ops"
        Th=$(echo "$line" | cut -f 14 -d ' ' | tr -d ',' | tr -d ' ')
        IOPS=$(echo "$line" | cut -f 16 -d ' ' | tr -d ',' | tr -d ' ')
        Lat=$(echo "$line" | cut -f 22 -d ' ' | tr -d ',' | tr -d ' ')
        size=$OBJECT_SIZE\b
        if [[ "$ops" = "PUT" ]]
        then
            update_value_1="Latency,host=`hostname`,operation=Write,Obj_size=$size,Benchmark_Type=$BENCHMARK,region=us-west value=$Lat"
            update_value_2="Throughput,host=`hostname`,operation=Write,Obj_size=$size,Benchmark_Type=$BENCHMARK,region=us-west value=$Th"
            update_value_3="IOPS,host=`hostname`,operation=Write,Obj_size=$size,Benchmark_Type=$BENCHMARK,region=us-west value=$IOPS"
        else
            update_value_1="Latency,host=`hostname`,operation=Read,Obj_size=$size,Benchmark_Type=$BENCHMARK,region=us-west value=$Lat"
            update_value_2="Throughput,host=`hostname`,operation=Read,Obj_size=$size,Benchmark_Type=$BENCHMARK,region=us-west value=$Th"
            update_value_3="IOPS,host=`hostname`,operation=Read,Obj_size=$size,Benchmark_Type=$BENCHMARK,region=us-west value=$IOPS"
        fi 
        curl -i -XPOST "$URL" --data-binary "$update_value_1"
        curl -i -XPOST "$URL" --data-binary "$update_value_2"
        curl -i -XPOST "$URL" --data-binary "$update_value_3"
     
    fi
else 
    exit
fi
