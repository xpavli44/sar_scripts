#!/bin/bash
#this scripts loops through all available sa files and merges them into one file which is readable by kSar
HOSTNAME=`hostname`
SA_FILES="/var/log/sa/sa??"
DATE=`date +"%B"`
SAR_MERGED_FILE="sarmonthly_${HOSTNAME}_${DATE}.txt"

#remove old merged sar file if exists
[[ -f "$SAR_MERGED_FILE" ]] && rm -f "$SAR_MERGED_FILE"

#loop through existing sa files, merge all files into one
for file in $SA_FILES; do
LC_ALL=C sar -A -f $file >> $SAR_MERGED_FILE
done

echo -e "sar files were merged into ${SAR_MERGED_FILE}"

