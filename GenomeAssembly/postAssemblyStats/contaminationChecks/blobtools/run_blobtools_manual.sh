#!/bin/bash

#SBATCH --job-name=blobman     ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=02:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL

####################################################################
# Author: Thomas Buchloh
# Date: Aug 2026
# Purpose: Build a BlobDir and blob plots with the standalone
#          `blobtools`/`blobtk` CLI instead of the sanger-tol/
#          blobtoolkit Nextflow pipeline (see run_diamond_blastx_
#          pri_hgsize.sh for why: the Nextflow run's own hit-to-
#          contig taxonomy rollup was dropping ~94% of real hits).
#
#          Originally pointed at output/hifiasm/woodsia_obtusa.asm.
#          bp.p_ctg.fa (reusing that Nextflow run's already-computed
#          hits/coverage/BUSCO). That assembly directory has since
#          been deleted from scratch, so this now targets the
#          hifiasm_pri_hgsize assembly instead -- a different contig
#          set, so none of the old run's outputs carry over. Inputs
#          below are freshly generated for this assembly by:
#              run_hifi_read_mapping.sh              (coverage BAM)
#              run_diamond_blastx_pri_hgsize.sh       (taxonomy hits)
#              run_busco_blobtoolkit_pri_hgsize.sh    (BUSCO x5)
#          No blastn-vs-nt this time (skipped for turnaround --
#          diamond blastx alone resolved 99.5% of contigs against
#          the other assembly, which is what actually matters for
#          the blob plot).
#
#          Uses the blobtoolkit/blobtk Singularity images already
#          cached from the earlier Nextflow run (same versions:
#          blobtoolkit 4.4.6, blobtk 0.5.1) rather than re-pulling.
#
#          All 4 scripts in this pipeline (run_hifi_read_mapping.sh,
#          run_diamond_blastx_pri_hgsize.sh, run_busco_blobtoolkit_
#          pri_hgsize.sh, and this one) share one RUN_DIR constant so
#          every stage's output lands under a single directory for
#          this run, instead of being scattered across qualityControl/
#          contamination/ like the first pass was. Change RUN_DIR in
#          all 4 together, to a new suffix, for a fresh run rather
#          than overwriting this one.
####################################################################

set -euxo pipefail

module purge
module load SAMtools

# Nextflow auto-binds each task's own workDir into its Singularity
# containers (inputs get staged/symlinked there first). Calling
# singularity directly here has no such staging, so the container
# can't see /lisc/data paths unless bound explicitly.
export SINGULARITY_BIND="/lisc/data:/lisc/data"
export APPTAINER_BIND="/lisc/data:/lisc/data"

###############################################################################
# INPUTS
###############################################################################

FASTA=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm_v1.2/woodsia_obtusa.asm.p_ctg.fa
TAXID=29611
TAXDUMP=/lisc/data/work/botany/diospyrosProj/Amin_tmp/blob_tool_kit/taxdump_2026_04

RUN_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/blobtoolkit_manual_pri_hgsize

BAM="${RUN_DIR}/mapping/woodsia_obtusa_primary.hifi.sorted.bam"

BLASTX_HITS="${RUN_DIR}/diamond_blastx/woodsia_obtusa.asm.p_ctg.blastx.txt"

BUSCO_DIR="${RUN_DIR}/busco"
BUSCO_TABLES=(
    "${BUSCO_DIR}/eukaryota_odb12/run_eukaryota_odb12/full_table.tsv"
    "${BUSCO_DIR}/bacteria_odb12/run_bacteria_odb12/full_table.tsv"
    "${BUSCO_DIR}/archaea_odb12/run_archaea_odb12/full_table.tsv"
    "${BUSCO_DIR}/embryophyta_odb12/run_embryophyta_odb12/full_table.tsv"
    "${BUSCO_DIR}/viridiplantae_odb12/run_viridiplantae_odb12/full_table.tsv"
)

SIF_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/blobtoolkit_wobtusa_v1.1/singularity_cache
BTK_SIF="${SIF_DIR}/docker.io-genomehubs-blobtoolkit-4.4.6.img"
BLOBTK_SIF="${SIF_DIR}/docker.io-genomehubs-blobtk-0.5.1.img"

###############################################################################
# OUTPUTS
###############################################################################

BLOBDIR="${RUN_DIR}/BlobDir"
PLOTDIR="${RUN_DIR}/plots"

mkdir -p "$BLOBDIR" "$PLOTDIR"

###############################################################################
# BUILD BLOBDIR
###############################################################################

singularity exec "$BTK_SIF" blobtools add \
    --create \
    --fasta "$FASTA" \
    --taxid "$TAXID" \
    --taxdump "$TAXDUMP" \
    --threads "$SLURM_CPUS_PER_TASK" \
    "$BLOBDIR"

singularity exec "$BTK_SIF" blobtools add \
    --cov "$BAM" \
    --threads "$SLURM_CPUS_PER_TASK" \
    "$BLOBDIR"

singularity exec "$BTK_SIF" blobtools add \
    --hits "$BLASTX_HITS" \
    --taxrule bestsumorder \
    --taxdump "$TAXDUMP" \
    --threads "$SLURM_CPUS_PER_TASK" \
    "$BLOBDIR"

for TABLE in "${BUSCO_TABLES[@]}"; do
    singularity exec "$BTK_SIF" blobtools add \
        --busco "$TABLE" \
        --threads "$SLURM_CPUS_PER_TASK" \
        "$BLOBDIR"
done

###############################################################################
# PLOTS
###############################################################################

singularity exec "$BLOBTK_SIF" blobtk plot -v blob \
    --blobdir "$BLOBDIR" -o "${PLOTDIR}/woodsia_obtusa.blob.png"

singularity exec "$BLOBTK_SIF" blobtk plot -v snail \
    --blobdir "$BLOBDIR" -o "${PLOTDIR}/woodsia_obtusa.snail.png"

singularity exec "$BLOBTK_SIF" blobtk plot -v cumulative \
    --blobdir "$BLOBDIR" -o "${PLOTDIR}/woodsia_obtusa.cumulative.png"

# finished
exit
