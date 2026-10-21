#!/bin/bash

#SBATCH --job-name=pd_map      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=03-00:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: purge_dups stage 1 (of 2) - map HiFi reads to the hifiasm primary
#          assembly to get read-depth statistics, then auto-calculate
#          purge_dups coverage cutoffs and plot the depth histogram for
#          manual review before stage 2 (run_purge_dups_2_purge.sh).
#          https://github.com/dfguan/purge_dups
####################################################################

set -euxo pipefail

# load modules or tools (also loads minimap2 as a dependency)
module load purge_dups/1.2.6-foss-2023b
echo "purge_dups module version: ${EBVERSIONPURGE_DUPS}"
echo "minimap2 version: $(minimap2 --version)"

# set input and output file paths
PRI_ASM=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm/woodsia_obtusa.asm.bp.p_ctg.fa
READS=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM/woodsia_obtusa_hifi_reads.filt.fastq.gz
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/purge_dups

mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# map HiFi reads to the primary assembly for read-depth statistics.
# -I 10G forces minimap2 to index the ~5.3 Gb assembly in a single pass;
# purge_dups' docs warn read depth comes out wrong on large genomes if
# minimap2 has to split the index into multiple batches (default -I 8G
# would already be close to a single pass here, but this removes any risk)
minimap2 -x map-hifi -I 10G -t "$SLURM_CPUS_PER_TASK" "$PRI_ASM" "$READS" \
    | gzip -c - > woodsia_obtusa_hifi_reads.paf.gz

# compute read-depth histogram (PB.stat) and base-level coverage (PB.base.cov)
pbcstat -O "$OUT_DIR" woodsia_obtusa_hifi_reads.paf.gz

# auto-calculate low/mid/high read-depth cutoffs from PB.stat
calcuts PB.stat > cutoffs 2> calcuts.log

# plot the depth histogram with the auto cutoffs overlaid, for manual review
# (purge_dups' docs recommend checking this, especially for genomes with
# atypical heterozygosity, before trusting the auto cutoffs in stage 2)
python3 "${EBROOTPURGE_DUPS}/scripts/hist_plot.py" -c cutoffs PB.stat PB.cov.png

# finished
echo "Review $OUT_DIR/PB.cov.png and $OUT_DIR/cutoffs before running stage 2."
echo "If the auto cutoffs look wrong, regenerate manually, e.g.:"
echo "  calcuts -l <low> -m <mid> -u <high> $OUT_DIR/PB.stat > $OUT_DIR/cutoffs_manual"
exit
