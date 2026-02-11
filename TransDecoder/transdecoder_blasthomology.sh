#!/bin/bash

#SBATCH --job-name=1sampletransdecoder  ### named job, limit 8 chars
#SBATCH --output=output/out/%x.%j.out   ### path for output file
#SBATCH --error=output/err/%x.%j.err    ### path for error file
#SBATCH --cpus-per-task=##  ### number of cpus assigned to job if ntask=1
#SBATCH --mem=##G   ### memory available for the script
#SBATCH --time=##:00:00   ### time limit (hh:mm:ss) 
#SBATCH --mail-user=##@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

#load modules
module load Conda
conda activate /lisc/data/scratch/botany/mcclafferty/transdecoder_env #made a conda environment because I had an issue with the ver. transdecoder Lisc had
module load R
module load BLAST+
#exit the slurm script if a command fails
set -e

#transdecoder output dir & input dir
OUTPUTDIR=/lisc/data/scratch/botany/mcclafferty/schiedea/transdecoder/TransDecoder_Out
INPUTDIR=/lisc/data/scratch/botany/mcclafferty/schiedea/transdecoder
#directory with custom blast index
DBDIR=/lisc/data/work/botany/mcclafferty/Phytozome_eudicotsDB

#blast index name
DBNAME=Phytozome_eudicotsDB

#local cache for running blast on lisc
DBCACHE=$(lisc_localcache $DBDIR)

#run TransDecoder
TransDecoder.LongOrfs -t samplename.fasta -O $OUTPUTDIR
TRANSDECODER_DIR=samplename.fasta.transdecoder_dir
cp -r "$OUTPUTDIR/$TRANSDECODER_DIR/" "$TMPDIR/"
blastp -query "$TMPDIR/$TRANSDECODER_DIR/longest_orfs.pep" \
	-db "$DBCACHE/$DBNAME" \
	-max_target_seqs 1 \ # can select # of target sequences, but I think transdecoder will just use best match ...
	-outfmt 6 \
	-evalue 1e-5 \
	-num_threads  > "$TMPDIR/$TRANSDECODER_DIR/samplename_blastp.outfmt6" #fill in # of threads 
#copy back to working directory and integrate blast results into coding region selection
cp "$TMPDIR/$TRANSDECODER_DIR/samplename_blastp.outfmt6" "$OUTPUTDIR/$TRANSDECODER_DIR/" #fill in your sample name here

#jump to the output directory to run next step
pushd $OUTPUTDIR 

#run TransDecoder.Predict to integrate sequences with blast homology 
TransDecoder.Predict -t "$INPUTDIR/samplename.fasta" --retain_blastp_hits "$OUTPUTDIR/$TRANSDECODER_DIR/samplename_blastp.outfmt6"

# delete temporary directory
rm -rf $TMPDIR
