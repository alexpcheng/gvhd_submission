#!/usr/bin/env RScript
# Title: [ENTER TITLE]
# Authors: [ENTER AUTHORS]
# Brief description: [ENTER DESCRIPTION]

rm(list=ls())
save_file <-FALSE
# libraries -------------------------------------------------------
library(data.table)
library(ggplot2)
library(RColorBrewer)
library(pals)
library(ggpubr)
library(stringr)
library(dplyr)
library(ggsci)
# Functions -------------------------------------------------------

tissues_of_origin <- fread('tables/SAMPLE_INFO_MASTER_TABLE.csv')

tissue_hex <- data.frame(fread('/workdir/apc88/GVHD/tissue_hex_new.txt'))
tissue_hex$tissue<- factor(tissue_hex$tissue,
                             levels = c("hema. stem cell/progenitor", "lym. progenitor", "mye. progenitor",
                                        "Tcell", "NKell", "Bcell", "erythroblast",
                                        "eosonophil", "neutrophil", "dendritic",
                                        "monocyte", "macrophage",
                                        "spleen",
                                        "bladder",
                                        "skin",
                                        "kidney",
                                        "liver",
                                        "pancreas",
                                        "intestine"))
tissue_hex <- tissue_hex[order(tissue_hex$tissue), ]
tissue_hex$hex <- as.vector(ggthemes::tableau_color_pal(palette = 'Tableau 20')(19))

tissue_porportion_melt <- tissues_of_origin
tissue_porportion_melt$hema_sc_BM <- tissue_porportion_melt$progenitor_BM+tissue_porportion_melt$hema_sc_BM

tissue_porportion_melt$myeloid_progenitor <- tissue_porportion_melt$macro_progenitor+tissue_porportion_melt$myeloid_progenitor

tissue_porportion_melt$total_cfDNA <- (1-tissue_porportion_melt$microbial_fraction)*
  tissue_porportion_melt$qubit*tissue_porportion_melt$elution_volume/tissue_porportion_melt$plasma_volume*(tissue_porportion_melt$microbial_control_input*tissue_porportion_melt$micorbial_control_input_concentration/(tissue_porportion_melt$microbial_control_qubit*tissue_porportion_melt$`microbial_control elution`))

tissue_porportion_melt <- tissue_porportion_melt[,c("hema_sc_BM", "lymphoid_progenitor", "myeloid_progenitor",
                                                    "TCell", "NKCell", "BCell", "erythroblast",
                                                    "eosonophil", "neutrophil", "dendritic",
                                                    "monocyte", "macrophage",
                                                    "spleen",
                                                    "bladder",
                                                    "skin",
                                                    "kidney",
                                                    "liver",
                                                    "pancreas",
                                                    "colon", 
                                                    "cluster_id", 
                                                    "patient_id",
                                                    "microbial_fraction",
                                                    "days_post_HCT",
                                                    "total_cfDNA")]

tissue_porportion_melt <- melt(tissue_porportion_melt, id.vars = c("cluster_id", "patient_id", "microbial_fraction", "days_post_HCT", "total_cfDNA"))


tissue_porportion_melt$variable <- factor(tissue_porportion_melt$variable,
                                          levels = c("macrophage", "monocyte", "dendritic",
                                                     "eosonophil", "neutrophil",
                                                     "erythroblast",
                                                     "BCell", "NKCell", "TCell",
                                                     "hema_sc_BM", "lymphoid_progenitor", "myeloid_progenitor",
                                                     "spleen",
                                                     "bladder",
                                                     "skin",
                                                     "kidney",
                                                     "liver",
                                                     "pancreas",
                                                     "colon"))
                                          

dd <- tissue_porportion_melt[tissue_porportion_melt$patient_id==3 | tissue_porportion_melt$patient_id==17, ]

ff <- dd[dd$patient_id==3, ]
ff <- ff[ff$days_post_HCT==86, ]
ff <- ff[order(ff$value*ff$total_cfDNA, decreasing = TRUE), ]
dd$variable <- factor(dd$variable, 
                      levels = ff$variable)

pdf(file = 'figures/Tisue_prop_by_TP.pdf', width = 50/25.4, height = 45/25.4)
ggplot(data = dd[dd$days_post_HCT<100, ])+
  geom_area(aes(x=days_post_HCT, y=value*total_cfDNA, fill=variable), color = 'black', size=0.1)+
  facet_wrap(vars(patient_id), nrow=2)+theme_classic()+
  scale_fill_manual(values = tissue_hex$hex)+
  xlab("Days since transplant")+
  ylab("Tissue cfDNA concentration")+
  theme(strip.background = element_blank(),
        strip.text = element_blank(),
        legend.position = "none",
        axis.text = element_text(family = "Helvetica", size = 6),
        axis.title = element_text(family = "Helvetica", size = 8))
dev.off()
