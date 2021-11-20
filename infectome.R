#!/usr/bin/env RScript
# Title: infectome.R
# Authors: Alexandre Pellan Cheng
# Brief description: Infectome measurements of plasma cfDNA

# Load libraries -----------------------------------------------------------------------------------------------
rm(list=ls())
library(data.table)
library(ggplot2)
library(parallel)
source('~/theme_alex.R')
source('/workdir/apc88/GVHD/software/LowBiomassBackgroundCorrection/bin/R/load_packages.R')
install("/workdir/apc88/GVHD/software/LowBiomassBackgroundCorrection/SparseMetagenomicCorrection/")
library(SparseMetagenomicCorrection)

# functions ----------------------------------------------------------------------------------------------------

# paths --------------------------------------------------------------------------------------------------------
wetlabmetadata.path <- '/workdir/apc88/GVHD/analysis_final/tables/SAMPLE_INFO_MASTER_TABLE.csv'
path.grammy <- '/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/grammy/'
path.reads <- '/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/total_reads/'
path.stats <- '/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/aln_stats/'
path.tblat <- '/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/tblats/'
common_seq_contaminants.path <- '/workdir/apc88/KTxBS_Publication/lists/common_sequence_contaminants.toremove.txt'

# Load data and format -----------------------------------------------------------------------------------------
wetlab <- fread(wetlabmetadata.path)
controls <- fread('tables/CONTROLS.csv', data.table=FALSE)

# Create appropriate directories -------------------------------------------------------------------------------
dir.create('/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/', showWarnings = FALSE)
dir.create('/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/grammy/', showWarnings = FALSE)
dir.create('/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/tblats/', showWarnings = FALSE)
dir.create(path.reads, showWarnings = FALSE)
dir.create(path.stats, showWarnings = FALSE)

# Create LBBC grammy and tblat files ---------------------------------------------------------------------------
sample_grammys <- list.files(path = '/workdir/apc88/GVHD/updated_grammy_wgbs/sample_output/grammy',
                             pattern= glob2rx('BRIP*.grammy.tab'),
                             recursive=TRUE,
                             full.names = TRUE)

sample_grammys <- sample_grammys[!grepl('MC|new', sample_grammys)]

# Get appropriate controls based on sequencing batch -----------------------------------------------------------
all_control_grammys <- list.files(path = '/workdir/apc88/GVHD/updated_grammy_wgbs/sample_output/grammy',
                                  pattern = glob2rx('*MC*.grammy.tab'),
                                  recursive=TRUE,
                                  full.names=TRUE)
all_control_grammys <- all_control_grammys[!grepl('new_samples', all_control_grammys)]


control_grammys <- c()

for (ctl in all_control_grammys){
  print(ctl)
  ctl_name <- gsub(pattern = ".grammy.tab", "", strsplit(x = ctl, split = '/')[[1]][9])
  print(ctl_name)
  if (controls$microbial_control_batch[controls$cluster_id==ctl_name]==1 & grepl("LMC",ctl_name)){
    control_grammys <- c(control_grammys, ctl)
  }
  if (controls$microbial_control_batch[controls$cluster_id==ctl_name]==2 & grepl("HMC",ctl_name)){
    control_grammys <- c(control_grammys, ctl)
  }
  if (ctl_name == "LMCB16"){
    control_grammys <- c(control_grammys, ctl)
  }
}

adjust_gram <- function(filename){
  
  a <- fread(filename)
  if (!grepl("MC", filename)){
    sample_id <- a$SAMPLE[1]
    dedup <- fread(paste0('/workdir/apc88/GVHD/Alignment_analysis/sample_output/deduplication/', sample_id, '.txt'))
    a$AdjustedBlast <- a$AdjustedBlast * dedup$reads_kept/dedup$total_reads
    a$RelCoverage <- a$RelCoverage * dedup$reads_kept/dedup$total_reads
  }
  return(a)
}

# Prepare files for LBBC ---------------------------------------------------------------------------------------
# LBBC requires a concatenated grammy file of all studied files 

c(control_grammys, sample_grammys)[[8]]
gram <- unique(rbindlist(lapply(X = c(control_grammys, sample_grammys), FUN=adjust_gram)))
fwrite(file = '/workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/grammy/GVHD.grammy.tab',
       x = gram, quote = FALSE, sep='\t', col.names = TRUE, row.names = FALSE)

# LBBC requires all tblat.1 files to be in the same folder
sample_tblats <- gsub(".grammy.tab", ".tblat.1", sample_grammys)
control_tblats <- gsub(".grammy.tab", ".tblat.1", control_grammys)  

