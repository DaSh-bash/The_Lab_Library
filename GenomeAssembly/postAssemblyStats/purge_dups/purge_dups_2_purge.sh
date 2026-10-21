#!/bin/bash

#SBATCH --job-name=pd_purge      ### named job, limit 8 chars
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
# Purpose: purge_dups stage 2 (of 2) - split the primary assembly, self-align
#          it, purge haplotigs/overlaps using the read-depth cutoffs from
#          stage 1 (run_purge_dups_1_mapping.sh), and extract the purged
#          primary assembly plus the removed haplotig sequences.
#          Requires stage 1 to have completed first (needs PB.base.cov
#          and a reviewed cutoffs file in OUT_DIR).
#          https://github.com/dfguan/purge_dups
####################################################################

set -euxo pipefail

# load modules or tools (also loads minimap2 as a dependency)
module load purge_dups/1.2.6-foss-2023b
echo "purge_dups module version: ${EBVERSIONPURGE_DUPS}"
echo "minimap2 version: $(minimap2 --version)"

# set input and output file paths
PRI_ASM=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm/woodsia_obtusa.asm.bp.p_ctg.fa
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/purge_dups
# cutoffs file reviewed/confirmed after stage 1 (edit this if you generated
# a manual cutoffs_manual file instead of using the auto cutoffs)
CUTOFFS="$OUT_DIR/cutoffs"

cd "$OUT_DIR"

# split the assembly at N-gaps so haplotig/overlap purging can act on
# individual contigs rather than whole scaffolds
split_fa "$PRI_ASM" > pri_asm.split

# self-align the split assembly to find duplicated/overlapping regions
# (-D drops self-diagonal hits, -P keeps all chains rather than just the
# best one per query, both required by purge_dups for this step)
minimap2 -x asm5 -DP -t "$SLURM_CPUS_PER_TASK" pri_asm.split pri_asm.split \
    | gzip -c - > pri_asm.split.self.paf.gz

# identify haplotigs/overlaps to purge, using stage 1's base-level
# coverage and the reviewed read-depth cutoffs
purge_dups -2 -T "$CUTOFFS" -c PB.base.cov pri_asm.split.self.paf.gz \
    > dups.bed 2> purge_dups.log

# extract the purged primary assembly and the removed haplotig sequences
# -e: only remove duplications at the ends of contigs (safer default;
# without it, internal false positives risk being deleted too)
get_seqs -e -p woodsia_obtusa dups.bed "$PRI_ASM"
# -> woodsia_obtusa.purged.fa (cleaned primary assembly)
# -> woodsia_obtusa.hap.fa    (removed haplotig/duplicated sequences)

# finished
exit
