#!/bin/bash -l

#SBATCH -A snic2021-5-20
#SBATCH -p core
#SBATCH -n 8
#SBATCH -t 02:00:00
#SBATCH -J linkage_map_vanessa_orthofinder
#SBATCH -e linkage_map_vanessa_orthofinder.error
#SBATCH --mail-user karin.nasvall@ebc.uu.se
#SBATCH --mail-type=ALL

module load bioinfo-tools OrthoFinder/2.5.2

#working directory is where the protein sequences are. This is also where the results dir will be placed unless other spec (-o) and -n append a name to out dir
WORK_DIR=/proj/uppstore2017185/b2014034_nobackup/Karin/link_map_vanessa/output/10a_orthofinder_220103

cd $WORK_DIR

orthofinder.py -f $WORK_DIR
