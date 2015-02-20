set terminal pngcairo font "arial,6" size 1200,500
set output 'errors-per-day-histogram.png'
set boxwidth 0.95
set style fill solid
set title "biocache-service errors per day"
plot "errors-per-day-example.dat" using 2:xtic(1) with boxes
