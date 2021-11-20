library(data.table)
library(ggplot2)
library(ggthemes)
library(stringr)
source('./ichorCNA_plotting.R') #Need to get from ichorCNA software package
master_table <- fread('tables/SAMPLE_INFO_MASTER_TABLE.csv')
master_table$patient_id <- str_pad(as.character(master_table$patient_id), 3, side = "left", "0")

patient_table <- fread('tables/PATIENT_INFO_MASTER_TABLE.csv')
patient_table$patient_id <- str_pad(as.character(patient_table$patient_id), 3, side = "left", "0")

master_table <- merge(master_table, patient_table[, c('patient_id', 'reason_for_HCT')])
master_table$disease_type <- "cancer associated"
master_table$disease_type[master_table$patient_id %in% c("008", "036")] <- "other"
master_table$disease_type <- factor(master_table$disease_type, levels = c("cancer associated", "other"))

chimerism <- fread('tables/CHIMERISM.csv')

pdf(file = 'figures/TF_PoN.pdf', width = 120/25.4, height = 45/25.4, useDingbats = FALSE)
ggplot(data = master_table)+
  geom_line(aes(x=days_post_HCT, y = ichor_TF_PoN, group = patient_id))+
  geom_point(data = master_table[master_table$disease_type == "cancer associated", ],
             aes(x=days_post_HCT, y= ichor_TF_PoN), fill= "steelblue",pch=21)+
  geom_point(data = master_table[master_table$disease_type == "other", ],
             aes(x=days_post_HCT, y= ichor_TF_PoN), fill = "orange",pch=21)+
  #geom_hline(yintercept = 0.125, linetype= "dashed")+
  theme_classic()+ylab("Tumor fraction")+xlab("Days since transplant")+
  theme(legend.position = "None",
        strip.background = element_blank(),
        strip.text = element_blank(),
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size = 6))
dev.off()

gg <- master_table[
  master_table$patient_id %in% unique(master_table$patient_id[master_table$ichor_TF_PoN>0.25]), 
  c("patient_id", "event", "cluster_id", "ichor_TF", "ichor_TF_PoN")]


cancer_only <- master_table[master_table$disease_type == "cancer associated" &
                              master_table$event %in% c("Pre-conditioning", "Transplant"), ]

cancer_only$event <- factor(cancer_only$event, 
                            levels = c("Pre-conditioning", "Transplant", "Engraftment"))

pdf(file = 'figures/TF_box.pdf', width = 50/25.4, height = 50/25.4, useDingbats = FALSE)
ggplot(data = cancer_only)+
  geom_boxplot(aes(x=event, y=ichor_TF_PoN))+
  geom_point(aes(x=event, y=ichor_TF_PoN))+
  geom_line(aes(x=event, y=ichor_TF_PoN, group=patient_id), linetype = "dotted")+
  geom_hline(yintercept = 0.125, linetype= "dashed")+
  theme_classic()+ylab("Tumor fraction")+xlab("Event")+
  scale_y_continuous(breaks =c(0, 0.25, 0.5, 0.75, 1), limits = c(0,1))+
  xlab(" ")+
  theme(legend.position = "None",
        strip.background = element_blank(),
        strip.text = element_blank(),
        axis.title = element_text(family = "Helvetica", size=8),
        axis.text = element_text(family = "Helvetica", size = 6))
dev.off()

