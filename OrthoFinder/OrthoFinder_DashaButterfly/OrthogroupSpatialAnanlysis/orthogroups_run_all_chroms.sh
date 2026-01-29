#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo
#   echo "Script calculates number and length of repeats from RepeatMasker .out file"
   echo "Syntax: bash repeats_run_all_chroms.sh [-h] <input_ortho> <input_index>"
   echo
   echo "Options:"
 #  echo "       <window_size>           Length of window (in base pairs)"
   echo "       <input_repeats>         Input file to read. Should be output file from RepeatMasker (.out)"
   echo "       <input_index>           Index file for whole genome (or any numbers of chromosomes) (.fai)"
   echo "       -h                      Print this help"
   #echo "v     Verbose mode."
   #echo "V     Print software version and exit."
   echo
   echo "Created by DSh, 2021"
}

################################################################################
# Main program                                                                 #
################################################################################
# Process the input options                                                    #
################################################################################
# Get the options
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
     \?) # incorrect option
         echo "Error: Invalid option"
         exit;;
   esac
done


################################################################################
# Main script                                                                  #
################################################################################
INDEX=$2

echo "chrom "$(awk 'ORS=NR%83?" ":RS' orthogroup.ref.list)" "

while IFS=$'\t' read -r -a myArray
do
	for line in "${myArray[0]}" 
	do
		len="${myArray[1]}"
		windows_num_tmp=$(expr $len / $1 )
		windows_num=$(expr $windows_num_tmp + 1)
		bash orthogroup_counter.sh $line $1 > $line.orthogr.count.out
		echo "$line "$(awk '{print $2}' $line.orthogr.count.out | awk 'ORS=NR%83?" ":RS' )" "
		
		#wait
	done
done < "$2" 