lapply(X = c(sample_tblats, control_tblats),
       FUN= function(x){cmd <- paste0('cp ', x, ' /workdir/apc88/GVHD/updated_grammy_wgbs/LBBC/tblats/'); system(cmd)})


# MAY 3 ALEX YOU ARE HERE

# Perform background corrections -------------------------------------------------------------------------------
# Set parameters----
bact.deltaCV.maximum = 2 
bact.Batch.var.log.min = -6 
bact.Negative.ctrl.coef.max = 10
bact.tax.level = "species"

virus.deltaCV.maximum = 2 # though we will turn this off.
virus.Batch.var.log.min = -15 #9
virus.Negative.ctrl.coef.max = 10
virus.tax.level = "species"

euka.deltaCV.maximum = 1
euka.Batch.var.log.min = -6 
euka.Negative.ctrl.coef.max = 10 
euka.tax.level = "species"

archaea.deltaCV.maximum = 2
archaea.Batch.var.log.min = -9 
archaea.Negative.ctrl.coef.max = 10
archaea.tax.level = "species"

Coverage.min.threshold = 10**-9

# Load metadata----
analyzed_data = sapply(X = c(control_grammys, sample_grammys),
                       FUN = function(x){gsub(".grammy.tab", "", strsplit(x, '/')[[1]][9])})


lab.metadata = fread(wetlabmetadata.path, data.table=FALSE)
lab.metadata = lab.metadata[lab.metadata$cluster_id %in% analyzed_data, ]

lab.metadata$biomass <- as.numeric(lab.metadata$elution_volume)*as.numeric(lab.metadata$qubit)

GVHD.meta = InitializeMetaData(SampleVector = lab.metadata$cluster_id,
                               BatchVector = paste0(lab.metadata$Sequence_order),
                               BatchName = 'Ex.batch')

lp.meta = lab.metadata[, c('cluster_id', 'Sequence_order')]
lp.meta$Batch = lp.meta$Sequence_order
GVHD.meta <- AddMetaData(MetaDataObject = GVHD.meta,
                         BatchFrame = lp.meta[, c(1,3)],
                         BatchName="LP.batch")

GVHD.meta <- AddMetaData(MetaDataObject = GVHD.meta,
                         ParameterFrame = lab.metadata[, c('cluster_id', 'biomass')],
                         ParameterName = "Biomass")
GVHD.meta <- GVHD.meta[grepl("BRIP", GVHD.meta$Sample) & !grepl("MC", GVHD.meta$Sample), ]

# Load or generate abundance matrix----
Read.Abund.Matrix = TotalReadsGen(GVHD.meta,
                                  TotalReadsOutput=paste0(path.reads, "GVHDmeta.totalreads.tab"),
                                  RawDataPath = "/workdir/apc88/GVHD/Data/samples/")

# Load negative controls----
negatives = SetNegativeControl(sample.vector = as.character(analyzed_data[grepl("MC", analyzed_data)]),
                               raw.data.path = '/workdir/apc88/GVHD/Data/samples/',
                               table.path = path.reads,
                               tblat.path = path.tblat)

GVHD.abundance = LoadAbundance(dir = path.grammy, file = "GVHD.grammy.tab")
GVHD.abundance = GVHD.abundance[(GVHD.abundance$superkingdom==2 |
                                   GVHD.abundance$superkingdom==10239 |
                                   GVHD.abundance$superkingdom==2759 |
                                   GVHD.abundance$superkingdom==2157), ]
colnames(GVHD.abundance)[2] = "Sample"
GVHD.abundance = GVHD.abundance[GVHD.abundance$RelCoverage >= Coverage.min.threshold, ]
GVHD.abundance$Measurement = GVHD.abundance$RelCoverage
GVHD.abundance <- GVHD.abundance[grepl("BRIP", GVHD.abundance$Sample) & !grepl("MC", GVHD.abundance$Sample), ]
GVHD.abundance <- GVHD.abundance[!(GVHD.abundance$genus %in% common_seq_contam$taxid), ]
taxinfo <- GVHD.abundance[, c('Sample', 'species', 'genus', 'family')]
colnames(taxinfo)[[2]]<-'SpecTax'

#Generate alignement CV files ----
no_cores = detectCores()-1
cl <- makeCluster(no_cores)
parLapply(cl,
          as.list(unique(GVHD.abundance$Sample)),
          AlignStatsSample,
          TblatPath=path.tblat,
          GITable="/workdir/apc88/GVHD/software/LowBiomassBackgroundCorrection/lookups/gi_tax_info.tab",
          OutPath=path.stats)
stopCluster(cl)

