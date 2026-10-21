#!/bin/bash

#SBATCH --job-name=gfastats      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Sep 2026
# Purpose: Compute assembly statistics for the primary-only hifiasm
#          assembly (repeat-content params: -D 30 -N 300) with
#          gfastats, run directly on the primary contig graph.
####################################################################

set -euxo pipefail

module load gfastats
gfastats --version

# set input and output file paths
GENOME_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/assembly_drafts/wobtusa_hifi_v1.5
PRI=woodsia_obtusa_v1.5.asm.p_ctg.gfa
OUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/wobtusa_v1.5

mkdir -p "$OUT_DIR"

# run gfastats on the primary-only assembly graph
gfastats "$GENOME_DIR/$PRI" --discover-paths --nstar-report -j "$SLURM_CPUS_PER_TASK" \
    > "$OUT_DIR/woodsia_obtusa_v1.5_primary_gfastats.txt"

# finished
exit
