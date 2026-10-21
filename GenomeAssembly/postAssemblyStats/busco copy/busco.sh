#!/bin/bash

#SBATCH --job-name=busc_pri2      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: Assess BUSCO gene completeness of the primary-only hifiasm
#          assembly (hifiasm_pri_hgsize run, --primary/--hg-size)
#          against embryophyta_odb12.2.
####################################################################

set -euxo pipefail

# load modules or tools
module load BUSCO/6.1.0-foss-2023a
echo "BUSCO module version: ${EBVERSIONBUSCO}"

# set input and output file paths
GENOME_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm_pri_hgsize
PRI=woodsia_obtusa.asm.p_ctg.fa
LINEAGE=embryophyta_odb12.2
OUT_PATH=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/busco_pri_hgsize

mkdir -p "$OUT_PATH"
# cd so BUSCO's default ./busco_downloads/ cache lands in scratch, not
# wherever sbatch was invoked from; fetched fresh from the online
# database each run for now, no local dataset copy kept
cd "$OUT_PATH"

busco -i "$GENOME_DIR/$PRI" -o primary --out_path "$OUT_PATH" \
        -m genome -l "$LINEAGE" -c "$SLURM_CPUS_PER_TASK"

# finished
exit
