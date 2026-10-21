#!/bin/bash

#SBATCH --job-name=hfasm_repeats      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=400G
#SBATCH --time=03-12:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: Assemble HiFi reads with hifiasm.
####################################################################

set -euxo pipefail

module load hifiasm
echo "hifiasm module version: ${EBVERSIONHIFIASM}"


# set input and output file paths
IN_FILE=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM/woodsia_obtusa_hifi_reads.filt.fastq.gz
OUT_FILE=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/assembly_drafts/wobtusa_hifi_v1.5/woodsia_obtusa_v1.5.asm

mkdir -p "$(dirname "$OUT_FILE")"


# # Run hifiasm with the specified parameters
# hifiasm \
#     -o "$OUT_FILE" \
#     -t "$SLURM_CPUS_PER_TASK" \
#     --hg-size 3.09g \
#     -l 3 \
#     -s 0.1 \
#     --hom-cov 46 \
#     --primary \
#     "$IN_FILE"

# Run hifiasm with parameters for high repeat content
hifiasm \
    -o "$OUT_FILE" \
    -t "$SLURM_CPUS_PER_TASK" \
    --hg-size 3.09g \
    -l 3 \
    --hom-cov 46 \
    -D 30 \
    -N 300 \
    --primary \
    "$IN_FILE"

# finished
exit