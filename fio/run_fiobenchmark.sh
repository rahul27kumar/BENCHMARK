#!/usr/bin/bash
TIME_INTERVAL=""
BLOCK_SIZE=""
NUMOFJOBS=""
CURRENTPATH=`pwd`
TIMESTAMP=`date +'%Y-%m-%d_%H:%M:%S'`
SAMPLE=""
TEMPLATE=""

validate_args() {

        if [[ -z $TIME_INTERVAL ]] || [[ -z $NUMOFJOBS ]] || [[ -z $BLOCK_SIZE ]] || [[ -z $TEMPLATE ]] || [[ -z $SAMPLE ]]; then
                show_usage
        fi

}

show_usage() {
        echo -e "\n \t  Usage : ./run_fiobenchmark.sh -t TIME_INTERVAL -bs BLOCK_SIZE -nj NUMOFJOBS -sm SAMPLE -tm TEMPLATE\n"
        echo -e "\t -t\t:\t Run time (Duration) \n"
        echo -e "\t -bs\t:\t Blocksize\n"
        echo -e "\t -nj\t:\t Number of jobs\n"
        echo -e "\t -sm\t:\t Sampling time \n"
        echo -e "\t -tm\t:\t Template for fio like seq_read_fio, seq_write_fio, randmix_80-20_fio, randmix_20-80_fio and rand_fio \n"
        echo -e "\tExample\t:\t ./run_fiobenchmark.sh -t 5 -bs 1M,4M,16M -nj 16,32,64 -sm 5 -tm seq_read_fio \n"
        exit 1
}

fio_benchmark() {
       
       for bs in ${BLOCK_SIZE//,/ }
       do
           for numjob in ${NUMOFJOBS//,/ }
           do 
               
               template_file=$CURRENTPATH/fio-template/$TEMPLATE
               workload_file=$CURRENTPATH/benchmark.log/$TEMPLATE\_bs_$bs\_numjobs_$numjob
               cp $template_file $workload_file
               sed -i "/\[global\]/a bs=$bs" $workload_file
               sed -i "/time_based/a runtime=$TIME_INTERVAL" $workload_file
               sed -i "/runtime/a numjobs=$numjob" $workload_file
               FIOLOG=benchmark.log/$TEMPLATE\_bs_$bs\_numjobs_$numjob\.log
               fio --status-interval=$SAMPLE $workload_file > $FIOLOG & 
               echo "Fio scripts is running..."
               PID=$!
               sleep 30
               system_monitoring $bs $FIOLOG fio
           done
       done

}

system_monitoring()
{
      echo "Client Server: System monitoring Started..." 
      systemctl start telegraf
      while [ true ]
      do
         if kill -0 $PID > /dev/null 2>&1;
         then
             ./monitor_performance.sh $1 $2 $3 
             sleep $SAMPLE
         else
             break
         fi
      done
      systemctl stop telegraf
      echo "Client Server: System monitoring Stopping..."
}





while [ ! -z $1 ]; do

        case $1 in
        -t)     shift
                TIME_INTERVAL="$1"
        ;;

        -bs)    shift
                BLOCK_SIZE="$1"
        ;;

        -nj)    shift
                NUMOFJOBS="$1"
        ;;

        -sm)    shift
                SAMPLE="$1"
        ;;

        -tm)    shift
                TEMPLATE="$1"
        ;;

        *)
                show_usage
                break
        esac
        shift
done

validate_args

if [ ! -d benchmark.log ]; then
      mkdir $CURRENTPATH/benchmark.log
      if [ ! `rpm -qa | grep telegraf` > /dev/null 2>&1 ]; then
          sh /root/BENCHMARK/setup_telegraf.sh
      fi
      fio_benchmark
else
      mv benchmark.log $CURRENTPATH/benchmark.bak_$TIMESTAMP
      mkdir $CURRENTPATH/benchmark.log
      fio_benchmark
fi
