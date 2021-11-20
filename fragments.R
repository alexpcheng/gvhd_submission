library(data.table)
library(ggplot2)
library(parallel)
library(caTools)
source('~/theme_alex.R')

master_table <- fread('tables/SAMPLE_INFO_MASTER_TABLE.csv')
master_table <- master_table[master_table$bisulfite_conversion>0.94, ]

tt1 <- function(sample_id){
  len_file <- fread(paste0('/workdir/apc88/GVHD/Alignment_analysis/sample_output/Lengths/',
                           sample_id,
                           '_aligned.lengths.counts'),
                    col.names =c("coun", "len"))
  len_file <- len_file[len_file$len>100, ]
  m <- len_file$len[len_file$coun == max(len_file$coun)]
  return(m)
}

mean(sapply(X = master_table$cluster_id, FUN=tt1))
sd(sapply(X = master_table$cluster_id, FUN=tt1))


sample_length_profile <- function(filename){
  sample_name <- strsplit(filename, '/')[[1]][length(strsplit(filename, '/')[[1]])]
  sample_name <- gsub(x=sample_name, pattern="_aligned.lengths.counts", "")
  
  lengths <- data.table::fread(filename, header=FALSE)
  colnames(lengths)<-c('count', 'fragment_length')
  lengths$fragment_length <- as.numeric(as.character(lengths$fragment_length))
  lengths$Cluster_ID<-sample_name
  lengths$frac <- lengths$count/sum(lengths$count)
  return(lengths)
}

sample_length_profile2 <- function(filename){
  sample_name <- strsplit(filename, '/')[[1]][length(strsplit(filename, '/')[[1]])]
  sample_name <- gsub(x=sample_name, pattern="_aligned.lengths.gz", "")
  
  lengths <- data.table::fread(filename, header=FALSE, nrows = 1000)
  lengths$V1<-NULL
  colnames(lengths)<-c('fragment_length')
  lengths$fragment_length <- as.numeric(as.character(lengths$fragment_length))
  lengths$Cluster_ID<-sample_name
  if (grepl("STDS", filename)){
    cohort <- "Longman-STDS"
  }
  else if (grepl("WGBS", filename)){
    cohort <- "Longman-WGBS"
  }
  else{
    cohort <- "Brighma-WGBS"
  }
  lengths$cohort <- cohort
  return(lengths)
}

no_cores <- 20
cl <- makeCluster(no_cores)
ll <- list.files('../Alignment_analysis/sample_output/Lengths/', glob2rx("*BRIP*.counts"), full.names = TRUE)
ll <- ll[!grepl("MC|BRIP154", ll)]
GVH.wgbs.len <-rbindlist(parLapply(cl,
                                   ll,
                                   sample_length_profile))

stopCluster(cl)

md <- aggregate(.~fragment_length, GVH.wgbs.len[, c('fragment_length', 'frac')], mean)$frac
smp = spec.pgram((md-runmean(md, 8)), plot=F)
m.df = data.frame(per=1/smp$freq, spec=smp$spec)

pdf(file="figures/spectrum.pdf",
                width=48/25.4, height=35/25.4, paper="special", bg="white",
                fonts="Helvetica", colormodel = "cmyk", pointsize=6)
ggplot(data=m.df)+
  geom_line(aes(x=per, y=spec), size=0.25)+
  xlab('Periodicity (bp)')+
  scale_x_continuous(limits=(c(0,20)), breaks=c(10.4))+
  geom_vline(xintercept = 10.4, size = 0.25, linetype="dotted")+
  theme_alex()+
  theme(axis.text.y=element_blank(),
        axis.title = element_blank(),
        axis.ticks.y = element_blank(),
        axis.ticks.x=element_line(size=0.25),
        panel.grid = element_blank())
dev.off()

pdf(file="figures/fragment.pdf",
                width=89/25.4, height=69/25.4, paper="special", bg="white",
                fonts="Helvetica", colormodel = "cmyk", pointsize=6)
ggplot(data=GVH.wgbs.len)+
  geom_line(aes(x=fragment_length,y=frac*100, group=Cluster_ID))+
  xlab('Fragment length (bp)')+
  ylab('Fraction (%)')+
  scale_y_continuous(breaks = c(0,1,2))+
  theme_classic()+
  theme(axis.title = element_text(family= "Helvetica", size = 8),
        axis.text = element_text(family = "Helvetica", size = 6))
dev.off()