# denoising ----
GVHD.bacteria.abundance = GVHD.abundance[GVHD.abundance$superkingdom==2, ]
bacteria = DenoiseAlgorithm(AbundanceObject = GVHD.bacteria.abundance, MetaDataObject = GVHD.meta,
                            NegativeObject = negatives,ReadAbundMatrix = Read.Abund.Matrix,
                            CV.Filter = T, MassVar.Filter = T,NegCtrl.Filter = T,
                            deltaCV.Param = bact.deltaCV.maximum, MassVar.Param = bact.Batch.var.log.min, 
                            NegCtrl.Param = bact.Negative.ctrl.coef.max, TaxLevel = bact.tax.level,
                            FastqPath = "/workdir/apc88/GVHD/Data/samples/",TablePath = path.reads, TblatPath = path.tblat, AlnStatsPath = path.stats,
                            GITable = "/workdir/apc88/GVHD/software/LowBiomassBackgroundCorrection/lookups/gi_tax_info.tab")
filtered.bacteria = merge(bacteria, GVHD.meta, "Sample")
filtered.bacteria$superkingdom <- 2
filtered.bacteria <- unique(merge(filtered.bacteria, taxinfo[, c('Sample', 'SpecTax', 'family')], by=c('Sample', 'SpecTax')))

GVHD.virus.abundance = GVHD.abundance[GVHD.abundance$superkingdom==10239, ]
virus = DenoiseAlgorithm(AbundanceObject = GVHD.virus.abundance, MetaDataObject = GVHD.meta,
                         NegativeObject = negatives,ReadAbundMatrix = Read.Abund.Matrix,
                         CV.Filter = F, MassVar.Filter = T,NegCtrl.Filter = T,
                         deltaCV.Param = virus.deltaCV.maximum, MassVar.Param = virus.Batch.var.log.min, 
                         NegCtrl.Param = virus.Negative.ctrl.coef.max, TaxLevel = virus.tax.level,
                         FastqPath = "/workdir/apc88/GVHD/Data/samples/",TablePath = path.reads, TblatPath = path.tblat, AlnStatsPath = path.stats,
                         GITable = "/workdir/apc88/GVHD/software/LowBiomassBackgroundCorrection/lookups/gi_tax_info.tab")

filtered.virus = merge(virus, GVHD.meta, "Sample")
filtered.virus$superkingdom <- 10239
filtered.virus <- unique(merge(filtered.virus, taxinfo[, c('Sample', 'SpecTax', 'family')], by=c('Sample', 'SpecTax')))

BK_pre_filt <- GVHD.virus.abundance[grepl("BK_polyo", GVHD.virus.abundance$Name), ]
BK_post_filt <- filtered.virus[grepl("BK polyo", filtered.virus$Name), ]

dd <- merge(BK_pre_filt[, c("Sample", "Name")], BK_post_filt[, c("Sample", "Name")], by="Sample", all=T)
ee <- BK_pre_filt[grepl("P182|P48|P60|P83", BK_pre_filt$Sample), ]

colnames(BK_post_filt)[[1]]<-c("cluster_id")
BK_post_filt <- BK_post_filt[, c("cluster_id", "Measurement")]

BK_post_filt <- merge(wetlab[, c("cluster_id", "BK_blood_clinical", "BK_urine_clinical", "patient_id", "days_post_HCT")], BK_post_filt, all=TRUE)
BK_post_filt$BK_blood_clinical<- as.numeric(BK_post_filt$BK_blood_clinical)
BK_post_filt$BK_urine_clinical <- as.numeric(BK_post_filt$BK_urine_clinical)

FP <- unique(BK_post_filt$patient_id[BK_post_filt$Measurement>0 & BK_post_filt$BK_blood_clinical==38])
tt <- BK_post_filt[BK_post_filt$Measurement>0 & BK_post_filt$BK_blood_clinical==38, ]


BK_extra<-BK_post_filt[BK_post_filt$patient_id %in% c(31), ]
BK_extra$Measurement[is.na(BK_extra$Measurement)]<-0
BK_extra$BK_blood_clinical[BK_extra$BK_blood_clinical==38]<-0
BK_extra$BK_urine_clinical[BK_extra$BK_urine_clinical==499]<-0
BK_extra<- melt(BK_extra, id.vars = c("cluster_id", "patient_id", "days_post_HCT"))

breaks_fun <- function(x) {
  if (max(x) ==0) {
    seq(0)
  }
  if (max(x)<1 & max(x)>0){
    seq(0, 0.7, 0.3)
  }else{
    c(0,1000,100000,10000000)
  }
}

BK_extra$variable <- factor(BK_extra$variable, levels = c("BK_blood_clinical", "Measurement", "BK_urine_clinical"))


