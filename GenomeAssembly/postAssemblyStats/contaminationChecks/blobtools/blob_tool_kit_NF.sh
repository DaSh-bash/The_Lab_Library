#!/bin/bash

#SBATCH --job-name=blobtk      ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=250G
#SBATCH --time=04-00:00:00
#SBATCH --no-requeue
#SBATCH --chdir=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/contamination/blobtoolkit_wobtusa_v1.4
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL


####################################################################
# Author: Thomas Buchloh (adapted from a script provided by Amin).
# Date: Aug 2026
# Purpose: Run the sanger-tol/blobtoolkit Nextflow pipeline on the
#          hifiasm assembly to check for contamination/
#          taxonomic screening -- BUSCO completeness, GC/coverage,
#          and blast/diamond hits per contig.
#          https://pipelines.tol.sanger.ac.uk/blobtoolkit
#
#          NOTE: --chdir above must exist before this job is
#          submitted (sbatch checks it at submit time, before this
#          script's own mkdir -p runs) -- create it by hand once, or
#          run this script's mkdir line interactively first.
#
#          Reuses shared reference databases (BUSCO DB, NCBI taxdump,
#          diamond protein DB) from Amin's group-readable project
#          directory rather than building our own copies.
#
#          Resources scaled up from Amin's proven config (36 cpu /
#          250G / 1d6h, ran successfully for a smaller Diospyros
#          assembly) since ours is larger and more fragmented
#          (5.28 Gb, 12,694 contigs) -- revisit after the first run.
#
#          An earlier run against a prior assembly draft (job
#          6089385, different --fasta/--busco_lineages/work dir)
#          got through 30/31 processes then died on DIAMOND_BLASTX:
#          exit 143 (SIGTERM), still healthy at ~38GB RAM
#          mid-alignment when killed. Root cause, confirmed in the
#          pipeline's own conf/base.config: this process carries
#          label 'process_high', hard-capped at time = 16h on the
#          first attempt -- too short for a blastx search against
#          the 69.7GB reference proteomes DB. custom.config below
#          preemptively overrides just that one process's time/cpus
#          for this run too, since the same DB/assembly-scale issue
#          applies regardless of assembly version. NOTE: this v1.4
#          run uses a fresh WORKDIR (new assembly, new BASE path
#          below), so -resume has no cached steps to reuse here --
#          it's kept only so a future re-submission after a partial
#          failure of *this* run can resume cheaply.
####################################################################

set -euxo pipefail

module purge
module load Nextflow/26.04.4

###############################################################################
# USER SETTINGS
###############################################################################

# Everything the pipeline reads or writes lives under BASE, so all
# outputs land in one predictable place instead of being scattered
# across separate home/shared directories.
BASE=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/contamination/blobtoolkit_wobtusa_v1.4
SAMPLESHEET="${BASE}/samplesheet_woodsia_obtusa.csv"
OUTDIR="${BASE}/results"
WORKDIR="${BASE}/work"
TMPDIR="${BASE}/tmp"

mkdir -p "${OUTDIR}" "${WORKDIR}" "${TMPDIR}"

# Final assembly to analyse -- hifiasm primary contigs, pre-purging
# (same assembly used as input to purge_dups/purge_haplotigs).
# hifiasm only emits GFA; run scripts/datawrangling/GFAtoFASTA.sh
# first to produce this FASTA via `gfatools gfa2fa` from
# woodsia_obtusa_v1.4.asm.p_ctg.gfa (--primary mode naming has no
# "bp." infix, unlike default trio-free hifiasm output).
FASTA=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/assembly_drafts/wobtusa_hifi_v1.4/woodsia_obtusa_v1.4.asm.p_ctg.fa

# Taxon metadata
TAXON="Woodsia obtusa"

# no NCBI accession for this assembly yet (--accession option)
#ACCESSION="GCA_XXXXX"

# Databases (shared, group-readable copies from Amin's project dir --
# not duplicated here)
BUSCO_DB="/lisc/data/work/botany/diospyrosProj/Amin_tmp/blob_tool_kit/busco_db/v5/data/"
TAXDUMP="/lisc/data/work/botany/diospyrosProj/Amin_tmp/blob_tool_kit/taxdump_2026_04"
BLASTP="/lisc/data/work/botany/diospyrosProj/Amin_tmp/blob_tool_kit/blastp_blastx_db/reference_proteomes.dmnd"
BLASTX="/lisc/data/work/botany/diospyrosProj/Amin_tmp/blob_tool_kit/blastp_blastx_db/reference_proteomes.dmnd"
# NCBI nt mirror is dated and rotates -- 2026-05-27 (Amin's original)
# no longer exists; 2026-08-01 is the current snapshot as of this run.
BLASTN="/lisc/opt/mirror/ncbi/2026-08-01/nt.nal"

