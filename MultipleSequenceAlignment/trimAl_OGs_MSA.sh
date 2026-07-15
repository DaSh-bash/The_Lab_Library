#!/bin/bash

#SBATCH --job-name=trim_OGs  ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/out/%j.%x.out   ### path for output file
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/err/%j.%x.err    ### path for error file
#SBATCH --cpus-per-task=32 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=64G   ### RAM available for the script
#SBATCH --time=01-00:00:00   ### time limit (hh:mm:ss) 
#SBATCH --mail-user=thomas.buchloh@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

##################################################################
# Author: Thomas Buchloh. 
# Date: Nov. 2025
# Purpose: Run trimAl to trim multiple sequence alignments for many orthogroups in parallel.
# TrimAl call can be changed to match your desired trimming parameters. See trimAl documentation for details.
##################################################################


set -e # Exit the slurm script if a command fails

# load modules
module load trimAl

#### trim famsa alignments first
# paths
INDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/alignments/Orthogroups_MSA_famsa_TB
OUTDIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/angiosp_WGD/output/OrthoFinder_default_core/Results_Feb19/postprocessing_TB/trimmed_alignments/OGs_famsa_trimAlgap25

mkdir -p $OUTDIR

# iterate through all orthogroups and trim alignments
# parallel -j 0 trimal -in {} -out $OUTDIR/{/.}.gt90.cons75.fa -gt 0.9 -cons 75 ::: $INDIR/*.fa # this call fails due to 'argument list too long'. Use following call instead to avoid this issue.
ls $INDIR | grep \.fa | parallel -j 32 "trimal -in $INDIR/{} -out $OUTDIR/{/.}.trimAlgap75.fa -gt 0.75"

# finish
exit