ichor_as_gg <- function(sample_id){
  
  ichor_path = '../Alignment_analysis/sample_output/ichorCNA_PoNtmp//'
  load(file=paste0(ichor_path,sample_id,"/",sample_id,".RData"))
  
  loglik <- loglik[!is.na(loglik$init), ]
  if (estimateScPrevalence){ ## sort but excluding solutions with too large % subclonal 
    fracInd <- which(loglik[, "Frac_CNA_subclonal"] <= maxFracCNASubclone & 
                       loglik[, "Frac_genome_subclonal"] <= maxFracGenomeSubclone)
    if (length(fracInd) > 0){ ## if there is a solution satisfying % subclonal
      ind <- fracInd[order(loglik[fracInd, "loglik"], decreasing=TRUE)]
    }else{ # otherwise just take largest likelihood
      ind <- order(as.numeric(loglik[, "loglik"]), decreasing=TRUE) 
    }
  }else{#sort by likelihood only
    ind <- order(as.numeric(loglik[, "loglik"]), decreasing=TRUE) 
  }
  
  i=1
  hmmResults.cor <- results[[ind[i]]]
  logR.column = "logR"
  call.column = "Corrected_Call"
  seqinfo = NULL
  plotSegs = TRUE
  plotYLim=c(-2,2)
  main=""
  ## plot genome wide figures for each solution ##
  iter <- hmmResults.cor$results$iter
  ploidyEst <- hmmResults.cor$results$phi[s, iter]
  normEst <- hmmResults.cor$results$n[s, iter]
  purityEst <- 1 - normEst
  ploidyAll <- (1 - normEst) * ploidyEst + normEst * 2
  subclone <- 1 - hmmResults.cor$results$sp[s, iter]
  #outPlotFile <- paste0(outDir, "/", id, "/", id, "_genomeWide")
  
  segsToUse <- hmmResults.cor$results$segs[[s]]
  
  
  plotSegs = TRUE
  seqinfo=NULL
  chr=NULL
  ploidy = NULL
  geneAnnot=NULL
  xlim=NULL
  xaxt = "n"
  cex = 0.5
  gene.cex = 0.5
  plot.title = NULL
  spacing=4
  cytoBand=T
  alphaVal=1
  #color coding
  dataIn = hmmResults.cor$cna[[s]]
  segs=segsToUse
  param=NULL
  logR.column="logR"
  call.column="Corrected_Call"
  alphaVal <- ceiling(alphaVal * 255); class(alphaVal) = "hexmode"
  alphaSubcloneVal <- ceiling(alphaVal / 2 * 255); class(alphaVal) = "hexmode"
  cnCol <- c("#00FF00","#006400","#0000FF","#8B0000",rep("#FF0000", 26))
  subcloneCol <- c("#00FF00")
  cnCol <- paste(cnCol,alphaVal,sep="")
  names(cnCol) <- c("HOMD","HETD","NEUT","GAIN","AMP","HLAMP",paste0(rep("HLAMP", 8), 2:25))
  #  segCol <- cnCol
  #  ## add in colors for subclone if param provided
  #  if (!is.null(param)){
  #    ind <- ((which.max(param$ct) + 1) : length(param$ct)) + 1
  #    cnCol[ind] <- paste0(cnCol[ind], alphaSubcloneVal / 2)
  #    segCol[ind] <- "#00FF00"
  #  }
  # adjust for ploidy #
  
  
  segs[, "median"] <- segs[, "median"] + log2(ploidy / 2)
  
  
  par(mar=c(spacing,8,2,2))
  yrange=c(-2,2)
  
  midpt <- (as.numeric(dataIn[,"end"]) + as.numeric(dataIn[,"start"]))/2
  coord <- getGenomeWidePositions(dataIn[,"chr"],midpt)
  #dataIn = dataIn[dataIn$chr=="chr1" | dataIn$chr=="chr5", ]
  #coord <- getGenomeWidePositions(dataIn[,"chr"],dataIn[,"end"], seqinfo)
  print(coord)
  print('n')
  g<-ggplot()+
    geom_point(aes(x=coord$posns, y=as.numeric(dataIn[, logR.column])),
               color = cnCol[as.character(dataIn[,call.column])], size=1)+
    geom_vline(xintercept = coord$chrBkpt, linetype = "dotted", color = "gray50")+
    geom_hline(yintercept = 0, color = "gray")+
    xlab("")+
    scale_x_continuous(expand = c(0,0), limits = c(0,as.numeric(coord$posns[length(coord$posns)])))+
    ylab("")+
    ylim(c(-2,2))+
    theme_bw()+
    theme(axis.ticks.x=element_blank())+
    theme(axis.text.x=element_blank(),
          axis.text.y = element_text(family = "Helvetica", size = 6))
  #g
  return(g)
}

pdf(file = './figures/BRIP57.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP57')
dev.off()

pdf(file = './figures/BRIP24.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP24')
dev.off()

pdf(file = './figures/BRIP146.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP146')
dev.off()

pdf(file = './figures/BRIP149.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP149')
dev.off()

pdf(file = './figures/BRIP137.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP137')
dev.off()

pdf(file = './figures/BRIP136.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP136')
dev.off()

pdf(file = './figures/BRIP28.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP28')
dev.off()

pdf(file = './figures/BRIP45.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP45')
dev.off()

pdf(file = './figures/BRIP34.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP34')
dev.off()




#FOR SUPPLMENT
pdf(file = './figures/031_PR.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP146')
dev.off()

pdf(file = './figures/031_D0.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP145')
dev.off()

pdf(file = './figures/031_E.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP149')
dev.off()

pdf(file = './figures/031_1M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP147')
dev.off()

pdf(file = './figures/031_2M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP148')
dev.off()

pdf(file = './figures/031_R2.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP137')
dev.off()

pdf(file = './figures/031_6M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP136')
dev.off()

pdf(file = './figures/015_PR.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP28')
dev.off()

