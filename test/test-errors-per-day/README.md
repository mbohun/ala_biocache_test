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
optional step, for example plot/visualize the result with gnuplot, D3.js, etc.
```BASH
mbohun@linux:~> ./extract-errors-per-day.sh ./biocache-service.log '"Proxy Error"' \
                  | gnuplot errors-per-day.gnuplot \
                  > errors-per-day-histogram.png
```

*example:*  
[./extract-errors-per-day.sh](extract-errors-per-day.sh) [./biocache-service.log](biocache-service.log) '"Proxy Error"' `\`  
`|` [gnuplot](http://www.gnuplot.info) [errors-per-day.gnuplot](errors-per-day.gnuplot) `\`  
`>` [errors-per-day-histogram.png](errors-per-day-histogram.png)

*example [output](errors-per-day-histogram.png):*
![Alt text](https://raw.githubusercontent.com/mbohun/ala_biocache_test/master/test/test-errors-per-day/errors-per-day-histogram.png "example ouptut")

```BASH
mbohun@linux:~> ./extract-errors-per-day.sh ./biocache-service.log \
                '"IOException occured when talking to server at: http://ala-rufus.it.csiro.au/solr"' \
                | gnuplot errors-per-day.gnuplot \
				> IOException-occured-when-talking-to-server.png
```
*example [output](IOException-occured-when-talking-to-server.png):*
![Alt text](https://raw.githubusercontent.com/mbohun/ala_biocache_test/master/test/test-errors-per-day/IOException-occured-when-talking-to-server.png "example ouptut")
