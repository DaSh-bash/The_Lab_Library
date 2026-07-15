#!/bin/bash

#SBATCH --job-name=algn_OGs  ### named job, limit 8 chars
#SBATCH --output=output/out/%j.%x.out   ### path for output file
#SBATCH --error=output/err/%j.%x.err    ### path for error file
#SBATCH --cpus-per-task=32 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=512G   ### RAM available for the script
#SBATCH --time=4-00:00:00   ### time limit (hh:mm:ss) 
#SBATCH --mail-user=thomas.buchloh@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

##################################################################
# Author: Thomas Buchloh. 
# Date: Nov. 2025
# Purpose: Run MAFFT to generate multiple sequence alignments for many 
# orthogroups in parallel using a SLURM array job.
##################################################################

# Exit the slurm script if a command fails
set -e

# load modules
module load MAFFT/7.526-GCC-13.3.0-with-extensions

# paths to your input and output locations. Make sure to adjust these paths to your specific directories.
SAMPLES=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/Orthogroups/Orthogroups_with4ormoretaxa.tsv
INDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/Orthogroup_Sequences_Renamed
OUTDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/Orthogroups_Aligned_Sequences_v2_TB

# iterate through all orthogroups and generate alignments
parallel --colsep '\t' --skip-first-line -a $SAMPLES "mafft --auto '$INDIR/{1}.fa' > '$OUTDIR/{1/.}.aligned.fa'"

# finsh
exit
