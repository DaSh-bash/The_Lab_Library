#!/bin/bash

####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: One-time setup step for filter_hifiAdapterfilt.sh. Copies the
#          HiFiAdapterFilt adapter-vector BLAST database (pacbio_vectors_db)
#          into this repo instead of relying on the module's own copy.
#
#          The module's copy (under /lisc/opt/sw/software/HiFiAdapterFilt/)
#          fails to load with "BLAST Database error: Database memory map
#          file error" -- confirmed reproducible even interactively via
#          blastdbcmd, and confirmed to be a filesystem issue specific to
#          that install rather than corrupt data (a byte-identical copy
#          elsewhere loads fine). Since it's a centrally-managed module we
#          can't fix it in place, so filter_hifiAdapterfilt.sh instead
#          prepends this copy's directory onto PATH before calling
#          hifiadapterfilt.sh, which finds its DB via the first PATH entry
#          containing "HiFiAdapterFilt/DB".
#
#          Not a SLURM job -- this just copies ~50KB of files and can be
#          run directly on a login node. Re-run this if the DB ever needs
#          refreshing (e.g. after a HiFiAdapterFilt module update).
####################################################################

set -euxo pipefail

SRC_DIR=/lisc/opt/sw/software/HiFiAdapterFilt/3.0.0-gompi-2024a/DB
DEST_DIR=/lisc/data/work/botany/TBuchloh_WickettLab/woodsia_obtusa/genome_assembly/scripts/datawrangling/BAMtoFASTQ/HiFiAdapterFilt/DB

mkdir -p "$DEST_DIR"
cp "$SRC_DIR"/pacbio_vectors_db* "$DEST_DIR/"

# finished
exit
