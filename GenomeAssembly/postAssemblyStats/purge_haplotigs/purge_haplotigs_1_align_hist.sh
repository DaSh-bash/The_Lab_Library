#!/bin/bash

#SBATCH --job-name=ph_align      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=96G
#SBATCH --time=03-00:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: purge_haplotigs stage 1/2 - align HiFi reads to the hifiasm
#          primary assembly, then generate purge_haplotigs' read-depth
#          histogram for manual cutoff selection before stage 2
#          (run_purge_haplotigs_2_cov_purge.sh).
#          Requires setup_purge_haplotigs_env.sh to have been run once.
#          https://bitbucket.org/mroachawri/purge_haplotigs
####################################################################

set -euxo pipefail

# load purge_haplotigs (bundles minimap2, samtools, bedtools, R/ggplot2)
module load Conda/Miniforge3
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate purge_haplotigs-1.1.3
conda list purge_haplotigs | grep purge_haplotigs

# set input and output file paths
PRI_ASM=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm/woodsia_obtusa.asm.bp.p_ctg.fa
READS=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM/woodsia_obtusa_hifi_reads.filt.fastq.gz
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/purge_haplotigs

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# purge_haplotigs hist requires the genome to be samtools-indexed first
samtools faidx "$PRI_ASM"

# align HiFi reads to the primary assembly and sort by coordinate.
# -x map-hifi (not the tool's own README example, which is written for
# older PacBio subreads/map-pb): these are CCS/HiFi reads, same preset
# used for this assembly elsewhere (e.g. purge_dups' mapping step).
# -I 10G forces a single-pass index of the ~5.3 Gb assembly, same
# rationale as purge_dups' stage 1 (avoids skewed depth from a
# multi-part index on a genome this large).
# --secondary=no keeps one best alignment per read ("randombest"),
# which is what purge_haplotigs' depth analysis expects.
minimap2 -t "$SLURM_CPUS_PER_TASK" -ax map-hifi -I 10G --secondary=no \
    "$PRI_ASM" "$READS" \
    | samtools sort -@ "$SLURM_CPUS_PER_TASK" -m 1G \
        -T "$OUT_DIR/sort_tmp" -o woodsia_obtusa_hifi_reads.bam -

samtools index woodsia_obtusa_hifi_reads.bam

# generate the read-depth histogram + per-contig coverage file
purge_haplotigs hist -b woodsia_obtusa_hifi_reads.bam -g "$PRI_ASM" \
    -t "$SLURM_CPUS_PER_TASK"
# -> woodsia_obtusa_hifi_reads.bam.histogram.png (depth histogram plot)
# -> woodsia_obtusa_hifi_reads.bam.gencov         (per-contig depth, for stage 2)

# finished
echo "Review $OUT_DIR/woodsia_obtusa_hifi_reads.bam.histogram.png and pick"
echo "low/mid/high read-depth cutoffs (low junk cutoff, boundary between the"
echo "haploid and diploid coverage peaks, high repeat cutoff) before editing"
echo "and running stage 2 (run_purge_haplotigs_2_cov_purge.sh)."
exit
