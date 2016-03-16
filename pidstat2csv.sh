#!/bin/bash
# pidstat2csv.sh: shell program to convert output from pidstat to *.csv usable for reports server
# pidstat command to be used: nohup pidstat -p `pidof YOUR_PROCESS_HERE` -u -d -r -h 10 720 >> /tmp/Perf_DPA_MySQL_DefaultPS.txt
# pidstat command to be used: nohup pidstat -p `pidof YOUR_PROCESS_HERE` -u -d -r -h 10 60 >> /tmp/Perf_DPA_Oracle_`hostname`.txt
input_file=$1
output_file=${input_file%%.*}.csv
tmp_file=${input_file%%.*}.tmp

# define usage function
usage(){
        echo "Usage: $0 filename"
        exit 1
}

# define is_file_exits function 
# $f -> store argument passed to the script
is_file_exits(){
        local f="$1"
        [[ -f "$f" ]] && return 0 || return 1
}
# invoke  usage
# call usage() function if filename not supplied
[[ $# -eq 0 ]] && usage

# Invoke is_file_exits
if ( is_file_exits "$1" )
then
        #create header in output csv
        echo '﻿"(PDH-CSV 4.0) (Central Daylight Time)(300)","\\LINUX-01\Process\UID","\\LINUX-01\Process\PID","\\LINUX-01\Process\%usr","\\LINUX-01\Process\%system","\\LINUX-01\Process\%guest","\\LINUX-01\Process\%CPU","\\LINUX-01\Process\CPU  minflt/s","\\LINUX-01\Process\majflt/s","\\LINUX-01\Process\VSZ","\\LINUX-01\Process\RSS","\\LINUX-01\Process\%MEM","\\LINUX-01\Process\kB_rd/s","\\LINUX-01\Process\kB_wr/s","\\LINUX-01\Process\kB_ccwr/s","\\LINUX-01\Process\iodelay","\\LINUX-01\Process\Command"' > $output_file
        #remove all lines that do not begin with space followed by number
        awk '/^ [0-9]/' $input_file > $tmp_file
        #replace first space with quote "
        sed -i 's/^ */"/' $tmp_file
        #replace multiple spaces with ","
        sed -i 's/ \+/","/g' $tmp_file
        #add quote at the end
        sed -i 's/$/"/g' $tmp_file
        #convert time stamp
        awk -F, '{gsub(/"/,"",$1 ); $1 = "\""strftime("%D %T.000",$1)"\""; print; }' $tmp_file > tmp; mv tmp $tmp_file
        #replace spaces with ","
        sed -i 's/" /",/g' $tmp_file
        #append processed text to output file
        cat $tmp_file >> $output_file
        #remove temp file
        rm $tmp_file
else
 echo "File not found"
fi
