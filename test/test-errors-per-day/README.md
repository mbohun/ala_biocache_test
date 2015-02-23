####example: extract the number/count of some error per day (for example: "Proxy Error")

```BASH
#!/bin/bash

# extract $ERROR_PATTER and accumulate the matches in some tmp file
grep -i 'proxy error' ./biocache-service.log | grep '^201[5-9]' | sed -e 's/ \[org.*$//g' > proxy_error-all.dat

# for each day extract the number of errors
for day in `cat proxy_error-all.dat | sed -e 's/ .*$//g' | sort | uniq`
do
    counter=`grep ${day} proxy_error-all.dat | wc -l`
    echo "${day} ${counter}"
done
```

./[extract-errors-per-day.sh](extract-errors-per-day.sh) > [errors-per-day-example.dat](errors-per-day-example.dat)  
[gnuplot](http://www.gnuplot.info) [errors-per-day.gnuplot](errors-per-day.gnuplot)

example output ([errors-per-day-histogram.png](errors-per-day-histogram.png) ):
![Alt text](https://raw.githubusercontent.com/mbohun/ala_biocache_test/master/test/test-errors-per-day/errors-per-day-histogram.png "example ouptut")
