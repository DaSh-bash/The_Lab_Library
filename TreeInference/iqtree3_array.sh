#!/bin/bash

#SBATCH --job-name=iqt3_f_low  ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/out/%x_%A_%a.out       ### path for output file %A for job ID, %a for array task ID
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/err/%x_%A_%a.err        ### path for error file
#SBATCH --array=1-1891      # Specify array task number: e.g., 1-100%20 means tasks 1 through 100 max with a max of 20 running simultaneously
#SBATCH --ntasks=1      ### number of tasks (processes) to run, set to 1 by default for array jobs
#SBATCH --cpus-per-task=3       ### number of cpus assigned to job if ntask=1
#SBATCH --mem=10G      ### RAM available for the script
#SBATCH --time=3-00:00:00    ### time limit (dd-hh:mm:ss) 
#SBATCH --mail-user=thomas.buchloh@univie.ac.at      ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL     ### email notification types

##################################################################
# Author: Thomas Buchloh. 
# Date: Nov. 2025
# Purpose: Run IQ-TREE3 to generate phylogenetic trees for many orthogroups in parallel using a SLURM array job.
# This script is designed to work with trimmed alignments.
##################################################################


# Exit the slurm script if a command fails
set -e

# load modules
module load IQ-TREE

# Variables to modify
INPUT_DIR=/path/to/alignments # Directory containing alignment files
OUTPUT_DIR=/path/to/IQTREE_results # Directory to save IQ-TREE3 results
ALN_LIST=/path/to/alignment_list.txt # A text file containing the list of alignment files (one per line) to be processed by the array job

MODEL=TEST # Model selection method (e.g., MFP = model finder then do tree reconstruction with best model, TEST = test basic models then do tree reconstruction with best model)
BOOTSTRAP=5000 # Number of ultrafast bootstrap replicates (e.g., 1000)

# Create output directory if it doesn't exist
mkdir -p ${OUTPUT_DIR}

TOTAL=$(wc -l < "$ALN_LIST")
NJOBS=$SLURM_ARRAY_TASK_COUNT # needs to exactly match the --array parameter above. 

# calculate which lines this job handles
START=$(( (SLURM_ARRAY_TASK_ID - 1) * TOTAL / NJOBS + 1 ))
END=$(( SLURM_ARRAY_TASK_ID * TOTAL / NJOBS ))

# Run IQ-TREE3
# -s: input alignment file
# -m: model selection method
# -bb: number of ultrafast bootstrap replicates
# -nt: number of threads to use (set to the number of CPUs allocated for the job)
# --prefix: prefix for output files (e.g., tree files, log files)

# loop over assigned genes
sed -n "${START},${END}p" "$ALN_LIST" | while read FILE; do

    echo "trying iqtree3 reconstruction on $FILE"

    if [ ! -f $INPUT_DIR/$FILE ]; then
    echo "$FILE not found!"
    fi

    iqtree3 \
        -s $INPUT_DIR/$FILE \
        -m ${MODEL} \
        -bb ${BOOTSTRAP} \
        -nt AUTO \
        --prefix ${OUTPUT_DIR}/$FILE
done

# finish
exit