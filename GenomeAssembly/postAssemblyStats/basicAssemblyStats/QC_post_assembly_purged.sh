#!/bin/bash

#SBATCH --job-name=QC_purg      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: Same QC pipeline as QC_post_assembly.sh (SeqKit, QUAST, BUSCO),
#          rerun on the purge_dups output instead of the pre-purge primary
#          assembly, so the two can be compared on identical metrics via
#          extract_to_table_aiden.py (writes into the same QC_DIR, so one
#          combined table covers both assemblies as separate rows).
####################################################################

set -euxo pipefail

# set input and output file paths
FASTA=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/purge_dups/woodsia_obtusa.purged.fa
ASSEMBLY_NAME=woodsia_obtusa_purged
QC_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/qualityControl/QC_post_assembly
SAMPLE_OUT="$QC_DIR/$ASSEMBLY_NAME"

mkdir -p "$SAMPLE_OUT"

[[ -s "$FASTA" ]] || { echo "ERROR: missing FASTA: $FASTA"; exit 1; }

###############################################################################
### Sanity check with SeqKit
###############################################################################

echo "Running seqkit stats..."

module load SeqKit/2.10.1

seqkit stats "$FASTA" > "$SAMPLE_OUT/${ASSEMBLY_NAME}_seqkit_stats.txt"

max_len=$(awk 'NR==2 {gsub(",", "", $NF); print $NF}' "$SAMPLE_OUT/${ASSEMBLY_NAME}_seqkit_stats.txt")

if (( max_len < 500 )); then
    echo "ERROR: No contigs >= 500 bp. Stopping."
    exit 1
fi

echo "Finished SeqKit stats. Max contig length: $max_len"

module unload SeqKit/2.10.1

###############################################################################
### Running QUAST
###############################################################################

echo "------------------------------------------------------------"
echo "QUAST: assembly quality assessment"
echo "------------------------------------------------------------"
module load QUAST/5.3.0-gfbf-2025b

mkdir -p "$SAMPLE_OUT/quast"

echo "Running QUAST for ${ASSEMBLY_NAME}..."

quast -o "$SAMPLE_OUT/quast" \
  --eukaryote \
  --threads "$SLURM_CPUS_PER_TASK" \
  "$FASTA"

echo "Finished QUAST for ${ASSEMBLY_NAME}"

module unload QUAST/5.3.0-gfbf-2025b

###############################################################################
### Running BUSCO
###############################################################################

echo "------------------------------------------------------------"
echo "BUSCO: assembly completeness assessment"
echo "------------------------------------------------------------"

module load BUSCO/6.1.0-foss-2023a
echo "BUSCO module version: ${EBVERSIONBUSCO}"

cd "$SAMPLE_OUT"

LINEAGE=embryophyta_odb12.2

echo "Running BUSCO for ${ASSEMBLY_NAME}..."

busco \
    -i "$FASTA" \
    -f \
    -c "$SLURM_CPUS_PER_TASK" \
    -l "$LINEAGE" \
    -m genome \
    --miniprot \
    -o "${ASSEMBLY_NAME}_busco"

module unload BUSCO/6.1.0-foss-2023a

echo "Finished BUSCO for ${ASSEMBLY_NAME}"

# finished
exit
