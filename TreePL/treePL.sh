#!/bin/bash

#SBATCH --job-name=treePL_opt ### named job, limit 8 chars
#SBATCH --output=output/out/%x.%j.out   ### path for output file
#SBATCH --error=output/err/%x.%j.err    ### path for error file
#SBATCH --cpus-per-task=16 ### number of cpus assigned to job if ntask=1
#SBATCH --mem=5G   ### RAM available for the script
#SBATCH --time=1:00:00   ### time limit (dd-hh:mm:ss) 
#SBATCH --mail-user=julia.mcclafferty@univie.ac.at    ### email to receive script notifications
#SBATCH --mail-type=BEGIN,END,FAIL    ### email notification types

# load module 
module load treePL

###needs to be run multiple times to optimize make sure to run prime first (see config.txt). 
##View cv.out and select lowest chisq value for final smoothing parameter (run more than once to test and confirm). 
#If recieving an error in .out file (might want to try different opt=VALUE or optAD=VALUE. Add plus 1 to value in config until error does not appear. 

# run treePL
treePL /<your>/<path>/config.txt
