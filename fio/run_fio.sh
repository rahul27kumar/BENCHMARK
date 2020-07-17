#! /bin/bash
SERVER=$1
DURATION=$2
IOSIZE=$3
NUMJOBS=$4
SAMPLE=$5
TEMPLATE=$6


ssh root@$SERVER "cd ~/BENCHMARK/fio; ./run_fiobenchmark.sh -t $DURATION -bs $IOSIZE -nj $NUMJOBS -sm $SAMPLE -tm $TEMPLATE" &
PID1=$!
ssh root@$SERVER "ssh srvnode-2 'cd ~/BENCHMARK/fio; ./run_fiobenchmark.sh -t $DURATION -bs $IOSIZE -nj $NUMJOBS -sm $SAMPLE -tm $TEMPLATE'" &
PID2=$!
sleep 20
while [ true ]
do
    if  kill -0 $PID1 > /dev/null 2>&1 ;
    then
        echo "Data is collecting..."
        sleep $SAMPLE
    else
        break
    fi
    if  kill -0 $PID2 > /dev/null 2>&1 ;
    then
        echo "Data is collecting..."
        sleep $SAMPLE
    else
        echo "Fio scripts is completed sucessfully"
        break
    fi
done

