#!/bin/bash

#SBATCH --job-name=astral  ### named job, limit 8 chars
#SBATCH --output=output/out/%x.%j.out   ### path for output file
#SBATCH --error=output/err/%x.%j.err    ### path for error file
#SBATCH --cpus-per-task=64 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=32G   ### RAM available for the script
#SBATCH --time=01-00:00:00   ### time limit (dd-hh:mm:ss) 
#SBATCH --mail-user=thomas.buchloh@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

##################################################################
# Author: Thomas Buchloh. 
# Date: Nov. 2025
# Purpose: Run ASTRAL-Pro3.
##################################################################


# Exit the slurm script if a command fails
set -e

# load modules
module load ASTER

# build the mapping file for locus to species map
# grep "^>" *.fa | sed 's/.*>//' | awk -F_ '{print $0, $1"_"$2}' > locus_species_map.txt # executed in the directory where the alignments are (not in the slurm script). 

# paths
IN_OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/astralpro3

# run astral-pro3 for the first time
astral-pro3 \
-r 16 -s 16 -u 3 -t 64 \
-i $IN_OUT_DIR/iq3_trees_cat.tree \
-o $IN_OUT_DIR/astral_pro3_tree.tree \
-a $IN_OUT_DIR/locus_species_map.txt \
2>$IN_OUT_DIR/astral_run1.log

# finish
exit