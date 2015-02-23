####extract the number/count of some error per day

```BASH
mbohun@linux:~> ./extract-errors-per-day.sh
usage: ./extract-errors-per-day.sh [log file] [error regexp]
```
```BASH
mbohun@linux:~> ./extract-errors-per-day.sh ./biocache-service.log '"Proxy Error"'
2015-02-19 25
2015-02-20 65
2015-02-21 38
2015-02-22 53
2015-02-23 17
```
```BASH
mbohun@linux:~> ./extract-errors-per-day.sh ./biocache-service.log '"Proxy Error"' | gnuplot errors-per-day.gnuplot
```

*example:*
[./extract-errors-per-day.sh](extract-errors-per-day.sh) [./biocache-service.log](biocache-service.log) '"Proxy Error"' | [gnuplot](http://www.gnuplot.info) [errors-per-day.gnuplot](errors-per-day.gnuplot)  

*example [output](errors-per-day-histogram.png):*
![Alt text](https://raw.githubusercontent.com/mbohun/ala_biocache_test/master/test/test-errors-per-day/errors-per-day-histogram.png "example ouptut")
