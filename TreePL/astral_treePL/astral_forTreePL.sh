#!/bin/bash

#SBATCH --job-name=astral_forTreePL ### named job, limit 8 chars
#SBATCH --output=output/out/%x.%j.out   ### path for output file
#SBATCH --error=output/err/%x.%j.err    ### path for error file
#SBATCH --cpus-per-task=64 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=2G   ### RAM available for the script
#SBATCH --time=01:00:00   ### time limit (dd-hh:mm:ss) 
#SBATCH --mail-user=julia.mcclafferty@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

# Exit the slurm script if a command fails
set -e

# load modules
module load ASTER

# build the mapping file for locus to species map
##grep "^>" *.fa | sed 's/.*>//' | awk -F_ '{print $0, $1"_"$2}' > locus_species_map.txt # executed in the directory where the alignments are. FROM THOMAS --> works on his files
##grep -h '^>' *.fna | sed 's/^>//' | awk -F_ -v OFS='\t' '{print $0, $1}' > locus_species_map.txt ## WORKS ON MY FILES

# paths
IN_OUT_DIR=/lisc/data/scratch/botany/mcclafferty/schiedea/ASTRAL

# run astral pro for treePL. Must include --root for treePL, can make substitutions per site more accurate if you include --genelength
astral-pro3 \
-r 16 -s 16 -u 3 -t 64 \
-i $IN_OUT_DIR/cat_genetrees.treefile \
-o $IN_OUT_DIR/astral_fortreePL.tree \
-a $IN_OUT_DIR/locus_species_map.txt \
--root Bvulgaris \
--genelength 1267 \ ## see AMAS to get average length of alignment 
2>$IN_OUT_DIR/astral_run_root_genelengths.log

# finish
exit
