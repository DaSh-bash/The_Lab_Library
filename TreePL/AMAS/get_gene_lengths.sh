# you can run this quickly and see terminal output or copy and paste as one-liners

## create new file with just length of alignment 
awk 'NR>1 {print $1 "\t" $3}' summary.txt > genelengths.txt

## get average gene lengths for --genelength flag on ASTRAL
awk '{sum += $2; n++} END {if (n>0) printf "%.6f\n", sum/n; else print 0}' genelengths.txt
