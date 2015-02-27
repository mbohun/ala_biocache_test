set terminal pngcairo font "arial,8" size 1200,500
set title "ALA biocache-service.log"
set ylabel "errors per sec"
set xlabel "date"
set xdata time
set timefmt "%s"
set format x "%Y-%m-%d"
set key left top
set grid
plot "[org.ala.biocache.dao.SearchDAOImpl].dat"         using 1:2 title 'org.ala.biocache.dao.SearchDAOImpl', \
     "[org.ala.biocache.service.AuthService].dat"       using 1:2 title 'org.ala.biocache.service.AuthService', \
     "[org.ala.biocache.service.DownloadService].dat"   using 1:2 title 'org.ala.biocache.service.DownloadService', \
     "[org.ala.biocache.service.LoggerRestService].dat" using 1:2 title 'org.ala.biocache.service.LoggerRestService', \
     "[org.ala.biocache.util.CollectionsCache].dat"     using 1:2 title 'org.ala.biocache.util.CollectionsCache', \
     "[org.ala.biocache.web.MapController].dat"         using 1:2 title 'org.ala.biocache.web.MapController', \
     "[org.ala.biocache.web.OccurrenceController].dat"  using 1:2 title 'org.ala.biocache.web.OccurrenceController', \
     "[org.ala.biocache.web.WMSController].dat"         using 1:2 title 'org.ala.biocache.web.WMSController'
