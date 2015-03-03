set datafile separator ","
set terminal pngcairo font "arial,8" size 4096,1200

#set title "ALA biocache-service.log"
set xlabel "date"
set ylabel "errors per sec"

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set xrange["2015-02-19 00:00:00":"2015-03-04 00:00:00"]
set xtics "1980-01-01 00:00:00",86400

set multiplot layout 9,1

set yrange [0:*]
set ytics  5
set key left top
set grid
plot "[org.ala.biocache.dao.SearchDAOImpl].dat"         using 1:2 with impulses title 'org.ala.biocache.dao.SearchDAOImpl'

set yrange [0:*]
set ytics  1
set key left top
set grid
plot "[org.ala.biocache.service.AuthService].dat"       using 1:2 with impulses title 'org.ala.biocache.service.AuthService'

set yrange [0:*]
set ytics  1
set key left top
set grid
plot "[org.ala.biocache.web.WMSController].dat"         using 1:2 with impulses title 'org.ala.biocache.web.WMSController'

set yrange [0:*]
set ytics  1
set key left top
set grid
plot "[org.ala.biocache.service.DownloadService].dat"   using 1:2 with impulses title 'org.ala.biocache.service.DownloadService'

set yrange [0:*]
set ytics  1
set key left top
set grid
plot "[org.ala.biocache.service.LoggerRestService].dat" using 1:2 with impulses title 'org.ala.biocache.service.LoggerRestService'

set yrange [0:*]
set ytics  1
set key left top
set grid
plot "[org.ala.biocache.util.CollectionsCache].dat"     using 1:2 with impulses title 'org.ala.biocache.util.CollectionsCache'

set yrange [0:*]
set ytics  1
set key left top
set grid
plot "[org.ala.biocache.web.MapController].dat"         using 1:2 with impulses title 'org.ala.biocache.web.MapController'

set yrange [0:*]
set ytics  1
set key left top
set grid
plot "[org.ala.biocache.web.OccurrenceController].dat"  using 1:2 with impulses title 'org.ala.biocache.web.OccurrenceController'

unset multiplot
