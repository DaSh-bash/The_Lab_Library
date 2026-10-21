#!/bin/bash
#
### QC for assemblies_16 — direct hifiasm output (pre-purge), both
### haplotypes. Same structure as QC_post_assembly_15.slrm.
###
### Array is per-SAMPLE (0-9), matching hifiasm16.slrm's array exactly, so
### this can be --dependency=aftercorr'd against it for true per-sample
### pipelining. Which haplotype comes from the $HAP environment variable
### (sbatch --export=HAP=hap1 / HAP=hap2) — submitted TWICE, once per
### haplotype. See purge_haplotigs16.slrm for why this replaced an earlier
### combined array=0-19 design (10->20 fan-out breaks aftercorr's strict
### per-index correspondence with the 10-task hifiasm16 array).
### Each (sample, haplotype) writes to its own ${base}_${HAP} subdirectory
### within ONE shared QC_DIR (post_assembly_16), so extract_to_table.py
### naturally produces one table with both haplotypes as separate rows
### (assembly name = "${base}_${HAP}"), instead of needing four separate
### QC dirs/tables.
###
### Fasta path matches purge_haplotigs16.slrm's own gfa->fasta output
### exactly (assemblies_16/${base}/${HAP}/${base}_${HAP}.fasta) — both
### scripts are triggered together via aftercorr on hifiasm16 completion,
### so both independently converting the SAME gfa to the SAME fasta path in
### parallel would race exactly like it did for assemblies_15 (see
### purge_haplotigs15.slrm / QC_post_assembly_15.slrm comments — that race
### corrupted caput_10G_merged's BAM earlier this session). Skip-if-exists +
### atomic temp-file-then-mv avoids that regardless of which job's write
### wins.

#SBATCH --job-name=QC_post_assembly_16
#SBATCH --array=0-9
#SBATCH --cpus-per-task=16
#SBATCH --mem=100GB
#SBATCH --partition=basic
#SBATCH --constraint=amd
#SBATCH --mail-type=END,FAIL
#SBATCH --time=0-04:00:00
#SBATCH --no-requeue
#SBATCH --output=/lisc/data/scratch/botany/aiden/LOG/gen_assembl/%x-%A_%a.out
#SBATCH --error=/lisc/data/scratch/botany/aiden/LOG/gen_assembl/%x-%A_%a.err

# --constraint=amd: gfatools/0.5-GCC-14.3.0 was built with -march=native on an
# AMD build node; gfa2fa segfaults/produces corrupt output on this cluster's
# Intel nodes (node-b*). Pin to AMD until the module gets rebuilt portably.

set -eo pipefail

echo "Start time is: $(date)"
START_TIME=$(date +%s)

GenomeDIR=/lisc/data/scratch/botany/aiden/gen_assembl/assemblies_16
OutDIR=/lisc/data/scratch/botany/aiden/gen_assembl/qc/post_assembly_16

mkdir -p $GenomeDIR
mkdir -p $OutDIR

SAMPLES=(bourg_13E brach_4C_merged caput_10G_merged conco_5E dasyl_2K makoy_6D_merged punct_14E_merged ramir_7F_merged rolan_9F xerog_11H_merged)

base=${SAMPLES[$SLURM_ARRAY_TASK_ID]}
HAP=${HAP:?ERROR: \$HAP must be set to hap1 or hap2 (sbatch --export=HAP=hap1)}
[[ "$HAP" == "hap1" || "$HAP" == "hap2" ]] || { echo "ERROR: \$HAP must be hap1 or hap2, got: $HAP"; exit 1; }
SAMPLENAME="${base}_${HAP}"

Genome="$GenomeDIR/${base}/${base}.bp.${HAP}.p_ctg.gfa"

[[ -s "$Genome" ]] || { echo "ERROR: missing GFA: $Genome"; exit 1; }

echo "Array task ID: $SLURM_ARRAY_TASK_ID"
echo "Processing: ${SAMPLENAME}"
echo "Input: $Genome"

echo "------------------------------------------------------------"
echo "GFATools: Basic stats and .gfa to .fasta conversion"
echo "------------------------------------------------------------"

module load gfatools/0.5-GCC-14.3.0

echo "Running GFATools for ${SAMPLENAME}..."