pdf(file = './figures/015_D0.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP27')
dev.off()

pdf(file = './figures/015_E.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP45')
dev.off()

pdf(file = './figures/015_2M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP44')
dev.off()

pdf(file = './figures/015_3M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP60')
dev.off()

pdf(file = './figures/015_6M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP121')
dev.off()

pdf(file = './figures/003_PR.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP34')
dev.off()

pdf(file = './figures/003_D0.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP35')
dev.off()

pdf(file = './figures/003_E.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP36')
dev.off()

pdf(file = './figures/003_1M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP37')
dev.off()

pdf(file = './figures/003_2M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP38')
dev.off()

pdf(file = './figures/003_3M.pdf', width = 92/25.4, height = 35/25.4, useDingbats = FALSE)
ichor_as_gg('BRIP53')
dev.off()





























ichor_as_gg2 <- function(sample_id){
  
  ichor_path = '../Alignment_analysis/sample_output//ichorCNA_PoN/'
  load(file=paste0(ichor_path,sample_id,"/",sample_id,".RData"))
  
  loglik <- loglik[!is.na(loglik$init), ]
  if (estimateScPrevalence){ ## sort but excluding solutions with too large % subclonal 
    fracInd <- which(loglik[, "Frac_CNA_subclonal"] <= maxFracCNASubclone & 
                       loglik[, "Frac_genome_subclonal"] <= maxFracGenomeSubclone)
    if (length(fracInd) > 0){ ## if there is a solution satisfying % subclonal
      ind <- fracInd[order(loglik[fracInd, "loglik"], decreasing=TRUE)]
    }else{ # otherwise just take largest likelihood
      ind <- order(as.numeric(loglik[, "loglik"]), decreasing=TRUE) 
    }
  }else{#sort by likelihood only
    ind <- order(as.numeric(loglik[, "loglik"]), decreasing=TRUE) 
  }
  
  i=1
  hmmResults.cor <- results[[ind[i]]]
  logR.column = "logR"
  call.column = "Corrected_Call"
  seqinfo = NULL
  plotSegs = TRUE
  plotYLim=c(-2,2)
  main=""
  ## plot genome wide figures for each solution ##
  iter <- hmmResults.cor$results$iter
  ploidyEst <- hmmResults.cor$results$phi[s, iter]
  normEst <- hmmResults.cor$results$n[s, iter]
  purityEst <- 1 - normEst
  ploidyAll <- (1 - normEst) * ploidyEst + normEst * 2
  subclone <- 1 - hmmResults.cor$results$sp[s, iter]
  #outPlotFile <- paste0(outDir, "/", id, "/", id, "_genomeWide")
  
  segsToUse <- hmmResults.cor$results$segs[[s]]
  
  
  plotSegs = TRUE
  seqinfo=NULL
  chr=NULL
  ploidy = NULL
  geneAnnot=NULL
  xlim=NULL
  xaxt = "n"
  cex = 0.5
  gene.cex = 0.5
  plot.title = NULL
  spacing=4
  cytoBand=T
  alphaVal=1
  #color coding
  dataIn = hmmResults.cor$cna[[s]]
  segs=segsToUse
  param=NULL
  logR.column="logR"
  call.column="Corrected_Call"
  alphaVal <- ceiling(alphaVal * 255); class(alphaVal) = "hexmode"
  alphaSubcloneVal <- ceiling(alphaVal / 2 * 255); class(alphaVal) = "hexmode"
  cnCol <- c("#00FF00","#006400","#0000FF","#8B0000",rep("#FF0000", 26))
  subcloneCol <- c("#00FF00")
  cnCol <- paste(cnCol,alphaVal,sep="")
  names(cnCol) <- c("HOMD","HETD","NEUT","GAIN","AMP","HLAMP",paste0(rep("HLAMP", 8), 2:25))
  #  segCol <- cnCol
  #  ## add in colors for subclone if param provided
  #  if (!is.null(param)){
  #    ind <- ((which.max(param$ct) + 1) : length(param$ct)) + 1
  #    cnCol[ind] <- paste0(cnCol[ind], alphaSubcloneVal / 2)
  #    segCol[ind] <- "#00FF00"
  #  }
  # adjust for ploidy #
  
  
  segs[, "median"] <- segs[, "median"] + log2(ploidy / 2)
  
  
  par(mar=c(spacing,8,2,2))
  yrange=c(-2,2)
  #midpt <- (as.numeric(dataIn[,"end"]) + as.numeric(dataIn[,"start"]))/2
  #coord <- getGenomeWidePositions(dataIn[,"chr"],midpt)
  dataIn = dataIn[dataIn$chr=="chr1" | dataIn$chr=="chr5", ]
  coord <- getGenomeWidePositions(dataIn[,"chr"],dataIn[,"end"], seqinfo)
  df <- data.frame(coord$posns, dataIn[, logR.column])
  colnames(df)<-c('X', 'Y')
  df$sample_id <-sample_id
  df$bkpt <- coord$chrBkpt[2]
  return(df)
}

