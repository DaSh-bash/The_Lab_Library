In this folder there are scripts to run 
OrthoFinder version OrthoFinder/2.5.2


We downloaded protein fasta files from Lepbase and NCBI 210621

Junonia_coenia_Jc_v2.proteins.fa.gz
Bicyclus_anynana_BaGv2.proteins.fa.gz
Danaus_plexippus_v3_-_proteins.fa.gz			 
GCF_002938995.1_ASM293899v1_protein.faa.gz		 
GCF_902806685.1_iAphHyp1.1_protein.faa.gz		 
GCF_905163445.1_ilParAegt1.1_protein.faa.gz		 		 
Heliconius_erato_lativitta_v1_-_proteins.fa.gz		 
Heliconius_melpomene_melpomene_Hmel2.5.proteins.fa.gz

cp /proj/uppstore2017185/b2014034_nobackup/Dasha/Vanessa_Annotation_Curation/08_FilterRound2/makerrun3.all.maker.rename.proteins.AED50.eAED50.long50.norepeatdomainwZF.noverlap.noW.fasta ./Vanessa_cardui.fa


scripts/10_select_and_unzip_fasta.sbatch was used to unzipped and rename the files to species_name.fa
 
scripts/10_filter_transcript.sh (one-liners) filter only primary transcripts (one transcript per unique gene name)

scripts/10_orthofinder_220103.sbatch running the analysis and 

scripts/10_orthofinder_rootedtree.sbatch for rerunning final analysis with guide tree. 

scripts/Orthofinder_result.R is for visualising summary results.

The trees with duplications are visualised with FigTree

All output files are stored on Uppmax. In the Results_Jan07-folder the main result files. In the selected_output folder there are the summary results and some output files used in downstream analysis. Large folders such as Resolved_Gene_Trees, Orthogroup_Sequences, and Single_Copy_Orthologue_Sequences are not here (to many files), stored on Uppmax.

