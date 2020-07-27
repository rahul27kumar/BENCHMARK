#!/bin/bash
source /root/BENCHMARK/influxdbDetails.conf
INFLUXDB=`cat /etc/telegraf/telegraf.conf | grep -A 3 outputs.influxdb | grep urls | cut -d "=" -f2 | tr -d '"[]' | tr -d ' '`
URL="$INFLUXDB/write?db=$benchmarkdb"
host=`hostname`
OBJECT_SIZE=$(echo "$1" | tr -d 'Mb')
echo "OBJECT_SIZE : $OBJECT_SIZE"
BENCHMARK=$3
line=$(tail -n 1 $2)
OPS=$(echo "$line" | grep -o '\"opType\":\"[a-z]*\"' | cut -d ':' -f2 | tr -d "\"" )
ops=($OPS)
IOPS=$(echo "$line" | grep -o '\"throughput\":[0-9]*.[0-9]*' | cut -d ':' -f2 | tr -d " ")
iops=($IOPS)
LAT=$(echo "$line" | grep -o '\"avgResTime\":[0-9]*.[0-9]*' | cut -d ":" -f2 | tr -d " ")
lat=($LAT)

for index in ${!ops[@]};
do
   if [[ "${ops[$index]}" = "read" ]] || [[ "${ops[$index]}" = "write" ]]
   then
        op=${ops[$index]}
        iops1=${iops[$index]}
        Th=`expr "${iops[$index]} * $OBJECT_SIZE" | bc -l`
        value=`printf "%.2f" $(echo $Th | bc -l)`
        Lat=${lat[$index]}
        ops1=${op^}
        update_value_1="Latency,host=`hostname`,operation=$ops1,Obj_size=$1,Benchmark_Type=$BENCHMARK,region=us-west value=$Lat"
        update_value_2="Throughput,host=`hostname`,operation=$ops1,Obj_size=$1,Benchmark_Type=$BENCHMARK,region=us-west value=$value"
        update_value_3="IOPS,host=`hostname`,operation=$ops1,Obj_size=$1,Benchmark_Type=$BENCHMARK,region=us-west value=$iops1"
        echo "update_value_1 : $update_value_1"
        echo "update_value_2 : $update_value_2"
        echo "update_value_3 : $update_value_3"
        curl -i -XPOST "$URL" --data-binary "$update_value_1"  #> /dev/null 2>&1;
        curl -i -XPOST "$URL" --data-binary "$update_value_2"  #> /dev/null 2>&1;
        curl -i -XPOST "$URL" --data-binary "$update_value_3"  #> /dev/null 2>&1;
        echo "$ops1 Data captured for latency, throughput and IOPS..."
   else 
        break
   fi

done

