#!/usr/bin/env RScript
# Title: cfDNA_blood_and_conc_by_TP.R
# Authors: Alexandre Pellan Cheng
# Brief description: cell-free DNA dynamics early in Tx

library(data.table)
library(ggplot2)

sample_info <- fread('tables/SAMPLE_INFO_MASTER_TABLE.csv', data.table = FALSE)

blood <- c("macrophage", "BCell", "TCell", "monocyte", "NKCell", "dendritic", 
           "eosonophil", "erythroblast", "neutrophil", "progenitor_BM", "hema_sc_BM", 
           "lymphoid_progenitor", "myeloid_progenitor", "macro_progenitor")

solid <- c("bladder", "liver", "pancreas", "kidney", "colon", "skin", "spleen")


sample_info <- sample_info[sample_info$hg19_coverage>0.1, ]

sample_info$blood <- rowSums(sample_info[, colnames(sample_info) %in% blood])
sample_info$solid <- rowSums(sample_info[, colnames(sample_info) %in% solid])
sample_info$total_cfDNA <- (1-sample_info$microbial_fraction)*sample_info$qubit*sample_info$elution_volume/sample_info$plasma_volume*(sample_info$microbial_control_input*sample_info$micorbial_control_input_concentration/(sample_info$microbial_control_qubit*sample_info$`microbial_control elution`))

df_firstTPs <- sample_info[, c("patient_id", "cluster_id", "event", "blood", "total_cfDNA")]

df_firstTPs <- df_firstTPs[grepl("Pre-conditioning|Transplant|Engraftment", df_firstTPs$event), ]
df_firstTPs$event<-gsub("/1 month", "", df_firstTPs$event)
df_firstTPs$event<-gsub("/ 1 month", "", df_firstTPs$event)
df_firstTPs$event <- factor(df_firstTPs$event, levels = c("Pre-conditioning", "Transplant", "Engraftment"))


pdf(file = 'figures/blood_cfDNA.pdf', width = 45/25.4, height = 40/25.4, useDingbats = FALSE)
ggplot(data = df_firstTPs, aes(x=event, y=blood))+
  geom_boxplot()+
  geom_point()+
  ylab("Blood cfDNA fraction")+
  xlab(" ")+
  ylim(c(0,1))+
  theme_classic()+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8))
dev.off()

pairwise.wilcox.test(x=df_firstTPs$blood, g=df_firstTPs$event, p.adjust.method = "none")
aggregate(.~event, df_firstTPs[, c('blood', 'event')], sd)
table(df_firstTPs$event)


pdf(file = 'figures/total_cfDNA.pdf', width = 45/25.4, height = 40/25.4, useDingbats = FALSE)
ggplot(data = df_firstTPs, aes(x=event, y=total_cfDNA))+
  geom_boxplot()+
  geom_point()+
  ylab(" ")+
  xlab(" ")+
  ylim(c(-1,16))+
  theme_classic()+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8))
dev.off()

pairwise.wilcox.test(x=df_firstTPs$total_cfDNA, g=df_firstTPs$event, p.adjust.method = "none")
table(df_firstTPs$event)

df_TPs <- sample_info[, c("patient_id", "cluster_id", "event", "blood", "total_cfDNA")]

df_TPs <- df_TPs[grepl("Pre-conditioning|Transplant|Engraftment|month", df_TPs$event), ]
df_TPs$event[grepl("Engraftment", df_TPs$event)]<-"Engraftment"
df_TPs$event[grepl("1 month", df_TPs$event)]<-"1 month"
df_TPs$event[grepl("2 month", df_TPs$event)]<-"2 month"
df_TPs$event[grepl("3 month", df_TPs$event)]<-"3 month"
df_TPs$event[grepl("6 month", df_TPs$event)]<-"6 month"


df_TPs$event <- factor(df_TPs$event, levels = c("Pre-conditioning", "Transplant", "Engraftment", "1 month", "2 month", "3 month", "6 month"))

pdf(file = 'figures/total_cfDNA_allTPS.pdf', width = 89/25.4, height = 40/25.4, useDingbats = FALSE)
ggplot(data = df_TPs, aes(x=event, y=total_cfDNA))+
  geom_boxplot()+
  geom_point()+
  ylab(" ")+
  xlab(" ")+
  ylim(c(-1,16))+
  theme_classic()+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8))

dev.off()
pairwise.wilcox.test(x=df_TPs$total_cfDNA, g=df_TPs$event, p.adjust.method = "none")
table(df_TPs$event)


