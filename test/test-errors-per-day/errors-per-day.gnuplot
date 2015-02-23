set terminal pngcairo font "arial,6" size 1200,500
set output
set boxwidth 0.95
set style fill solid
set title "biocache-service errors per day"
plot "/dev/stdin" using 2:xtic(1) with boxes
