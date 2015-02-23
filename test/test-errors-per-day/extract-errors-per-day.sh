#!/bin/bash

temp=`basename $0`
ERROR_TIMESTAMPS=`mktemp /tmp/${temp}.XXXXXX` || exit 1

ERROR_REGEXP='proxy error'

# TODO: add proper input args processing, tmp files, etc

# for each log file if we have many, collect $ERROR_PATTER and accumulate the matches in some tmp file
grep -i 'proxy error' ./biocache-service.log | grep '^201[5-9]' | sed -e 's/ \[org.*$//g' > $ERROR_TIMESTAMPS

# for each day extract the number of errors
for day in `cat $ERROR_TIMESTAMPS | sed -e 's/ .*$//g' | sort | uniq`
do
    counter=`grep ${day} $ERROR_TIMESTAMPS | wc -l`
    echo "${day} ${counter}"
done