pdf(file = 'figures/BK_031.pdf', width = 70/25.4, height = 33/25.4, useDingbats = FALSE)
ggplot(data = BK_extra)+
  geom_point(aes(x=days_post_HCT, y=value))+
  geom_line(aes(x=days_post_HCT, y=value, group= patient_id))+
  geom_point(data = BK_extra[BK_extra$value == 0, ], aes(x=days_post_HCT, y=value), fill="white", pch=21)+
  scale_y_continuous(trans="pseudo_log", breaks = breaks_fun)+
  facet_grid(patient_id+variable~., scales = "free_y")+
  xlab("Days since transplant")+
  theme_classic()+
  ylab("Measurement")+
  theme(strip.background = element_blank(),
        #strip.text = element_blank(),
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size=6))
dev.off()

BK_post_filt$Measurement[is.na(BK_post_filt$Measurement)]<-0
BK_post_filt$clinical_detec <- "Yes"
BK_post_filt$clinical_detec[BK_post_filt$BK_blood_clinical==38]<-"No"
small = BK_post_filt[!is.na(BK_post_filt$BK_blood_clinical), ]
small = small[!(small$BK_urine_clinical>499 & small$BK_blood_clinical==38), ]
small = small[order(small$clinical_detec, small$Measurement), ]
small$cfDNA_detect <-"Yes"
small$cfDNA_detect[small$Measurement==0]<-"No"

small$cfDNA_detect<- factor(small$cfDNA_detect, levels = c("Yes", "No"))
small$clinical_detec<- factor(small$clinical_detec, levels = c("Yes", "No"))

wilcox.test(small$Measurement~small$clinical_detec)
aggregate(.~clinical_detec, small[, c("clinical_detec", "Measurement")], sd)

library(caret)

sensitivity(small$cfDNA_detect, small$clinical_detec, positive = "Yes")
specificity(small$cfDNA_detect, small$clinical_detec, positive = "Yes")

g1 <- ggplot(data = small, aes(x=clinical_detec, y = Measurement))+
  geom_boxplot()+
  geom_point()+
  scale_y_continuous(trans = "pseudo_log")+
  theme_classic()+
  ylab("BK polyomavirus\nRelative Genomic Equivalents")+
  xlab("Clincal detection")+
  theme(axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size=6))

small$clinical_detec <- factor(small$clinical_detec, levels = c("No", "Yes"))

proc <- roc(response = small$clinical_detec,
            predictor = small$Measurement)
roc(response = small$clinical_detec,
    predictor = small$Measurement, print.auc=TRUE)

g2 <- ggroc(proc, color = "blue")+
  geom_abline(slope = 1, intercept = 1, linetype = "dotted")+
  geom_point(aes(x=0.9752, y=0.8889))+
  theme_classic()+
  theme(axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size=6))
  
library(gridExtra)

pdf(file = 'figures/BK_threshold.pdf', width = 114/25.4, height = 114/2/25.4, useDingbats = FALSE)

grid.arrange(g1, g2, ncol=2)

dev.off()
confusionMatrix(table(small[, c("cfDNA_detect", "clinical_detec")]))
    
Anello_viruses <- filtered.virus[filtered.virus$family == 687329, ]
Anello_viruses <- Anello_viruses[!is.na(Anello_viruses$Sample), ]
Anello_viruses$cluster_id <- Anello_viruses$Sample
Anello_viruses <- merge(wetlab[, c("cluster_id", "days_post_HCT", "patient_id", "event")], Anello_viruses, by= "cluster_id", all=TRUE)

Anello_viruses$Measurement[is.na(Anello_viruses$Measurement)]<-0
table(Anello_viruses$Name)
qq <- data.frame(table(filtered.virus$family))
qq <- qq[order(qq$Freq, decreasing=TRUE), ]


Anello_viruses_fam <- aggregate(.~cluster_id+days_post_HCT+patient_id+event, 
                                Anello_viruses[, c("cluster_id", "days_post_HCT", "Measurement", "patient_id", "event")], sum)

Anello_viruses_fam$event[grepl("Engraftment", Anello_viruses_fam$event)]<-"Engraftment"
Anello_viruses_fam$event[grepl("1 month", Anello_viruses_fam$event)]<-"1 month"
Anello_viruses_fam$event[grepl("2 month", Anello_viruses_fam$event)]<-"2 month"
Anello_viruses_fam$event[grepl("6 month", Anello_viruses_fam$event)]<-"6 month"
Anello_viruses_fam<- Anello_viruses_fam[!grepl("BK", Anello_viruses_fam$event), ]
Anello_viruses_fam$event <- factor(Anello_viruses_fam$event, levels =c("Pre-conditioning",
                                                                       "Transplant",
                                                                       "Engraftment",
                                                                       "1 month",
                                                                       "2 month",
                                                                       "3 month", 
                                                                       "6 month"))
