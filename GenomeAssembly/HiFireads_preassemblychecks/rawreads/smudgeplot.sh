#!/bin/bash

#SBATCH --job-name=smudgeplot      ### named job, limit 8 chars
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
# Purpose: Run Smudgeplot for a ploidy/heterozygosity QC check before
#          assembly. Builds a FastK k-mer database from the filtered
#          HiFi reads, extracts heterozygous k-mer pairs, then plots them.
####################################################################

set -euxo pipefail

module load FastK/1.2-GCCcore-14.3.0
module load Conda/Miniforge3
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate smudgeplot-0.5.3
echo "smudgeplot version: $(smudgeplot --version)"

# set input and output file paths
FASTQ_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM
IN_FILE=woodsia_obtusa_hifi_reads.filt.fastq.gz
KMER_DIR=/lisc/data/work/botany/TBuchloh_WickettLab/woodsia_obtusa/genome_assembly/output/qualitycontrol/kmer_counts
OUT_DIR=/lisc/data/work/botany/TBuchloh_WickettLab/woodsia_obtusa/genome_assembly/output/qualitycontrol/smudgeplot
FASTK_TMP=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/fastk_tmp

# Same k as run_genomescope.sh, so both QC analyses describe the same
# k-mer space. Not a hard requirement of smudgeplot, just consistency.
KMER=21

# Lower coverage cutoff below which k-mers are treated as sequencing
# error and ignored: ~0.5x the fitted haploid kmer coverage. GenomeScope
# (run_genomescope.sh, job 5930883) fit kmercov=23.4, so L = 0.5*23.4 ~ 12.
L_CUTOFF=12

mkdir -p "$KMER_DIR" "$OUT_DIR" "$FASTK_TMP"

# Build the FastK k-mer database from the filtered HiFi reads (FastK reads
# .gz natively, no decompression step needed).
FastK -v -t1 -k"$KMER" -M56 -T"$SLURM_CPUS_PER_TASK" \
  -P"$FASTK_TMP" \
  -N"$KMER_DIR/woodsia_obtusa_hifi_reads_fastk" \
  "$FASTQ_DIR/$IN_FILE"

# Extract heterozygous k-mer pairs into a .smu coverage-pair histogram
smudgeplot hetmers -L "$L_CUTOFF" -t "$SLURM_CPUS_PER_TASK" --verbose \
  -o "$KMER_DIR/woodsia_obtusa_hifi_reads" \
  "$KMER_DIR/woodsia_obtusa_hifi_reads_fastk"

# Infer ploidy and generate the smudgeplot(s)
smudgeplot all \
  -o "$OUT_DIR/woodsia_obtusa_hifi_reads" \
  "$KMER_DIR/woodsia_obtusa_hifi_reads.smu"

# finished
exit
