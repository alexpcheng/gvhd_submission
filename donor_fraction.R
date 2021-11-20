library(data.table)
library(ggplot2)
library(ggthemes)
library(stringr)
master_table <- fread('tables/SAMPLE_INFO_MASTER_TABLE.csv')
master_table$patient_id <- str_pad(as.character(master_table$patient_id), 3, side = "left", "0")

chimerism <- fread('tables/CHIMERISM.csv')
chimerism$patient_id <- str_pad(as.character(chimerism$patient_id), 3, side = "left", "0")

patient <- fread('tables/PATIENT_INFO_MASTER_TABLE.csv')
patient$patient_id <- str_pad(as.character(patient$patient_id), 3, side = "left", "0")

sexMM <- master_table[master_table$patient_sex!=master_table$donor_sex &master_table$hg19_coverage>=0.1, ]
unique(sexMM$patient_id)

get_df <- function(rowv){
  patient_sex = rowv['patient_sex']
  print(patient_sex)
  donor_sex = rowv['donor_sex']
  X = as.numeric(rowv['chrX_abund'])
  Y = as.numeric(rowv['chrY_abund'])
  A = as.numeric(rowv['chr1_abund'])
  print(Y)
  if (patient_sex == "M"){
    donor_fraction <- 100 - (2 * (100-X))
  }else if (patient_sex == "F"){
    donor_fraction <- 2 * (100-X)
  }
  return(donor_fraction)
}

sexMM$DF <- apply(X=sexMM, MARGIN=1, FUN = get_df)
sexMM$event[!sexMM$event %in% 
              c("Pre-conditioning", "Transplant", "Engraftment", "1 month", "2 month", "3 month", "6 month")] <- 
  "Disease event"
sexMM$event <- factor(sexMM$event, levels = c("Pre-conditioning", "Transplant", "Engraftment", "1 month", "2 month", "3 month", "6 month", "Disease event"))
#sexMM <- sexMM[, c("event", "cluster_id", "DF",)]

blood <- c("macrophage", "BCell", "TCell", "monocyte", "NKCell", "dendritic", 
           "eosonophil", "erythroblast", "neutrophil", "progenitor_BM", "hema_sc_BM", 
           "lymphoid_progenitor", "myeloid_progenitor", "macro_progenitor")

solid <- c("bladder", "liver", "pancreas", "kidney", "colon", "skin", "spleen")



sexMM$blood <- rowSums(data.frame(sexMM)[, colnames(sexMM) %in% blood])
sexMM$solid <- rowSums(data.frame(sexMM)[, colnames(sexMM) %in% solid])

pdf(file = 'figures/sexMMDF.pdf', width = 89/25.4, height = 45/25.4, useDingbats = FALSE)
ggplot(data = sexMM)+
  geom_line(aes(x=days_post_HCT, y = DF/100, group = as.character(patient_id)))+
  geom_point(aes(x=days_post_HCT, y = DF/100))+
  theme_classic()+ylab("Donor fraction")+xlab("Days since transplant")+
  theme(legend.position = "None",
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size = 6))
dev.off()

pdf(file = 'figures/sexMMDF_indv.pdf', width = 178/25.4, height = 160/25.4, useDingbats = FALSE)
ggplot(data = sexMM)+
  geom_line(aes(x=days_post_HCT, y = DF/100, group = as.character(patient_id)))+
  geom_point(aes(x=days_post_HCT, y = DF/100))+
  theme_classic()+ylab("Donor fraction")+xlab("Days since transplant")+
  theme(legend.position = "None",
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size = 6))+
  facet_wrap(vars(patient_id))
dev.off()

ggplot(data = sexMM[!grepl("Pre-con|Trans", sexMM$event), ])+
  geom_point(aes(x=DF/100, y = blood))+
  geom_abline(slope = 1, intercept = 0)

dd <- sexMM[!grepl("Pre-con|Trans", sexMM$event), c("patient_id", "cluster_id", "event", "DF", "blood")]
dd$diff <- abs(dd$blood-dd$DF/100)
dd$bhigh <- dd$blood>dd$DF/100
dd <- dd[order(dd$bhigh, dd$diff, decreasing = TRUE), ]

cor.test(dd$blood, dd$DF, method = "spearman")

sexMM2<- merge(sexMM, patient_table, by = "patient_id")
sexMM2$GVHD <- !is.na(sexMM2$days_HCT_to_GVHD_1)
ggplot(data = sexMM2)+
  #geom_line(aes(x=days_post_HCT, y = DF/100, group = as.character(patient_id)))+
  geom_boxplot(aes(x=event, y = DF/100, fill = GVHD))+
  geom_point(aes(x=event, y = DF/100, fill = GVHD), position = position_dodge(width = 0.75))+
  theme_classic()+ylab("Donor fraction")+xlab("Days since transplant")+
  theme(legend.position = "None",
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size = 6))

mean_data <- aggregate(.~event, sexMM[sexMM$event != "Disease event" & !sexMM$patient_id %in% c("001", "006"), c("days_post_HCT", "DF", "event")], sd)

pdf(file = 'figures/sexMMDF_001_006.pdf', width = 50/25.4, height = 40/25.4, useDingbats = FALSE)
ggplot(data = sexMM[sexMM$patient_id %in% c("002", "006"), ])+
  geom_line(aes(x=days_post_HCT, y = DF/100))+
  geom_line(aes(x=days_post_HCT, y = blood), linetype = "dotted")+
  geom_point(aes(x=days_post_HCT, y = DF/100))+
  #geom_point(data = chimerism[chimerism$patient_id %in% c("002", "006"), ],
   #          aes(x=days_post_HCT, y=as.numeric(mean_donor_perc), color = cell_type))+
  scale_y_continuous(breaks=c(0,0.5,1))+
  scale_color_brewer(palette="Set1")+
  theme_classic()+ylab("Donor fraction")+xlab("Days since transplant")+
  theme(legend.position = "None",
        strip.background = element_blank(),
        strip.text = element_blank(),
        #axis.title.y = element_blank(),
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size = 6))+
  facet_wrap(vars(patient_id), nrow =2)
dev.off()  

sex2 <- merge(sexMM, patient, by = "patient_id")
sex2 <- sex2[sex2$relapse=="no" & sex2$loss_of_graft =="no" & is.na(sex2$days_HCT_to_GVHD_1), ]
sex2 <- sex2[sex2$event!="Disease event"]

pdf(file = 'figures/DF_HLY.pdf', width = 89/25.4, height = 60/25.4, useDingbats = FALSE)
ggplot(data = sex2, aes(x=event, y=DF/100))+
  geom_boxplot()+
  geom_point()+
  theme_classic()+
  xlab(" ")+
  ylab("Donor fraction")+
  theme(legend.position = "None",
        strip.background = element_blank(),
        strip.text = element_blank(),
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size = 6))
dev.off()  
table(sex2$event)

