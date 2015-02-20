set terminal pngcairo font "arial,10" size 500,500
set output 'errors-per-day-histogram.png'
set boxwidth 0.75
set style fill solid
set title "biocache-service errors per day"
plot "errors-per-day.dat" using 2:xtic(1) with boxes
