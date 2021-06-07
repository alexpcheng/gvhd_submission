debug <- FALSE
if (debug){
  setwd("Y:/")
  DB <- "NCBIGenomes06"
  SAMPLE <- "L36_M6"
  DIR <- "/Infections/Runs/V1/Samples/L36_M6"
  REF <- "/Infections/Data/GenomeDB/NCBIGenomes06/LUTGrammy/taxids_names_lengths_tax.tab"
} else {
  args <- commandArgs(trailingOnly = TRUE)
  DIR <- args[1]
  DB <- args[2]
  SAMPLE <- args[3]
  REF <- args[4]
}
# 
# DIR<-'/workdir/apc88/grammy/V1/'
# DB<-'grammy/Short'
# SAMPLE<-'Short'
# REF<-'/workdir/apc88/grammy/LUTGrammy/taxids_names_lengths_tax.tab'


grammy.file <- paste(DIR, DB, "/", SAMPLE, ".tab", sep = "")
grammy.tab <- read.table(grammy.file, header = FALSE, fill = TRUE)
colnames(grammy.tab) <- c("SAMPLE", "Taxid", "GrAb", "GrEr")
#
blast.file <- paste(DIR, DB, "/", SAMPLE,".tblat.1", sep = "")
blast <- read.table(blast.file, header = FALSE, fill = TRUE)
total.blast <- length(unique(blast$V1))
#total.blast <- nrow(blast)
align.stats.file <- paste(DIR, "statistics/", SAMPLE, "_stats.align.tab",  sep = "")
align.stats <- read.table(align.stats.file, header = FALSE, fill = TRUE)
hg.coverage <- align.stats[align.stats$V2 == "chr21_coverage",]$V3
#
grammy.LUT <- read.table(REF, header = TRUE, fill = TRUE)

grammy.tab.info <- merge(grammy.tab, grammy.LUT, by = "Taxid")
# weighted genome size
if (is.null(hg.coverage)){
  hg.coverage <-NA
}
grammy.tab.info$hgcoverage <- hg.coverage
grammy.tab.info$WeightedGenome <- sum(grammy.tab.info$Length * grammy.tab.info$GrAb)
grammy.tab.info$AdjustedBlast <- total.blast*(grammy.tab.info$Length*grammy.tab.info$GrAb/grammy.tab.info$WeightedGenome)
grammy.tab.info$Coverage <- 75*grammy.tab.info$AdjustedBlast/grammy.tab.info$Length
grammy.tab.info$RelCoverage <- 2*75*grammy.tab.info$AdjustedBlast/grammy.tab.info$Length/hg.coverage
#
output.file <- paste(DIR, DB, "/", SAMPLE,".grammy.tab", sep = "")
write.table(grammy.tab.info, output.file,sep ="\t", row.names = FALSE)
