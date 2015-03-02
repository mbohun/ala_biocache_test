#!/bin/bash

if [ -z "$1" ]; then
    echo "usage: $0 [log file]"
    exit 1;
fi

LOG_FILE=$1

# first delete all lines NOT beginning with a timestamp (this strips all the exceptions stack traces, details we do not need)
grep '^201[4-9]-[0-1][0-9]-[0-3][0-9].*\[[a-zA-Z0-9.]*\]' $LOG_FILE | sed -e 's/].*$/]/g' > tmp.log

for err in `sed -e 's/^.*\[/[/' tmp.log | sort | uniq`; do
    regexp='^201[4-9]-[0-1][0-9]-[0-3][0-9].*\\$err'

    eval grep $regexp tmp.log | sed -e 's/,[0-9][0-9][0-9].*$//g' > $err.log
    cat $err.log | uniq > $err.ulog

    rm -f $err.dat
    while read -r line
    do
	echo "$line,`grep "$line" $err.log | wc -l`" >> $err.dat
    done < "$err.ulog"
    
    rm -f $err.ulog $err.log
done
