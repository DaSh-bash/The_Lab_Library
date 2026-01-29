while IFS=$'\t' read -r -a myArray
do
	for line in "${myArray[3]}"
	do
		#echo "$line"
		#echo "$(awk '/a/ {print $1}' a="$line"  Vcardui_Orthogroups.tsv)"
		echo "$(grep "$line" Vcardui_Orthogroups.tsv | awk '{print $1}')"  
		#begin="${myArray[1]}"
		#end="${myArray[2]}"
		#echo "$(awk '$5 == a && $6>b && $7<c {print}'  a="$line" b="$begin" c="$end" repeat_annot_test.out | wc -l)"

		#count_gain=$(awk '$1 == a && $2>b && $3<c {print}'  a="$line" b="$begin" c="$end" $REP | wc -l)
		#length_rpt=$(awk '$5 == a && $6>b && $7<c {sum+=$7-$6} END {print sum}'  a="$line" b="$begin" c="$end" $REP)


		#echo "$line $begin $end $count_gain"    #$length_rpt $count_SINE $length_SINE $count_DNA $length_DNA $count_TcMar $length_TcMar $count_LINE $length_DNA $count_LTR $length_LTR $count_nonLTR $length_nonLTR"

	done
done < Gained_Gene_Locations_Simplified_sorted.gff
