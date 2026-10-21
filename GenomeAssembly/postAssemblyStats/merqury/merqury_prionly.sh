#!/bin/bash

#SBATCH --job-name=merq_pri2      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: Evaluate the primary-only hifiasm assembly (hifiasm_pri_hgsize
#          run, --primary/--hg-size) with MerquryFK, a k-mer based,
#          reference-free assembly QC tool. Reusing the k-mer table
#          built for genomescope/smudgeplot QC.
####################################################################

set -euxo pipefail

# load modules or tools
module load MERQURY.FK/1.2-foss-2025b
echo "MERQURY.FK module version: ${EBVERSIONMERQURYFK}"

# set input and output file paths
GENOME_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm_pri_hgsize
PRI=woodsia_obtusa.asm.p_ctg.fa
# k=21 FastK read k-mer table, already built (see kmer_counts/) for genomescope/smudgeplot QC
READS_KTAB=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/kmer_counts/woodsia_obtusa_hifi_reads_fastk
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/merqury_pri_hgsize
TMP_DIR="$OUT_DIR/tmp"

mkdir -p "$TMP_DIR"
# cd so MerquryFK's internal temp files land in scratch even where it
# doesn't fully respect -P and instead writes relative to cwd
cd "$TMP_DIR"

OUT_PREFIX="$OUT_DIR/woodsia_obtusa"

# evaluate the single primary assembly against the existing read k-mer table
MerquryFK -v -T"$SLURM_CPUS_PER_TASK" -P"$TMP_DIR" "$READS_KTAB" "$GENOME_DIR/$PRI" "$OUT_PREFIX"

# finished
exit
