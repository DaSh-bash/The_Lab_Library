#!/bin/bash

#SBATCH --job-name=famsa_array  ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/out/%x_%A_%a.out   ### path for output file %A for job ID, %a for array task ID
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/err/%x_%A_%a.err    ### path for error file
#SBATCH --array=1-50     # Specify array task number: e.g., 1-100%20 means tasks 1 through 100 max with a max of 20 running simultaneously
#SBATCH --ntasks=1 ### number of tasks (processes) to run, set to 1 by default for array jobs
#SBATCH --cpus-per-task=16 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=20G   ### RAM available for the each array task
#SBATCH --time=01-00:00:00   ### time limit (dd-hh:mm:ss) 
#SBATCH --mail-user=thomas.buchloh@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=ALL    ### email notification types

##################################################################
# Author: Thomas Buchloh. 
# Date: Nov. 2025
# Purpose: Run FAMSA to generate multiple sequence alignments for many 
# orthogroups in parallel using a SLURM array job.
##################################################################

module load FAMSA

# set input and output directories. Make sure to adjust these paths to your specific directories.
INDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/Orthogroup_Sequences_Renamed
OUTDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/Orthogroups_MSA_famsa_TB

mkdir -p $OUTDIR

# locate file with the relevant orthogroup names
GENES_FILE=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/Orthogroups_with4ormoretaxa.txt
# SAMPLES=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/Orthogroups/Orthogroups_with4ormoretaxa.tsv

# create a list of orthogroup files from 1) the SAMPLES file or from 2) the directory with the alignments
# awk -F'\t' '{print $1".fa"}' $SAMPLES > $GENES_FILE # this is done outside the script to avoid overwriting the file in each array job. But it is kept here for reference. 
# ls -1 *.fa > $GENES_FILE # this is done outside the script to avoid overwriting the file in each array job. But it is kept here for reference.

TOTAL=$(wc -l < "$GENES_FILE")
NJOBS=50 # needs to exactly match the --array parameter above. 

# calculate which lines this job handles
START=$(( (SLURM_ARRAY_TASK_ID - 1) * TOTAL / NJOBS + 1 ))
END=$(( SLURM_ARRAY_TASK_ID * TOTAL / NJOBS ))

# loop over assigned genes and align with FAMSA
sed -n "${START},${END}p" "$GENES_FILE" | while read FILE; do
    famsa  -t 16 -medoidtree -trim_columns 0.05 $INDIR/$FILE $OUTDIR/$FILE.famsa
done
