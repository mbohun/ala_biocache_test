set datafile separator ","

# NOTE: on osx EITHER install gnuplot with: 'brew install gnuplot --cairo' / 'brew install gnuplot --with-cairo'
#              OR change the terminal from pngcairo to png (however the png output is acceptable but phugly)
set terminal pngcairo font "arial,8" size 4096,1200

# NOTE: for SVG output use:
#set terminal svg fname 'arial' fsize 7 size 4096,1200

set xlabel "date"
set ylabel "errors per sec"
set yrange [0:]

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%Y-%m-%d"
set xrange["2015-02-19 00:00:00":"2015-03-10 00:00:00"]
set xtics "1980-01-01 00:00:00",86400

set key left top
set grid

set multiplot layout 9,1 title "ALA biocache-service.log"

set ytics  5
plot "[org.ala.biocache.dao.SearchDAOImpl].dat"         using 1:2 with impulses title 'org.ala.biocache.dao.SearchDAOImpl'

set ytics  1
plot "[org.ala.biocache.service.AuthService].dat"       using 1:2 with impulses title 'org.ala.biocache.service.AuthService'

set ytics  1
plot "[org.ala.biocache.web.WMSController].dat"         using 1:2 with impulses title 'org.ala.biocache.web.WMSController'

set ytics  1
plot "[org.ala.biocache.service.DownloadService].dat"   using 1:2 with impulses title 'org.ala.biocache.service.DownloadService'

set ytics  1
plot "[org.ala.biocache.service.LoggerRestService].dat" using 1:2 with impulses title 'org.ala.biocache.service.LoggerRestService'

set ytics  1
plot "[org.ala.biocache.util.CollectionsCache].dat"     using 1:2 with impulses title 'org.ala.biocache.util.CollectionsCache'

set ytics  1
plot "[org.ala.biocache.web.MapController].dat"         using 1:2 with impulses title 'org.ala.biocache.web.MapController'

set ytics  1
plot "[org.ala.biocache.web.OccurrenceController].dat"  using 1:2 with impulses title 'org.ala.biocache.web.OccurrenceController'

unset multiplot
