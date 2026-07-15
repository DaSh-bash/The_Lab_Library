#!/bin/bash

#SBATCH --job-name=ofdef_as  ### named job, limit 8 chars
#SBATCH --output=output/out/%j.%x.out   ### path for output file
#SBATCH --error=output/err/%j.%x.err    ### path for error file
#SBATCH --cpus-per-task=32 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=768G   ### RAM available for the script
#SBATCH --time=7-00:00:00   ### time limit (hh:mm:ss) 
#SBATCH --mail-user=thomas.buchloh@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

# Exit the slurm script if a command fails
set -e

##################################################################
# Author: Thomas Buchloh. 
# Date: Nov. 2025
# Purpose: Run OrthoFinder for 64 core genomes and then assign 
# the rest of the genomes to the core results to speed up the analysis.
##################################################################

## load module
# module load OrthoFinder/3.1.2-foss-2024a

# or

## load conda and conda environment
# The LiSC HPC module for OrthoFinder may or may not work. If needed, a script for building the conda environment for your prefered version of Orthofinder is available on the Wickett_Lab Github.
module load Conda/Miniforge3
conda activate of3_env

# Paths to your input and output locations. Make sure to adjust these paths to your specific directories.
INFILE=/lisc/data/work/botany/TBuchloh_WickettLab/lisc_meiosis_WGD_angiosperms/data/raw_data/pep
OUTDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output

## run core orthofinder analysis (note: non-default output directory (-o) must not exist already)
orthofinder -t 32 -a 16 -f $INFILE/core -o $OUTDIR/OrthoFinder_default_core
# orthofinder -t 32 -a 16 -T iqtree3 -f $INFILE/core -o $OUTDIR/OrthoFinder_iqtree3_core

## after core has completed, run the rest of the genomes using the core results
orthofinder -t 32 -a 8 --assign $INFILE/assign --core $OUTDIR/OrthoFinder_default_core/Results_Feb09

#end job
exit