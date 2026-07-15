# Author: Thomas Buchloh
# Date: Feb. 2026

# script to generate a list of OrthoGroups, from the Orthogroups.tsv file, which have more than 4 spp represented. 
# output is a .tsv file with the filtered orthogroups listed for use in selecting Orthogroups for downstream analyses (e.g., alignment, phylogenetic analyses, etc.)

## set your working directory to the location of the Orthogroups.tsv file. Make sure to adjust this path to your specific directory.
#setwd("/Users/tbuchloh/Dropbox/2.Dissertation/Projects/UWien/meiosis_WGD_angiosperms/scripts/orthofinder/cleaning")

## read in data
df <- read.delim("Orthogroups.tsv") # a wrapper for read.table() with arguments for .tsv files
# str(df)

## loop through orthogroups and keep only those with more than 4 taxa
# replace "" with NA
df[df == ""] <- NA

# loop and count
cols <- ncol(df)
df_spp4 <- df[rowSums(!is.na(df[,2:cols])) >= 4,] # keep orthogroups with 4 or more taxa
rm(df)
df_spp4_clean <- df_spp4[nchar(df_spp4$Orthogroup) <= 9,] # remove odd-ball rows that were not orthogroups
rm(df_spp4)

df_spp4_clean[is.na(df_spp4_clean$Orthogroup),]

# clean .tsv to only keep the orthogroups with more than 4 taxa
df_spp4_clean[is.na(df_spp4_clean)] <- "" # replace NAs
write.table(
  df_spp4_clean,
  file = "Orthogroups_with4ormoretaxa.tsv",
  sep = "\t",          # Specify tab as the separator
  row.names = FALSE,   # Omit row names
  quote = FALSE        # Prevent surrounding strings with quotes
)

