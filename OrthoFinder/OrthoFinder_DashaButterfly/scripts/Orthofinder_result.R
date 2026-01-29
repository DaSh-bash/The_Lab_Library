
setwd("~/Desktop/Proj_vanessa_assembly/output/10a_orthofinder/")
ortho_stat <- read.csv2("../selected_output/Statistics_PerSpecies.csv", dec=".")
ortho_stat

#plot
library(ggplot2)
library(tidyr)

ortho_stat_long <- pivot_longer(ortho_stat, cols=c("Number.of.species.specific.orthogroups", "Number.of.genes.in.species.specific.orthogroups", "Number.of.genes"), names_to = "variable", values_to = "value")
ortho_stat_long

#get the species in the same order as in the tree
#dx$group <- factor(dfx$group, levels = c("SLG", "BA"))
ortho_stat_long$Species <- factor(ortho_stat_long$Taxa, levels = c("Heliconius_erato_lativitta", 
                                                                      "Heliconius_melpomene_melpomene", 
                                                                      "Vanessa_tameamea",
                                                                      "Vanessa_cardui",
                                                                      "Junonia_coenia",
                                                                      "Bicyclus_anynana",
                                                                      "Pararge_aegeria",
                                                                      "Maniola_hyperantus",
                                                                      "Danaus_plexippus"))
                                                                      

strip_labels <- c("Species specific genes", "Species specific orthogroups", "Total number of genes")
names(strip_labels) <- c("Number.of.genes.in.species.specific.orthogroups","Number.of.species.specific.orthogroups", "Number.of.genes")


ortho_stat_long$variable_f <- factor(ortho_stat_long$variable, 
                                     levels=c("Number.of.genes",
                                              "Number.of.species.specific.orthogroups",
                                              "Number.of.genes.in.species.specific.orthogroups"
                                              ))
#default colours
ggplot(ortho_stat_long, 
       aes(Species, 
           y = value, 
           fill=variable_f)) +
  geom_bar(stat = "identity") +
  coord_flip() + 
  facet_grid(~variable_f,
             labeller = labeller(variable_f=strip_labels),
             scales = "free_x") +
  theme(panel.background = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(size = 12),
        axis.line = element_line(size = 0.2, colour = "grey"),
        axis.ticks = element_line(size = 0.2, colour = "grey"),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none"
  )

ggplot(ortho_stat_long, 
       aes(Species, 
           y = value)) +
  geom_bar(stat = "identity") +
  coord_flip() + 
  facet_grid(~variable_f,
             labeller = labeller(variable_f=strip_labels),
             scales = "free_x") +
  theme(panel.background = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(size = 12),
        axis.line = element_line(size = 0.2, colour = "grey"),
        axis.ticks = element_line(size = 0.2, colour = "grey"),
        axis.text.x = element_text(size = 12),
        axis.text.y = element_text(size = 12),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        legend.position = "none"
  )

