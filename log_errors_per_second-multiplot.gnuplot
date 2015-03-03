set datafile separator ","
set terminal pngcairo font "arial,8" size 5000,1000

#set title "ALA biocache-service.log"

set multiplot layout 6,1

set yrange [0:*]
set ytics  5
set ylabel "errors per sec"
set xlabel "date"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set key left top
set grid
plot "[org.ala.biocache.dao.SearchDAOImpl].dat"         using 1:2 with impulses title 'org.ala.biocache.dao.SearchDAOImpl'

set yrange [0:*]
set ytics  1
set ylabel "errors per sec"
set xlabel "date"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set key left top
set grid
plot "[org.ala.biocache.service.AuthService].dat"       using 1:2 with impulses title 'org.ala.biocache.service.AuthService'

set yrange [0:*]
set ytics  1
set ylabel "errors per sec"
set xlabel "date"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set key left top
set grid
plot "[org.ala.biocache.service.DownloadService].dat"   using 1:2 with impulses title 'org.ala.biocache.service.DownloadService'

# set yrange [0:*]
# set ytics  1
# set ylabel "errors per sec"
# set xlabel "date"
# set xdata time
# set timefmt "%Y-%m-%d %H:%M:%S"
# set format x "%Y-%m-%d"
# set key left top
# set grid
# plot "[org.ala.biocache.service.LoggerRestService].dat" using 1:2 with impulses title 'org.ala.biocache.service.LoggerRestService'

# set yrange [0:*]
# set ytics  1
# set ylabel "errors per sec"
# set xlabel "date"
# set xdata time
# set timefmt "%Y-%m-%d %H:%M:%S"
# set format x "%Y-%m-%d"
# set key left top
# set grid
# plot "[org.ala.biocache.util.CollectionsCache].dat"     using 1:2 with impulses title 'org.ala.biocache.util.CollectionsCache'

set yrange [0:*]
set ytics  1
set ylabel "errors per sec"
set xlabel "date"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set key left top
set grid
plot "[org.ala.biocache.web.MapController].dat"         using 1:2 with impulses title 'org.ala.biocache.web.MapController'

set yrange [0:*]
set ytics  1
set ylabel "errors per sec"
set xlabel "date"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set key left top
set grid
plot "[org.ala.biocache.web.OccurrenceController].dat"  using 1:2 with impulses title 'org.ala.biocache.web.OccurrenceController'

set yrange [0:*]
set ytics  1
set ylabel "errors per sec"
set xlabel "date"
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set key left top
set grid
plot "[org.ala.biocache.web.WMSController].dat"         using 1:2 with impulses title 'org.ala.biocache.web.WMSController'

unset multiplot
