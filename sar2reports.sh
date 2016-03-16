#!/bin/bash
# sar2reports.sh
# purpose: convert sar data to format acceptable by report server
# if used without parameters this script will collect sar files from local machine, merge then in one file, convert to csv with ";" serparation, then convert in format readable by reports server
# if used with filepath to sar text file as a parameter it will convert the given file to csv readable by reports server

HOSTNAME=`hostname`
SA_FILES="/var/log/sa/sa??"
DATE=`date +"%B"`
SAR_MERGED_FILE="sarmonthly_${HOSTNAME}_${DATE}.txt"
DIR_FOR_FILES="/tmp"
SAR_URL="http://downloads.sourceforge.net/project/ksar/ksar/5.0.6/kSar-5.0.6.zip?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fksar%2F"

get_ksar()
{
echo "Downloading kSar"
wget --quiet --output-document=ksar.zip $SAR_URL
if [ $? != 0 ]; then
  echo "download failed"
  echo -e "please verify that URL $SAR_URL is still valid"
  exit 1
else
  echo -e "download completed\n"
fi
}

unzip_ksar()
{
local ksar_zip="ksar.zip"
echo "Unzipping kSar"
unzip -o $ksar_zip >/dev/null 2>&1
if [ $? != 0 ]; then
  echo "unzip of $ksar_zip failed"
  exit 1
else
  echo -e "unzip of $ksar_zip completed\n"
fi
#clean up the zip file
echo -e "removing $ksar_zip"
rm -f $ksar_zip
echo -e "$ksar_zip removed\n"
}

check_java()
{
echo "checking if java is installed"
java -version >/dev/null 2>&1
if [ $? == 127 ]; then
  echo "java is not instaleld! script kSar needs java to run, please install java and run the script again"
  exit 127
else
  echo -e "java found, script continues\n"
fi
}

merge_sar()
{
echo "merging sar files"
#remove old merged sar file if exists
[[ -f "$DIR_FOR_FILES/$SAR_MERGED_FILE" ]] && rm -f "$DIR_FOR_FILES/$SAR_MERGED_FILE"

#loop through existing sa files, merge all files into one
for file in $SA_FILES; do
  LC_ALL=C sar -A -f $file >> $DIR_FOR_FILES/$SAR_MERGED_FILE
done
echo -e "sar files were merged into $DIR_FOR_FILES/$SAR_MERGED_FILE\n"
}

sar2csv()
{
if [ -z "$1" ]; then
  local input=$DIR_FOR_FILES/$SAR_MERGED_FILE
else
  local input=$1
fi

OUTPUT=${input%%.*}.csv

echo "converting merged sar $input to $OUTPUT"
java -jar kSar.jar -input $input -outputCSV $OUTPUT >/dev/null 2>&1
if [ $? != 0 ]; then
  echo "file conversion failed"
  exit 1
else
  echo -e "file converted to ; separated csv\n"
fi
}

csv2report()
{
local output=${1%%.*}_reports.csv
echo -e "converting ; separated csv file $1 to reports server compatible format"
#create header
awk 'FNR<2 {print}' $1 | sed 's/.$/"/g' | awk '$1=$1' FS=";" OFS="\",\"" | sed 's/^/"/' | awk '$1="\"(PDH-CSV 4.0) (Central Daylight Time)(300)\",\""' | sed 's/,"/,"\\\\LINUX-01\\sar\\/g' > $output
#process data lines
awk 'FNR>2 {print}' $1 | sed 's/.$/"/g' | awk '$1=$1' FS=";" OFS="\",\"" | sed 's/^/"/' | awk -F, 'OFS=","{date=("date --date="$1" +\"%m/%d/%Y %T.%3N\" "); date | getline $1; close(date)}1' | awk -F, '{sub($1, "\"&\""); print}' >> $output

if [ $? != 0 ]; then
  echo "file conversion failed"
  exit 1
else
  echo -e "file $1 was converted to reports server compatible format $output\n"
fi
}

###main begins here###
#check if java is installed
check_java

#check if we have kSar, if not download it
DIRECTORY=`ls -d kSar-* >/dev/null 2>&1`
if [ ! -d "$DIRECTORY" ]; then
  get_ksar
  unzip_ksar
  DIRECTORY=`ls -d kSar-*`
else
  echo -e "kSar is presnet ... going on\n"
fi

#if input file is provided get its absolute path
if [[ $# -eq 1 ]] ; then
  input_txt_file=`readlink -f $1`
fi

echo -e "changing working directory to $DIRECTORY \n"
cd $DIRECTORY

#merge sar files, if no input file is given
if [[ $# -eq 0 ]] ; then
  merge_sar
fi

#use kSar to convert merged sar or provided sar file to csv
sar2csv $input_txt_file

#go out from working dir
echo -e "leaving working directory $DIRECTORY \n"
cd ..

#convert csv to reports server compatible format
csv2report $OUTPUT
