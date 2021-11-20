#!/usr/bin/env RScript
# Title: GVHD.R
# Authors: Alexandre Pellan Cheng
# Brief description: Plots & stats related to GVHD

library(data.table)
library(ggplot2)
library(scales)

sample_info <- fread('tables/SAMPLE_INFO_MASTER_TABLE.csv', data.table = FALSE)
sample_info <- sample_info[sample_info$hg19_coverage>0.1, ]

patient_info <- fread('tables/PATIENT_INFO_MASTER_TABLE.csv', data.table = FALSE)
patient_info <- patient_info[!is.na(patient_info$patient_id), ]


blood <- c("macrophage", "BCell", "TCell", "monocyte", "NKCell", "dendritic", 
           "eosonophil", "erythroblast", "neutrophil", "progenitor_BM", "hema_sc_BM", 
           "lymphoid_progenitor", "myeloid_progenitor", "macro_progenitor")

solid <- c("bladder", "liver", "pancreas", "kidney", "colon", "skin", "spleen")



sample_info$blood <- rowSums(sample_info[, colnames(sample_info) %in% blood])
sample_info$solid <- rowSums(sample_info[, colnames(sample_info) %in% solid])
sample_info$total_cfDNA <- (1-sample_info$microbial_fraction)*sample_info$qubit*sample_info$elution_volume/sample_info$plasma_volume*(sample_info$microbial_control_input*sample_info$micorbial_control_input_concentration/(sample_info$microbial_control_qubit*sample_info$`microbial_control elution`))


df <- merge(sample_info[, c("blood", "colon", "liver", "skin", "solid", "total_cfDNA", "cluster_id", "patient_id",
                            "days_post_HCT", "event")],
            patient_info[, c("patient_id", "gvhd", "days_HCT_to_GVHD_1", "liver_stage", "gut_stage", "skin_stage")], by = "patient_id")

df$stauts <- '+'
df$stauts[is.na(df$gvhd)] <- '-'

df$days_post_HCT <- as.numeric(as.character(df$days_post_HCT))

pdf(file = 'figures/GVHD_solid_cfDNA.pdf', width = 94/25.4, height = 45/25.4, useDingbats = FALSE)
ggplot(data = df, aes(x=days_post_HCT, y=solid*total_cfDNA, group = patient_id, color = stauts))+
  geom_line()+
  geom_point()+
  ylab(" ")+
  xlab("Days since transplant")+
  scale_y_continuous(labels = scales::label_number(accuracy = 0.01))+
  ggthemes::scale_color_tableau()+
  theme_classic()+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8),
        legend.position = "none")
dev.off()

df2 <- df[grepl("1 mo|2 mo|3 mo|6 mo|En|Pr|Tr", df$event), ]
df2$days_HCT_to_GVHD_1[is.na(df2$days_HCT_to_GVHD_1)]<-1000
df2 <- df2[df2$days_post_HCT<=df2$days_HCT_to_GVHD, ]
df2$event[grepl("Engraftment", df2$event )]<-"Engraftment"
df2$event[grepl("1 month", df2$event)] <- "1 month"
df2$event[df2$event == "symptom W1,2/6 month"] <- "1 month"

df2$event <- factor(df2$event, levels = c("Pre-conditioning", "Transplant", "Engraftment", "1 month", "2 month", "3 month", "6 month"))

pdf(file = 'figures/GVHD_solid_cfDNA_TPs.pdf', width = 94/25.4, height = 40/25.4, useDingbats = FALSE)
ggplot(data = df2, aes(x=event, y=solid*total_cfDNA, fill = stauts))+
  geom_boxplot(position = position_dodge2(preserve="single"), outlier.shape = NA)+
  geom_point(position=position_dodge(width = 0.75), pch =21, fill="white", aes(group = stauts))+
  scale_y_log10()+
  ylab(" ")+
  xlab(" ")+
  ggthemes::scale_fill_tableau()+
  theme_classic()+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8),
        legend.position = "none")

