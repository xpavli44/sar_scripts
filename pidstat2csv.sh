#!/bin/bash
# pidstat2csv.sh: shell program to convert output from pidstat to *.csv usable for reports server
# pidstat command to be used: nohup pidstat -p `pidof YOUR_PROCESS_HERE` -u -d -r -h 10 720 >> /tmp/Perf_DPA_MySQL_DefaultPS.txt
# pidstat command to be used: nohup pidstat -p `pidof YOUR_PROCESS_HERE` -u -d -r -h 10 60 >> /tmp/Perf_DPA_Oracle_`hostname`.txt
# filename=/tmp/Perf_DPA_mysql-S12_`hostname`_`date +"%d_%m"`.txt; echo "" > $filename; pidstat -p $(pidof mysqld) -u -d -r -h 60 86400 >> $filename
# filename=/tmp/Perf_DPA_oracle-S12_`hostname`_`date +"%d_%m"`.txt; echo "" > $filename; pidstat -p $(pidof ora_pmon_orcl) -p $(pidof ora_dbw0_orcl) -p $(pidof ora_lgwr_orcl) -p $(pidof ora_ckpt_orcl) -p $(pidof ora_smon_orcl) -p $(pidof ora_reco_orcl) -u -d -r -h 60 86400 >> $filename


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
        #get process name
        process=`awk 'FNR==4 {print $17}' $input_file`
        #create header in output csv
        echo -e ﻿"\"(PDH-CSV 4.0)\ (Central Daylight Time)(300)\",\"\\\\\\LINUX-01\\Process(*)\\$process\\UID\",\"\\\\\\LINUX-01\\Process(*)\\$process\\PID\",\"\\\\\\LINUX-01\\Process(*)\\$process\\%usr\",\"\\\\\\LINUX-01\\Process(*)\\$process\\%system\",\"\\\\\\LINUX-01\\Process(*)\\$process\\%guest\",\"\\\\\\LINUX-01\\Process(*)\\$process\\%CPU\",\"\\\\\\LINUX-01\\Process(*)\\$process\\CPU  minflt/s\",\"\\\\\\LINUX-01\\Process(*)\\$process\\majflt/s\",\"\\\\\\LINUX-01\\Process(*)\\$process\\VSZ\",\"\\\\\\LINUX-01\\Process(*)\\$process\\RSS\",\"\\\\\\LINUX-01\\Process(*)\\$process\\%MEM\",\"\\\\\\LINUX-01\\Process(*)\\$process\\kB_rd/s\",\"\\\\\\LINUX-01\\Process(*)\\$process\\kB_wr/s\",\"\\\\\\LINUX-01\\Process(*)\\$process\\kB_ccwr/s\",\"\\\\\\LINUX-01\\Process(*)\\$process\\iodelay\",\"\\\\\\LINUX-01\\Process(*)\\$process\\Command\"" > $output_file 
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
