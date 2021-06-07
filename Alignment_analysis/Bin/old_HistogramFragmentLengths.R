#!/usr/bin/env RScript
# Title: Histogram Fragment Lengths
# Authors: Alexandre Pellan Cheng, Iwijn De Vlaminck
# Brief description: Creates fragment length profiles for paired end sequencing data

# Initialize -------------------------------------------------------------------------------------------------
rm(list=ls())

# Load libraries ------------------------------------------------------------------------
require(ggplot2)
require(scales)
library(data.table)
# Initialize variables ------------------------------------------------------------------
save_eps <- T

args = commandArgs(trailingOnly=TRUE)
LengthsFile <- args[1]
Fig <- args[2]

# Read and format length files ----------------------------------------------------------
lengths <-  data.frame(fread(LengthsFile, header = FALSE))
lengths$V1 <- NULL
lengths.filt <- abs(lengths)
lengths.filt <- lengths.filt[lengths.filt > 0 & lengths.filt < 500]

hist.lengths <- hist(lengths.filt, breaks = 100)
df.lengths <- data.frame(mids = hist.lengths$mids, density = hist.lengths$density)

# Plot and save data --------------------------------------------------------------------
if (save_eps) { pdf(file=Fig, width=6.5/2.5,height=5/2.5, paper="special",bg="white",
                    fonts="Helvetica", colormodel="cmyk", pointsize = 8)}

ggplot(df.lengths, aes(y=density, x=mids)) +
  geom_line(colour = "red")+ 
  scale_y_continuous(limits = c(0,0.03),labels = comma) +
  xlim(0,500) + 
  labs(title="Fraction", x="Fragment size (bp)", y = "") +
  theme_bw() + theme(legend.position="none")+ scale_colour_brewer(palette="Set1") +
  theme(plot.background=element_blank()) +
  theme(axis.title=element_text(family="Helvetica", vjust=0.35, size = 8), 
        axis.text=element_text(family="Helvetica",size = 8),
        plot.title=element_text(family="Helvetica",size = 8))

if (save_eps) {dev.off()}