dev.off()

a <- df2[, c("event", "stauts", "solid")]
colnames(a)[[3]] <- "measurement"
a$var <- "Fraction"

b <- df2[, c("event", "stauts")]
b$measurement <- df2$solid*df2$total_cfDNA
b$var <- "solid_conc"

c <- df2[, c("event", "stauts", "total_cfDNA")]
colnames(c)[[3]] <- "measurement"
c$var <- "total_cfDNA"

d<-rbind(a,b,c)

pdf(file = 'figures/GVHD_fractionVStotal_TPs.pdf', width = 178/25.4, height = 150/25.4, useDingbats = FALSE)
ggplot(data = d, aes(x=event, y=measurement, fill = stauts))+
  geom_boxplot(position = position_dodge2(preserve="single"), outlier.shape = NA)+
  geom_point(position=position_dodge(width = 0.75), pch =21, fill="white", aes(group = stauts))+
  scale_y_log10()+
  ylab(" ")+
  xlab(" ")+
  ggthemes::scale_fill_tableau()+
  theme_bw()+
  facet_wrap(vars(var), nrow = 3, scales = "free_y")+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8),
        legend.position = "none")
dev.off()

print("=============== STATS SOLID CONCENTRATION ======================")
df3 = df2[df2$event == "Pre-conditioning", ]
wilcox.test(df3$total_cfDNA*df3$solid~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "Transplant", ]
wilcox.test(df3$total_cfDNA*df3$solid~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "Engraftment", ]
wilcox.test(df3$total_cfDNA*df3$solid~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "1 month", ]
wilcox.test(df3$total_cfDNA*df3$solid~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid*df3$total_cfDNA)

df3 = df2[df2$event == "2 month", ]
wilcox.test(df3$total_cfDNA*df3$solid~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid*df3$total_cfDNA, plot=TRUE)

df3 = df2[df2$event == "3 month", ]
wilcox.test(df3$total_cfDNA*df3$solid~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid*df3$total_cfDNA)

df3 = df2[df2$event == "6 month", ]
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid*df3$total_cfDNA, plot=TRUE)

print("=============== STATS SOLID FRACTION ======================")
df3 = df2[df2$event == "Pre-conditioning", ]
wilcox.test(df3$solid~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "Transplant", ]
wilcox.test(df3$solid~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "Engraftment", ]
wilcox.test(df3$solid~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "1 month", ]
wilcox.test(df3$solid~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid)

df3 = df2[df2$event == "2 month", ]
wilcox.test(df3$solid~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid, plot=TRUE)

df3 = df2[df2$event == "3 month", ]
wilcox.test(df3$solid~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid)

df3 = df2[df2$event == "6 month", ]
table(df3$stauts)
pROC::roc(df3$stauts, df3$solid, plot=TRUE)

print("=============== STATS TOTAL CONCENTRATION ======================")
df3 = df2[df2$event == "Pre-conditioning", ]
wilcox.test(df3$total_cfDNA~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "Transplant", ]
wilcox.test(df3$total_cfDNA~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "Engraftment", ]
wilcox.test(df3$total_cfDNA~df3$stauts)
table(df3$stauts)

df3 = df2[df2$event == "1 month", ]
wilcox.test(df3$total_cfDNA~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$total_cfDNA)

df3 = df2[df2$event == "2 month", ]
wilcox.test(df3$total_cfDNA~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$total_cfDNA, plot=TRUE)

df3 = df2[df2$event == "3 month", ]
wilcox.test(df3$total_cfDNA~df3$stauts)
table(df3$stauts)
pROC::roc(df3$stauts, df3$total_cfDNA)

df3 = df2[df2$event == "6 month", ]
table(df3$stauts)
pROC::roc(df3$stauts, df3$total_cfDNA, plot=TRUE)
