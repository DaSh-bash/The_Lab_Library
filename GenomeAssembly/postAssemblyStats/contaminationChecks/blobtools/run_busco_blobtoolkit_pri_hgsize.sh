#!/bin/bash

#SBATCH --job-name=busc_btk    ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=150G
#SBATCH --time=1-00:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL

####################################################################
# Author: Thomas Buchloh
# Date: Aug 2026
# Purpose: BUSCO completeness of the hifiasm_pri_hgsize assembly
#          across the 5 lineages the blobtoolkit contamination screen
#          uses (eukaryota/bacteria/archaea baseline + embryophyta/
#          viridiplantae for this taxon), for standalone blobtools
#          (see run_blobtools_manual.sh).
#
#          Fetched fresh from the online BUSCO database per lineage
#          (no --offline/--download_path), same as run_busco_pri_hgsize.sh
#          and the QC_post_assembly*.sh scripts, rather than Amin's
#          shared pre-downloaded BUSCO DB. That shared copy turned out
#          to be a stale dataset vintage (embryophyta_odb12: 2026
#          BUSCOs, created 2025-07-01) vs. the current online catalog
#          (embryophyta_odb12.2: 1658 BUSCOs) -- pinned to the .2
#          lineage names below (confirmed current via
#          `busco --list-datasets` as of 2026-08-27) so results here
#          are comparable to the standalone/QC BUSCO numbers instead
#          of silently scoring against a different marker set.
#
#          First attempt (job 6155407) OOM-killed on the 2nd lineage
#          (bacteria_odb12) at 64G, right after eukaryota_odb12 had
#          just finished fine -- looks like miniprot's genome index
#          for this ~5.3Gb assembly is the real memory cost, roughly
#          constant per lineage regardless of marker-set size, not
#          something that scales with how many BUSCOs are in a given
#          lineage. Bumped to 150G. The per-lineage skip-if-done check
#          below means a rerun doesn't redo eukaryota_odb12.
#
#          OUT_PATH below is the manual blobtools rebuild's run
#          directory. RUN_DIR must match the same constant in the
#          other 3 scripts of that pipeline (run_hifi_read_mapping.sh,
#          run_diamond_blastx_pri_hgsize.sh, run_blobtools_manual.sh)
#          -- change it in all 4 together, to a new suffix, for a
#          fresh run rather than overwriting this one.
####################################################################

set -euxo pipefail

module purge
module load BUSCO/6.1.0-foss-2023a
echo "BUSCO module version: ${EBVERSIONBUSCO}"

# set input and output file paths
GENOME_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm_v1.2
PRI=woodsia_obtusa.asm.p_ctg.fa
RUN_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/blobtoolkit_manual_pri_hgsize
OUT_PATH="${RUN_DIR}/busco"

LINEAGES=(eukaryota_odb12.2 bacteria_odb12.2 archaea_odb12.2 embryophyta_odb12.2 viridiplantae_odb12.2)

mkdir -p "$OUT_PATH"
# cd so BUSCO's default ./busco_downloads/ cache lands in scratch, not
# wherever sbatch was invoked from; fetched fresh from the online
# database each run, no local dataset copy kept (see purpose note above)
cd "$OUT_PATH"

for LINEAGE in "${LINEAGES[@]}"; do
    if [ -f "${OUT_PATH}/${LINEAGE}/run_${LINEAGE}/full_table.tsv" ]; then
        continue
    fi
    busco -i "$GENOME_DIR/$PRI" -o "$LINEAGE" --out_path "$OUT_PATH" \
        -m genome -l "$LINEAGE" -c "$SLURM_CPUS_PER_TASK"
done

# finished
exit