SAMPLE_OUT="${OutDIR}/${SAMPLENAME}"
mkdir -p $SAMPLE_OUT/{gfatools,quast}

gfatools stat "${Genome}" > $SAMPLE_OUT/gfatools/${SAMPLENAME}_gfa_stats.txt

HAPDIR="$GenomeDIR/${base}/${HAP}"
mkdir -p "$HAPDIR"
FASTA="$HAPDIR/${SAMPLENAME}.fasta"

if [[ -s "${FASTA}" ]]; then
    echo "[SKIP] FASTA already exists: ${FASTA}"
else
    TMP_FASTA="${FASTA}.tmp.${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
    gfatools gfa2fa "${Genome}" > "${TMP_FASTA}"
    mv -f "${TMP_FASTA}" "${FASTA}"
fi

if [[ ! -s "$FASTA" ]]; then
    echo "ERROR: FASTA file is empty!"
    exit 1
fi

echo "Finished GFATools stats and conversion for ${SAMPLENAME}"

module unload gfatools/0.5-GCC-14.3.0

###############################################################################
### Sanity check with SeqKit
###############################################################################

echo "Running seqkit stats..."

module load SeqKit/2.13.0

seqkit stats "$FASTA" > "$SAMPLE_OUT/${SAMPLENAME}_seqkit_stats.txt"

max_len=$(awk 'NR==2 {gsub(",", "", $NF); print $NF}' "$SAMPLE_OUT/${SAMPLENAME}_seqkit_stats.txt")

if (( max_len < 500 )); then
    echo "ERROR: No contigs >= 500 bp. Stopping."
    exit 1
fi

echo "Finished SeqKit stats for ${SAMPLENAME}"
echo "Max contig length: $max_len"

module unload SeqKit/2.13.0

###############################################################################
### Running QUAST
###############################################################################

echo "------------------------------------------------------------"
echo "QUAST: assembly quality assessment"
echo "------------------------------------------------------------"
module load QUAST/5.3.0-gfbf-2023b

mkdir -p "${SAMPLE_OUT}/quast"
cd "${SAMPLE_OUT}/quast"

echo "Running QUAST for ${SAMPLENAME}..."

quast -o "${SAMPLE_OUT}/quast" \
  --eukaryote \
  --threads "${SLURM_CPUS_PER_TASK}" \
  "$FASTA"

echo "Finished QUAST for ${SAMPLENAME}"

module unload QUAST/5.3.0-gfbf-2023b

###############################################################################
### running BUSCO
###############################################################################

echo "------------------------------------------------------------"
echo "BUSCO: assembly completeness assessment"
echo "------------------------------------------------------------"

module load BUSCO/6.0.0-foss-2023a
busco -v

mkdir -p "${SAMPLE_OUT}"
cd "${SAMPLE_OUT}"
mkdir -p ${SAMPLE_OUT}/busco_downloads

ODB="/lisc/data/scratch/botany/aiden/gen_assembl/busco_database/poales_odb12"

export BUSCO_CONFIG_FILE="${SAMPLE_OUT}/busco_config.ini"

echo "Running BUSCO for ${SAMPLENAME}..."

busco \
    -i $FASTA \
    -f \
    -c $SLURM_CPUS_PER_TASK \
    -l ${ODB} \
    -m genome \
    --miniprot \
    --offline \
    --opt-out-run-stats \
    --download_path ${SAMPLE_OUT}/busco_downloads \
    -o ${SAMPLENAME}_busco

echo "Cleaning BUSCO temporary files..."

cd $SAMPLE_OUT

find $SAMPLE_OUT -depth -type d -name "run_poales_odb12" -exec rm -rf {} +
find $SAMPLE_OUT -depth -type d -name "busco_downloads" -exec rm -rf {} +
find $SAMPLE_OUT -depth -type d -name "tmp" -exec rm -rf {} +
find $SAMPLE_OUT -depth -type d -name "logs" -exec rm -rf {} +

module unload BUSCO/6.0.0-foss-2023a

echo "Finished BUSCO for ${SAMPLENAME}"
echo "End time is: $(date)"
END_TIME=$(date +%s)

TOTAL_TIME_HOURS=$(awk -v s="$START_TIME" -v e="$END_TIME" 'BEGIN{printf "%.2f", (e-s)/3600}')
echo "Total runtime: ${TOTAL_TIME_HOURS} hours"
