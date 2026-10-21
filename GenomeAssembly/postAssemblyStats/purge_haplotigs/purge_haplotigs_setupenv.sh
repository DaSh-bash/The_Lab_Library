#!/bin/bash

####################################################################
# Author: Thomas Buchloh.
# Date: Aug 2026
# Purpose: One-time setup step for the purge_haplotigs pipeline
#          (run_purge_haplotigs_1_align_hist.sh,
#          run_purge_haplotigs_2_cov_purge.sh). Creates a conda env for
#          purge_haplotigs 1.1.3, which pulls in its own minimap2,
#          samtools, bedtools and R/ggplot2 as dependencies -- so the
#          pipeline scripts don't need any separate Lmod modules for
#          those. No Lmod module exists for purge_haplotigs itself.
#          https://bitbucket.org/mroachawri/purge_haplotigs
#
#          Not a SLURM job -- env creation is quick enough for a login
#          node. Re-run only if the env needs recreating.
####################################################################

set -euxo pipefail

module load Conda/Miniforge3

conda create -y -n purge_haplotigs-1.1.3 -c conda-forge -c bioconda purge_haplotigs=1.1.3

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate purge_haplotigs-1.1.3

# smoke-test the install against the tool's own bundled test data
purge_haplotigs test

# finished
exit
