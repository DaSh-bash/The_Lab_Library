#!/bin/bash
filename=""
#echo $filename
all_lines=$(cat $filename)
for line in $all_lines 
do
    #echo "$line" 
    genes=$(awk --field-separator=";" '{print $9}' makerrun3.all.maker.gff)
$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/RepeatMasker_Vanessa/GCA_905220365.1_ilVanCard2.1_genomic_chroms.fna.out | awk '/DNA/' |  wc -l)
    #count_TcM=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/RepeatMasker_Vanessa/GCA_905220365.1_ilVanCard2.1_genomic_chroms.fna.out | awk '/TcMar/' |  wc -l)
    #count_LINE=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/RepeatMasker_Vanessa/GCA_905220365.1_ilVanCard2.1_genomic_chroms.fna.out | awk '/LINE/' |  wc -l)
    #count_SINE=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/RepeatMasker_Vanessa/GCA_905220365.1_ilVanCard2.1_genomic_chroms.fna.out | awk '/SINE/' |  wc -l)
    #count_LTR=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/RepeatMasker_Vanessa/GCA_905220365.1_ilVanCard2.1_genomic_chroms.fna.out | awk '/LTR/' |  wc -l)
    #count_nonLTR=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/RepeatMasker_Vanessa/GCA_905220365.1_ilVanCard2.1_genomic_chroms.fna.out | awk '/NonLTR/' |  wc -l)
    #length_gene=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/Vanessa_MAKER/maker_run3/makerrun3.all.nofasta.gff | awk '$3=="gene" {sum+=$5-$4} END {print sum}')
    #count_rpt=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/Vanessa_MAKER/maker_run3/makerrun3.all.nofasta.repeats.uniq.gff | wc -l)
    #length_rpt=$(grep "$line" /proj/uppstore2017185/b2014034_nobackup/Dasha/Vanessa_MAKER/maker_run3/makerrun3.all.nofasta.repeats.uniq.gff | awk  '{SUM+=$6} END {print SUM}' ) 

    echo "$line	$genes$count_DNA	$count_TcM	$count_LINE	$count_SINE	$count_LTR	$count_nonLTR" #	$count_rpt	$length_rpt"
done
