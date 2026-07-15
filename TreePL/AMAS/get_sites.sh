#!/bin/bash
#SBATCH --job-name=get_sites  ### named job, limit 8 chars
#SBATCH --output=output/out/%x.%j.out   ### path for output file
#SBATCH --error=output/err/%x.%j.err    ### path for error file
#SBATCH --cpus-per-task=1 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=80G   ### memory available for the script (i used 80G)
#SBATCH --time=4:00:00   ### time limit (hh:mm:ss) 
#SBATCH --mail-user=julia.mcclafferty@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

# download the scripts for AMAS and put on lisc, then run each python script as command.
# produce summary.txt
/lisc/data/scratch/botany/mcclafferty/AMAs/AMAS/amas/AMAS.py summary -i /lisc/data/scratch/botany/mcclafferty/schiedea/trimal/backtrans/*.fna -f fasta -d dna

# get total num of sites for treePL config.txt : will be output in get_sites.txt
awk 'NR==1 {for(i=1;i<=NF;i++) if($i=="Alignment_length") c=i; next} {sum += $c} END {print sum}' summary.txt > get_sites.txt
