#!/bin/bash

#SBATCH --job-name=quast      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=128G
#SBATCH --time=03-00:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: Run quast to get genome assembly statistics.
####################################################################

set -euxo pipefail

# load modules or tools
module load QUAST

# log a tool's version 
print_version() {
  echo "$1 binary: $(command -v "$1")"
  echo "$1 version: $("$1" --version 2>&1 || true)"
}
print_version quast

# set input and output file paths
GENOME_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm
# HAP1=woodsia_obtusa.asm.bp.hap1.p_ctg.fa
# HAP2=woodsia_obtusa.asm.bp.hap2.p_ctg.fa
PRIMARY=woodsia_obtusa.asm.bp.p_ctg.fa
READS_PB=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM/woodsia_obtusa_hifi_reads.filt.fastq.gz
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/quast

mkdir -p "$OUT_DIR"

# Run quast
quast "$GENOME_DIR/$PRIMARY" \
        --k-mer-stats \
        --threads "$SLURM_CPUS_PER_TASK" \
        --no-snps \
        -o "$OUT_DIR"

# finished
exit