#!/bin/bash

#SBATCH --job-name=AMAS  ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/out/%x.%j.out   ### path for output file
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/err/%x.%j.err    ### path for error file
#SBATCH --cpus-per-task=64 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=64G   ### RAM available for the script
#SBATCH --time=1-00:00:00   ### time limit (dd-hh:mm:ss) 
#SBATCH --mail-user=thomas.buchloh@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

##################################################################
# Author: Thomas Buchloh. 
# Date: Nov. 2025
# Purpose: Run AMAS to generate summary statistics for many 
# alignments and individual sequences in multiple sequence alignments.
##################################################################

# Exit the slurm script if a command fails
set -e

# Paths to your input and output locations. Make sure to adjust these paths to your specific directories.
INDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/Orthogroups_MSA_famsa_TB
OUTDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/AMAS_summaryStats_FAMSA
AMAS=/lisc/home/user/buchloh/git/AMAS/amas/AMAS.py
# OUTFILE=summary_all.txt

# make output directory if it doesn't exist
mkdir -p ${OUTDIR}

### Run AMAS to generate summary statistics for alignments
## Run by-taxon for every individual alignment. 
ls $INDIR | grep \.fa | parallel -j $SLURM_CPUS_PER_TASK "python3 $AMAS summary --by-taxon --data-type aa --in-format fasta -i $INDIR/{}" # OG summaries go to output directory. Sequence summaries go to input directory.
# mv ${INDIR}/*.fa-summary.txt ${OUTDIR}

## Run in batches of 10k alignments to avoid argument length issues. 
# python3 ${AMAS} summary -c 12 --data-type aa --in-format fasta -i ${INDIR}/OG000*.aligned.fa -o ${INDIR}/summary_00000_09999.txt

# cat summary_*_*.txt > ${OUTDIR}/summary_all.txt

# finish
exit

