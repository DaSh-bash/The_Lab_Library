#!/bin/bash

#SBATCH --job-name=genomescope      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=150G
#SBATCH --time=24:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: Run GenomeScope 2.0 for quality control check before assembly.
####################################################################

set -euxo pipefail

module load Jellyfish
module load GenomeScope
echo "Jellyfish module version: ${EBVERSIONJELLYFISH}" # works for modules built with EasyBuild
echo "GenomeScope module version: ${EBVERSIONGENOMESCOPE}" # works for modules built with EasyBuild

# set input and output file paths
FASTQ_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM
IN_FILE=woodsia_obtusa_hifi_reads.filt.fastq.gz
KMER_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/kmer_counts_k31
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/genomescope_k31

KMER=31

mkdir -p "$KMER_DIR" "$OUT_DIR"

# Run Jellyfish to count k-mers in the input FASTQ file. jellyfish can't
# read .gz files directly, so decompress on the fly via process substitution.
jellyfish count -C -m "$KMER" -s 5G -t "$SLURM_CPUS_PER_TASK" \
  -o "$KMER_DIR/woodsia_obtusa_hifi_reads.jf" \
  <(zcat "$FASTQ_DIR/$IN_FILE")

# Build the k-mer frequency histogram GenomeScope expects
jellyfish histo -t "$SLURM_CPUS_PER_TASK" \
  "$KMER_DIR/woodsia_obtusa_hifi_reads.jf" > "$KMER_DIR/woodsia_obtusa_hifi_reads.histo"

# Run GenomeScope to analyze the k-mer frequency histogram and estimate genome characteristics
genomescope.R -i "$KMER_DIR/woodsia_obtusa_hifi_reads.histo" -o "$OUT_DIR" -k "$KMER"

# finished
exit