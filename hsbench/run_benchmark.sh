#! /bin/bash
BENCHMARK_PATH=/root/go/bin
CURRENTPATH=`pwd`
ACCESS_KEY=`cat /root/.aws/credentials | grep -A 3 default | grep aws_access_key_id | cut -d " " -f3`		
SECRET_KEY=`cat /root/.aws/credentials | grep -A 3 default | grep secret_access_key | cut -d " " -f3` 	
BENCHMARKLOG=/root/BENCHMARK/hsbench/benchmark.log
NO_OF_BUCKET=""  				
TEST_DURATION=600   				
BUCKET_PREFIX=Seagate  		
MAX_ATTEMPT=1				
NO_OF_THREADS=""			
NO_OF_OBJECTS=""			
REGION=US				
ENDPOINTS=https://s3.seagate.com		
COUNT=0
SIZE_OF_OBJECTS=""
JSON_FILENAME=				
OUTPUT_FILE=
TIMESTAMP=`date +'%Y-%m-%d_%H:%M:%S'`
IFS=”,”
PID=
SAMPLE=

validate_args() {

        if [[ -z $NO_OF_BUCKET ]] ||  [[ -z $SIZE_OF_OBJECTS ]] || [[ -z $NO_OF_OBJECTS ]] || [[ -z $NO_OF_THREADS ]] || [[ -z $SAMPLE ]];
        then
                show_usage
        fi

}

show_usage() {
        echo -e "\n \t  Usage : ./run_benchmark.sh -b \"NO_OF_BUCKET\"  -o \"NO_OF_OBJECTS\"  -s \"SIZE_OF_OBJECT\" -t \"NO_OF_THREADS\" [ -d TEST_DURATION ] -sm SAMPLE\n"
        echo -e "\t -b\t:\t number of buckets \n"
        echo -e "\t -o\t:\t number of objects [optional] default is '4096'\n"
        echo -e "\t -s\t:\t size of the objects K|M\n"
        echo -e "\t -t\t:\t number of the Threads\n"
        echo -e "\t -d\t:\t TEST_DURATION [optional] default is '600'\n"
        echo -e "\t -sm\t:\t Sampling time for system monitoring in seconds\n"
        echo -e "\tExample\t:\t ./run_benchmark.sh -b \"8,16,32,64\" -o \"1024,2048\" -s \"1M,4M,16M,32M\" -t \"32,48,64,96,128\" -d 600 -sm 5\n"
        exit 1
}

hotsause_benchmark()
{
    while [ $MAX_ATTEMPT -gt $COUNT ]
    do
               
        MKDIR=runid_$TIMESTAMP
        mkdir -p $BENCHMARKLOG/$MKDIR
        SAMPLES=($NO_OF_OBJECTS)
        THREAD=($NO_OF_THREADS)
        OBJ_SIZE=($SIZE_OF_OBJECTS)
#       BUCKET=($NO_OF_BUCKET)
        for index in ${!THREAD[@]};
        do
           for nc in ${!SAMPLES[@]};
           do
               for size in ${!OBJ_SIZE[@]}
               do
                 echo "Thread: ${THREAD[$index]} \t SAMPLE: ${SAMPLES[$nc]} \t OBJECT_SIZE: ${OBJ_SIZE[$size]}"        
                 JSON_FILENAME=NT_${THREAD[$index]}\_NB_${SAMPLES[$nc]}\_object_size_${OBJ_SIZE[$size]}\.json

                 echo "$BENCHMARK_PATH/hsbench -a $ACCESS_KEY -s $SECRET_KEY -u $ENDPOINTS -z ${OBJ_SIZE[$size]} -d $TEST_DURATION -t ${THREAD[$index]} -b $NO_OF_BUCKET -n ${SAMPLES[$nc]} -r $REGION -j $JSON_FILENAME"

                $BENCHMARK_PATH/hsbench -a $ACCESS_KEY -s $SECRET_KEY -u $ENDPOINTS -z ${OBJ_SIZE[$size]} -d $TEST_DURATION -t ${THREAD[$index]} -b $NO_OF_BUCKET -n ${SAMPLES[$nc]} -r $REGION -j $JSON_FILENAME

               done 
           done
        done
        mv $CURRENTPATH/*.json $CURRENTPATH/benchmark.log/$MKDIR/
        COUNT=$(($COUNT + 1))
        #sleep 30
       # python3 /root/perf_testing/table_formatter.py $BENCHMARKLOG/$MKDIR/    #> /root/perf_testing/table.log/$MKDIR\.table
    done
} 

system_monitoring()
{
      systemctl start telegraf
      while [ true ]
      do
         if kill -0 $PID > /dev/null 2>&1;
         then
             ./monitor_performance.sh $SIZE_OF_OBJECTS $CURRENTPATH/benchmark.log/output.log hsbench
             sleep $SAMPLE
         else
             break
         fi
      done
      systemctl stop telegraf
}

while [ ! -z $1 ]; do

        case $1 in
        -b)    shift
                NO_OF_BUCKET="$1"
        ;;

        -o)    shift
                NO_OF_OBJECTS="$1"
        ;;

        -s)    shift
                SIZE_OF_OBJECTS="$1"
        ;;

        -t)    shift
                NO_OF_THREADS="$1"
        ;;

	-d)     shift
                TEST_DURATION="$1"
        ;;
        -sm)    shift
                SAMPLE="$1"
        ;;

        *)
                show_usage
                break
        esac
        shift
done

validate_args

if [ ! -d $BENCHMARKLOG ]; then
      mkdir $BENCHMARKLOG
      if [ ! `rpm -qa | grep telegraf` > /dev/null 2>&1 ]; then
           sh /root/BENCHMARK/setup_telegraf.sh
      fi
      hotsause_benchmark 2>&1 | tee benchmark.log/output.log &
      PID=$!
      system_monitoring
      unset IFS
else
      mv $BENCHMARKLOG /root/BENCHMARK/hsbench/benchmark.bak_$TIMESTAMP
      mkdir $BENCHMARKLOG
      hotsause_benchmark 2>&1 | tee benchmark.log/output.log &
      PID=$!
      system_monitoring
      unset IFS
fi