df <- rbindlist(lapply(X=c("BRIP34", "BRIP35", "BRIP36", "BRIP37", "BRIP38", "BRIP53"), 
                       FUN = ichor_as_gg2))

pdf(file = 'figures/003.pdf', width = 50/25.4, height = 35/25.4, useDingbats = FALSE)

ggplot(data = df[grepl("34|36|53", df$sample_id), ])+
  geom_point(aes(x=X, y=Y, color = sample_id), pch =21, alpha =0.5)+
  geom_vline(xintercept = unique(df$bkpt), linetype = "solid", color = "black", size=1)+
  geom_hline(yintercept = 0, color = "gray")+
  xlab("")+
  scale_x_continuous(expand = c(0,0))+ #limits = c(0,as.numeric(coord$posns[length(coord$posns)])))+
  ylab("")+
  scale_y_continuous(breaks = c(-1,0.5))+
  theme_bw()+
  ggthemes::scale_color_colorblind()+
  theme(axis.ticks.x=element_blank())+
  theme(axis.text.x=element_blank(),
        axis.text.y = element_text(family = "Helvetica", size=6))+
  theme(legend.position = "none")

dev.off()

ddd <- fread('tables/SAMPLE_INFO_MASTER_TABLE.csv', data.table=FALSE)
ddd$total_cfDNA <- (1-ddd$microbial_fraction)*ddd$qubit*ddd$elution_volume/ddd$plasma_volume*(ddd$microbial_control_input*ddd$micorbial_control_input_concentration/(ddd$microbial_control_qubit*ddd$`microbial_control elution`))

blood <- c("macrophage", "BCell", "TCell", "monocyte", "NKCell", "dendritic", 
           "eosonophil", "erythroblast", "neutrophil", "progenitor_BM", "hema_sc_BM", 
           "lymphoid_progenitor", "myeloid_progenitor", "macro_progenitor")

solid <- c("bladder", "liver", "pancreas", "kidney", "colon", "skin", "spleen")


ddd <- ddd[ddd$hg19_coverage>0.1, ]

ddd$blood <- rowSums(ddd[, colnames(ddd) %in% blood])
ddd$solid <- rowSums(ddd[, colnames(ddd) %in% solid])

ddd<-ddd[ddd$patient_id==3, ]

ddd$event <- factor(ddd$event, levels = c("Pre-conditioning", "Engraftment", "3 month", "Transplant", "1 month", "2 month"))
dd = ddd[ddd$patient_id==3, ]
max_val = max(dd$ichor_TF_PoN*dd$total_cfDNA)
pdf(file = 'figures/003_scatter_v2.pdf', width = 42/25.4, height = 35/25.4, useDingbats = FALSE)

ggplot(data = dd)+
  geom_line(aes(x=days_post_HCT, y= total_cfDNA*solid), color = "darkred")+
  geom_point(aes(x=days_post_HCT, y= total_cfDNA*solid), pch = 21, color = "darkred", fill = "white")+
  
  geom_line(aes(x=days_post_HCT, y= total_cfDNA*ichor_TF_PoN), color = "forestgreen")+
  geom_point(aes(x=days_post_HCT, y= total_cfDNA*ichor_TF_PoN), pch = 21, color = "forestgreen", fill = "white")+
  
  geom_line(aes(x=days_post_HCT, y= total_cfDNA), color = "darkblue")+
  geom_point(aes(x=days_post_HCT, y= total_cfDNA), pch = 21, color = "darkblue", fill = "white")+
  
  ylab(" ")+
  theme_classic()+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8),
        legend.position = "none")

dev.off()


pdf(file = 'figures/003_scatter.pdf', width = 42/25.4, height = 35/25.4, useDingbats = FALSE)

ggplot(data = dd)+
  geom_line(aes(x=days_post_HCT, y= total_cfDNA*solid))+
  geom_point(aes(x=days_post_HCT, y= total_cfDNA*solid))+
  geom_line(aes(x=days_post_HCT, y= total_cfDNA*ichor_TF_PoN))+
  geom_point(aes(x=days_post_HCT, y= total_cfDNA*ichor_TF_PoN))+
  theme_classic()+
  ylab(" ")+
  theme(axis.text = element_text(size=6),
        axis.title = element_text(size = 8),
        legend.position = "none")

dev.off()
