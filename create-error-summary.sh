#!/bin/bash

if [ -z "$1" ]; then
    echo "usage: $0 [log file]"
    exit 1;
fi

LOG_FILE=$1

for err in `grep '^201[4-9]-[0-1][0-9]-[0-3][0-9].*\[[a-zA-Z0-9.]*\]' $LOG_FILE | sed -e 's/].*$/]/g' | sed -e 's/^.*\[/[/' | sort | uniq`; do
    regexp='^201[4-9]-[0-1][0-9]-[0-3][0-9].*\\$err'
    err_count=`eval grep $regexp $LOG_FILE | wc -l`
    printf "%s%s\n" "$err" "$err_count"
done
