#!/bin/bash

#SBATCH --job-name=fltr_hifiAdapterfilt      ### named job, limit 8 chars
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
# Purpose: Filter stray adapter sequences from HiFi reads.
####################################################################

set -euxo pipefail

module load HiFiAdapterFilt/3.0.0-gompi-2024a
echo "HiFiAdapterFilt module version: ${EBVERSIONHIFIADAPTERFILT}"
echo "hifiadapterfilt.sh script version: $(hifiadapterfilt.sh -v)"

# The module's own pacbio_vectors_db (under /lisc/opt/sw/software/...) fails
# to load with "BLAST Database error: Database memory map file error" --
# confirmed reproducible against that exact file, and confirmed fixed by
# using a byte-identical copy elsewhere, so this is a filesystem quirk on
# that specific install, not a corrupt/wrong database. hifiadapterfilt.sh
# finds its DB by grepping PATH for the first entry containing
# "HiFiAdapterFilt/DB" (see its DBpath= line), so prepending our own copy
# (checked into this repo) makes it win over the module's broken one.
DB_DIR=/lisc/data/work/botany/TBuchloh_WickettLab/woodsia_obtusa/genome_assembly/scripts/datawrangling/BAMtoFASTQ/HiFiAdapterFilt/DB
export PATH="$DB_DIR:$PATH"

# set input and output file paths
INPUT_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM
PREFIX=woodsia_obtusa_hifi_reads

# hifiadapterfilt.sh looks for ${PREFIX}*.bam in the current working
# directory (the -o flag only controls where results are written), so cd
# into the directory holding the merged BAM before calling it. The BAM
# code path in hifiadapterfilt.sh also has a bug where it queries blastn
# against ${outdir}/${x}.fasta instead of the ${read_path_str}/${x}.fasta
# it actually converted the BAM to -- so outdir must be the same directory
# the BAM lives in, or blastn can't find its input and filtering silently
# no-ops (confirmed: this is what happened on the first run).
cd "$INPUT_DIR"

# Run the hifiadapterfilt module with the specified parameters
# hifiadapterfilt.sh [ -p file Prefix ] [ -l minimum Length of adapter match to remove. Default=44 ] [ -m minimum percent Match of adapter to remove. Default=97 ] [ -t Number of threads for blastn. Default=8 ] [ -o outdirectory prefix Default=. ]
hifiadapterfilt.sh -p "$PREFIX" -t "$SLURM_CPUS_PER_TASK" -o "$INPUT_DIR"

# finished
exit