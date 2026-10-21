#!/bin/bash

#SBATCH --job-name=diamx_pg    ### named job, limit 8 chars
#SBATCH --output=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.out
#SBATCH --error=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/logs/%j.%x.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G
#SBATCH --time=2-00:00:00
#SBATCH --mail-user=thomas.buchloh@univie.ac.at
#SBATCH --mail-type=BEGIN,END,FAIL

####################################################################
# Author: Thomas Buchloh
# Date: Aug 2026
# Purpose: Diamond blastx of the hifiasm_pri_hgsize assembly against
#          Amin's reference proteomes DB, for standalone blobtools
#          taxonomy hits (see run_blobtools_manual.sh).
#
#          Same diamond command/params the sanger-tol/blobtoolkit
#          Nextflow pipeline used for the other (now-deleted)
#          assembly, incl. the exact --outfmt column layout blobtools
#          expects by default (1=qseqid,2=staxids,3=bitscore,
#          5=sseqid,10=qstart,11=qend,14=evalue) -- confirmed against
#          `blobtools add --help` in the cached blobtoolkit:4.4.6
#          image. Run directly on the whole assembly in one job
#          rather than Nextflow's per-chunk parallelism -- diamond
#          multithreads a single large query fine on its own, and
#          skipping the chunk/unchunk step also sidesteps whatever
#          was dropping most hits during that pipeline's own
#          chunk-to-contig rollup.
#
#          Time/mem sized off the previous run: diamond blastx
#          against this same DB took ~13h on a similarly-sized
#          (~5.3Gb) assembly even with 24 cpu; requesting more
#          headroom here (32 cpu, 2 days) since there's no Nextflow
#          per-process attempt/retry to fall back on if it runs long.
#
#          OUT_DIR below is the manual blobtools rebuild's run
#          directory. RUN_DIR must match the same constant in the
#          other 3 scripts of that pipeline (run_hifi_read_mapping.sh,
#          run_busco_blobtoolkit_pri_hgsize.sh, run_blobtools_
#          manual.sh) -- change it in all 4 together, to a new
#          suffix, for a fresh run rather than overwriting this one.
####################################################################

set -euxo pipefail

module purge
module load DIAMOND

# set input and output file paths
FASTA=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/hifiasm_v1.2/woodsia_obtusa.asm.p_ctg.fa
DB=/lisc/data/work/botany/diospyrosProj/Amin_tmp/blob_tool_kit/blastp_blastx_db/reference_proteomes.dmnd
TAXID=29611
RUN_DIR=/lisc/data/scratch/botany/TBuchloh_WickettLab/wobtusa/genome_assembly/output/blobtoolkit_manual_pri_hgsize
OUT_DIR="${RUN_DIR}/diamond_blastx"
OUT_FILE=woodsia_obtusa.asm.p_ctg.blastx.txt

mkdir -p "$OUT_DIR/tmp"
cd "$OUT_DIR"

diamond blastx \
    --threads "$SLURM_CPUS_PER_TASK" \
    --db "$DB" \
    --query "$FASTA" \
    --outfmt 6 qseqid staxids bitscore qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore \
    --taxon-exclude "$TAXID" \
    --evalue 1.0e-25 --max-target-seqs 10 --max-hsps 1 --tmpdir ./tmp/ \
    --out "$OUT_FILE" \
    --log

# finished
exit
