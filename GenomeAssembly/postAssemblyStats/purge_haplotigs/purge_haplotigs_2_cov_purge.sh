#!/bin/bash

#SBATCH --job-name=ph_purge      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=03-00:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: purge_haplotigs stage 2/2 - classify contigs by read depth
#          using the low/mid/high cutoffs picked from stage 1's
#          histogram (run_purge_haplotigs_1_align_hist.sh), then purge
#          (reassign) haplotigs via all-vs-all contig alignment.
#          Requires stage 1 to have completed first (needs the .bam and
#          .bam.gencov in OUT_DIR) and LOW/MID/HIGH below to be set from
#          manual review of the stage 1 histogram.
#          https://bitbucket.org/mroachawri/purge_haplotigs
####################################################################

set -euxo pipefail

# load purge_haplotigs (bundles minimap2, samtools, bedtools, R/ggplot2)
module load Conda/Miniforge3
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate purge_haplotigs-1.1.3

# set input and output file paths
PRI_ASM=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm/woodsia_obtusa.asm.bp.p_ctg.fa
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/purge_haplotigs
BAM="$OUT_DIR/woodsia_obtusa_hifi_reads.bam"
GENCOV="$OUT_DIR/woodsia_obtusa_hifi_reads.bam.gencov"

# EDIT THESE -- read off woodsia_obtusa_hifi_reads.bam.histogram.png
# (stage 1 output): LOW = cutoff below which coverage is junk, MID =
# the low point between the haploid and diploid coverage peaks, HIGH =
# cutoff above which coverage is repeat/artefact.
LOW=
MID=
HIGH=

cd "$OUT_DIR"

# classify each contig by % low/diploid/high coverage using the cutoffs
purge_haplotigs cov -i "$GENCOV" -l "$LOW" -m "$MID" -h "$HIGH" \
    -o coverage_stats.csv
# -> coverage_stats.csv (per-contig s/h/a/n classification, for the purge step)

# align contigs against each other and reassign flagged haplotigs.
# -b: bam is only needed here to generate the review dotplots (-d)
# -d: write dotplots for reassigned/unassigned contigs, for manual QC
purge_haplotigs purge -g "$PRI_ASM" -c coverage_stats.csv -b "$BAM" \
    -t "$SLURM_CPUS_PER_TASK" -o woodsia_obtusa_purged -d
# -> woodsia_obtusa_purged.fasta               (curated/purged primary assembly)
# -> woodsia_obtusa_purged.haplotigs.fasta     (reassigned haplotig sequences)
# -> woodsia_obtusa_purged.artefacts.fasta     (low/high-coverage artefact contigs)
# -> woodsia_obtusa_purged.reassignments.tsv   (reassignment log)
# -> woodsia_obtusa_purged.contig_associations.log
# -> dotplots_reassigned_contigs/, dotplots_unassigned_contigs/ (manual QC)

# finished
exit