ggplot(data = Anello_viruses_fam)+
  geom_point(aes(x=days_post_HCT, y=Measurement))+
  geom_line(aes(x=days_post_HCT, y=Measurement, group = patient_id))+
  theme_classic()

Anello_viruses_fam$event2 <- Anello_viruses_fam$days_post_HCT<=0
pdf(file = './Anello.pdf', width = 90/25.4, height = 50/25.4, useDingbats = FALSE)
ggplot(data = Anello_viruses_fam)+
  geom_boxplot(aes(x=event, y=Measurement))+
  geom_point(aes(x=event, y=Measurement))+
  scale_y_continuous(trans="pseudo_log")+
  theme_classic()


ee <- Anello_viruses_fam[grepl("Pre|Tra|3", Anello_viruses_fam$event), ]
ee$ee <- as.character(ee$event)

ee$ee[grepl("Pre|Tr", ee$ee)]<-"Pre-transplant"
ee$ee <- factor(ee$ee, levels = c("Pre-transplant", "3 month"))

pdf(file = 'figures/Anello_TP.pdf', width = 25/25.4, height = 25/25.4, useDingbats = FALSE)
ggplot(data = ee)+
  geom_boxplot(aes(x=ee, y=Measurement))+
  geom_point(aes(x=ee, y=Measurement))+
  scale_y_continuous(breaks=c(0,10,100), trans = "pseudo_log")+
  xlab(" ")+
  ylab("Relative genomic equivalents")+
  theme_classic()+
  theme(axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size=6))
dev.off()

pairwise.wilcox.test(x=ee$Measurement, g=ee$ee)

pairwise.wilcox.test(x=Anello_viruses_fam$Measurement, g=Anello_viruses_fam$event, p.adjust.method = "none")

tt <- Anello_viruses[Anello_viruses$days_post_HCT>150 & Anello_viruses$Measurement>50, ]



herpes_viruses <- filtered.virus[filtered.virus$family == 10292, ]
herpes_viruses <- herpes_viruses[grepl("Human", herpes_viruses$Name), ]
herpes_viruses <- herpes_viruses[!is.na(herpes_viruses$Sample), ]
herpes_viruses$cluster_id <- herpes_viruses$Sample

tab <- data.frame(sort(rep(lab.metadata$cluster_id, 6)), 
                  rep(c(10298, 10359, 10372, 10376, 32603, 32604), 170))
colnames(tab)<-c("cluster_id", "SpecTax")


herpes_viruses <- merge(herpes_viruses, tab, all = TRUE, by = c("SpecTax", "cluster_id"))

herpes_viruses$Measurement[is.na(herpes_viruses$Measurement)]<-0
herpes_viruses <- merge(wetlab[, c("cluster_id", "days_post_HCT", "patient_id", "event")], 
                        herpes_viruses, by= "cluster_id")
herpes_viruses$event[grepl("Engraftment", herpes_viruses$event)]<-"Engraftment"
herpes_viruses$event[grepl("1 month", herpes_viruses$event)]<-"1 month"
herpes_viruses$event[grepl("2 month", herpes_viruses$event)]<-"2 month"
herpes_viruses$event[grepl("6 month", herpes_viruses$event)]<-"6 month"
herpes_viruses<- herpes_viruses[!grepl("BK", herpes_viruses$event), ]
herpes_viruses$event <- factor(herpes_viruses$event, levels =c("Pre-conditioning",
                                                                       "Transplant",
                                                                       "Engraftment",
                                                                       "1 month",
                                                                       "2 month",
                                                                       "3 month", 
                                                                       "6 month"))




hh <- herpes_viruses[, c("SpecTax", "Measurement", "event")]
#hh <- aggregate(.~SpecTax+event, hh, mean)

pdf(file = 'figures/Herpes.pdf', width = 65/25.4, height = 25/25.4, useDingbats = FALSE)
ggplot(data = hh, aes(x=event, y= Measurement, fill=as.character(SpecTax)))+
  stat_summary(fun.y = mean, geom="bar", position="dodge")+
  stat_summary(geom= "errorbar", position= position_dodge(width = 0.9), width = 0.1)+
  theme_classic()+
  ggthemes::scale_fill_calc()+
  xlab(" ")+
  ylab("Relative genomic equivalents")+
  theme(legend.position = "None")+
  theme(axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size=6))
dev.off()
 