# BUSCO lineages to score. Woodsia obtusa is a fern, not a eudicot
# (Amin's eudicotyledons_odb12 was specific to his Diospyros run) --
# embryophyta_odb12 and viridiplantae_odb12 are both already
# pre-downloaded in BUSCO_DB above, no fern-specific odb12 lineage
# exists to add. Lineage names must match the extracted directory
# names under BUSCO_DB/lineages/ exactly (odb12, no ".2" suffix --
# the ".2" only appears in the source tarball filenames' date stamp,
# e.g. embryophyta_odb12.2025-07-01.tar.gz).
#
# bacteria_odb12/archaea_odb12 dropped: the pipeline's
# generate_config.py validates --busco_lineages against a
# taxonomy-derived mapping file for the taxon's own superkingdom
# (here: mapping_taxids-busco_dataset_name.eukaryota_odb12...txt,
# auto-selected since Woodsia obtusa is a Eukaryote) -- that file
# only lists lineages that are descendants of Eukaryota (confirmed:
# it contains eukaryota/embryophyta/viridiplantae but no
# bacteria/archaea entries), so requesting a different-superkingdom
# lineage hard-fails with "Invalid requested BUSCO lineage". This
# is how job 6211615 died on GENERATE_CONFIG. Contamination
# screening against bacteria/archaea is still covered by the
# blastn/blastx/blastp hits per contig, just not via BUSCO.
BUSCO_LINEAGES="eukaryota_odb12,embryophyta_odb12,viridiplantae_odb12"

###############################################################################
# SAMPLESHEET
###############################################################################
# One row: the same adapter-filtered, merged HiFi reads used for the
# hifiasm assembly and purge_dups, for read-depth/coverage mapping.
# datatype=pacbio + library_layout=SINGLE matches Amin's own working
# PacBio HiFi row (confirmed against his already-completed run).

cat > "${SAMPLESHEET}" <<EOF
sample,datatype,datafile,library_layout
woodsia_obtusa_hifi,pacbio,/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/data/merged_BAM/woodsia_obtusa_hifi_reads.filt.fastq.gz,SINGLE
EOF

###############################################################################
# PARAMS FILE
###############################################################################
# Same minimal params Amin's proven run used: align=true triggers the
# read-mapping/coverage step; use_work_dir_as_temp keeps intermediate
# files under WORKDIR instead of the default system temp.

cat > "${BASE}/params.yaml" <<EOF
align: true
use_work_dir_as_temp: true
EOF

###############################################################################
# CUSTOM PROCESS CONFIG
###############################################################################
# Override for DIAMOND_BLASTX only (see failure note above): more time
# per attempt than the pipeline's default 16h*task.attempt, and more
# of our 48 allocated cpus than the default 12*task.attempt, so it
# both has room to finish and runs faster. Nothing else touched --
# every other process ran fine under the defaults on the earlier
# (differently-configured) run.

cat > "${BASE}/custom.config" <<EOF
process {
    withName: 'DIAMOND_BLASTX' {
        cpus   = { 24 * task.attempt }
        time   = { 48.h * task.attempt }
    }
}
EOF

###############################################################################
# NEXTFLOW ENV
###############################################################################

export NXF_HOME="${BASE}/.nextflow_home"
export NXF_WORK="${WORKDIR}"
export NXF_TEMP="${TMPDIR}"
export TMPDIR="${TMPDIR}"

export NXF_SINGULARITY_CACHEDIR="${BASE}/singularity_cache"
mkdir -p "${NXF_SINGULARITY_CACHEDIR}"

###############################################################################
# RUN
###############################################################################

# -resume: no-op on this fresh WORKDIR (see NOTE above), kept so a
# re-submission after a partial failure of this run can resume cheaply
nextflow run sanger-tol/blobtoolkit \
    -r 0.10.2 \
    -profile singularity \
    -resume \
    -work-dir "${WORKDIR}" \
    -params-file "${BASE}/params.yaml" \
    -c "${BASE}/custom.config" \
    --input "${SAMPLESHEET}" \
    --outdir "${OUTDIR}" \
    --taxon "${TAXON}" \
    --fasta "${FASTA}" \
    --busco "${BUSCO_DB}" \
    --busco_lineages "${BUSCO_LINEAGES}" \
    --taxdump "${TAXDUMP}" \
    --blastp "${BLASTP}" \
    --blastx "${BLASTX}" \
    --blastn "${BLASTN}" \
    --image_format png \
    --publish_dir_mode copy

# finished
exit
