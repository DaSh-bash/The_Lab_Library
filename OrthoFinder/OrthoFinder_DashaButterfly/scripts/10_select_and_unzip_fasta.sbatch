#!/bin/bash -l

#SBATCH -A snic2021-5-20
#SBATCH -p core
#SBATCH -n 1
#SBATCH -t 01:00:00
#SBATCH -J linkage_map_vanessa_orthofinder_prep
#SBATCH -e linkage_map_vanessa_orthofinder_prep.error
#SBATCH --mail-user karin.nasvall@ebc.uu.se
#SBATCH --mail-type=ALL


#script to change names and copy protein files to input directory for orthofinder
INPUT_DIR=/proj/uppoff2020002/private/group_member_backups/KarinN/projects/2019_04_linkmap_vanessa/data/protein_CDS/

DIR_ORTHOFINDER=/proj/uppstore2017185/b2014034/nobackup/Karin/link_map_vanessa/output/10_orthofinder/
mkdir $DIR_ORTHOFINDER

for file in $(cat list_nymphalid_genomes.txt)
do
cp $INPUT_DIR/$file $DIR_ORTHOFINDER/
gunzip $DIR_ORTHOFINDER/$file
done
wait

cd $DIR_ORTHOFINDER/

mv Bicyclus_anynana_BaGv2.proteins.fa_-_proteins.fa Bicyclus_anynana.fa
mv Junonia_coenia_Jc_v2.proteins.fa Junonia_coenia.fa
mv Danaus_plexippus_v3_-_proteins.fa Danaus_plexippus.fa	 
#mv Melitaea_cinxia_-_proteins.fa Melitaea_cinxia.fa
mv GCF_002938995.1_ASM293899v1_protein.faa Vanessa_tameamea.fa
mv GCF_902806685.1_iAphHyp1.1_protein.faa Maniola_hyperantus.fa
mv GCF_905163445.1_ilParAegt1.1_protein.faa Pararge_aegeria.fa
mv Heliconius_erato_demophoon_v1_-_proteins.fa Heliconius_erato_demophoon.fa
mv Heliconius_erato_lativitta_v1_-_proteins.fa Heliconius_erato_lativitta.fa
mv Heliconius_melpomene_melpomene_Hmel2.5.proteins.fa Heliconius_melpomene_melpomene.fa

