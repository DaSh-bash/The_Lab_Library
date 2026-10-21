#!/bin/bash

#SBATCH --job-name=fastk_k31      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: Build a k=31 FastK k-mer table from the HiFi reads (same
#          reads used for the existing k=21 table), for tools that need
#          FastK/MerquryFK specifically rather than the Jellyfish counts
#          used for GenomeScope. This is a from-scratch run - the k=21
#          table already present in kmer_counts_k21/ was originally built
#          outside this project's own scripts, so this run also gives the
#          first real timing for a full FastK build on this read set.
####################################################################

set -euxo pipefail

module load MERQURY.FK
echo "MERQURY.FK module version: ${EBVERSIONMERQURYFK}" # works for modules built with EasyBuild
echo "FastK version: ${EBVERSIONFASTK}"

# set input and output file paths
FASTQ_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM
IN_FILE=woodsia_obtusa_hifi_reads.filt.fastq.gz
KMER_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/rawhifireads/kmer_counts_k31
TMP_DIR="$KMER_DIR/tmp"

KMER=31

mkdir -p "$KMER_DIR" "$TMP_DIR"
cd "$KMER_DIR"

# -t1: keep all k-mers (count >=1) so the table is usable by MerquryFK,
# not just a histogram
FastK -v -k"$KMER" -t1 -T"$SLURM_CPUS_PER_TASK" -M48 -P"$TMP_DIR" \
  -N"$KMER_DIR/woodsia_obtusa_hifi_reads_fastk" \
  "$FASTQ_DIR/$IN_FILE"

# finished
exit
