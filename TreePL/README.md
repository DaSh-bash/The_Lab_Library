Hi Yall. These are my notes on treePL. 

Since ASTRAL Pro3 has CASTLES, you can use that tree as input for treePL since the branch lengths are in substitutions per site. However, the input tree for treePL needs to be strict newick (the brackets [] need to be removed. I did this by hand because my tree was small, but this can be also be coded easily.) 
The tree must be rooted with --root flag, and the subsitutions per site estimation can be improved by adding the --genelength flag followed by the average length of alignment, (see AMAS). 

TreePL also requires the total number of sites. Use get_sites.sh to find the total number. And you can also use get_gene_lengths.sh which has one-liners if you want to get the average length of alignments for ASTRAL.

- Julia 😎 
