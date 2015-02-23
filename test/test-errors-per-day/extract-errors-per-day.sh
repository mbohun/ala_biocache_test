#!/bin/bash

ERROR_REGEXP='proxy error'

# TODO: add proper input args processing, tmp files, etc

# for each log file if we have many, collect $ERROR_PATTER and accumulate the matches in some tmp file
grep -i 'proxy error' ./biocache-service.log | grep '^201[5-9]' | sed -e 's/ \[org.*$//g' > proxy_error-all.dat

# for each day extract the number of errors
for day in `cat proxy_error-all.dat | sed -e 's/ .*$//g' | sort | uniq`
do
    counter=`grep ${day} proxy_error-all.dat | wc -l`
    echo "${day} ${counter}"
done
