#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: $0 [log file] [error regexp]"
    exit 1;
fi

LOG_FILE=$1
ERROR_REGEXP=$2

temp=`basename $0`
ERROR_TIMESTAMPS=`mktemp /tmp/${temp}.XXXXXX` || exit 1

# TODO: add proper input args processing, tmp files, etc

# for each log file if we have many, collect $ERROR_PATTER and accumulate the matches in some tmp file
eval grep $ERROR_REGEXP $LOG_FILE | grep '^201[5-9]' | sed -e 's/ \[org.*$//g' > $ERROR_TIMESTAMPS

# for each day extract the number of errors
for day in `cat $ERROR_TIMESTAMPS | sed -e 's/ .*$//g' | sort | uniq`; do
    counter=`grep ${day} $ERROR_TIMESTAMPS | wc -l`
    echo "${day} ${counter}"
done
