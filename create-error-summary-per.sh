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

    eval grep $regexp tmp.log > $err.log

    rm -f $err.ts
    while read -r line
    do
	date_string=`echo "$line" | sed -e 's/ \[.*$//g'`
	timestamp=`date -d "$date_string" +"%s"`
	echo "$timestamp" >> $err.ts
    done < "$err.log"
    rm -f $err.log

    rm -f $err.dat
    for ts in `cat $err.ts | uniq`; do
	count=`grep "$ts" $err.ts |wc -l`
	echo "$ts $count" >> $err.dat
    done
    rm -f $err.ts

done

rm -f tmp.log
