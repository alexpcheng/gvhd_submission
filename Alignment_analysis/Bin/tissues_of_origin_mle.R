# example for MLE taken from:
# https://datawookie.netlify.com/blog/2013/08/fitting-a-model-by-maximum-likelihood/

# Initialize -------------------------------------------------------------------------------------------------
rm(list=ls())
# Load libraries ---------------------------------------------------------------------------------------------
library(Matrix)
library(matrixcalc)
library(stats)
library(data.table)
library(limSolve)
library(parallel)
library(bbmle)
# Source custom function ------------------------------------------------------------------------------------- 
source("tissues_of_origin_functions.R")

# Paths ------------------------------------------------------------------------------------------------------
samples.path <- "../Alignment_analysis/sample_output/V1/binned_samples/"
references.path <-"../Reference_Methylomes/MethylMatrix/" #usually "../Methylation_References/
lists.path <- "../lists/"
donor_fractions.path <- "../Alignment_analysis/sample_output/V2/donor_fraction/"
tissue_origin.path <- "../Alignment_analysis/sample_output/V2/tissues_of_origin/"

# Load samples and references ---------------------------------------------------------------------------------
file_list = list.files(path = samples.path, pattern='BRIP01')

# Function to read and slightly modify samples
process_samples<-function(filename, samples.path){
  tiled<-fread(paste0(samples.path, filename))
  colnames(tiled)<-c("chr", "start", "end", "pmeth")
  tiled<-tiled[complete.cases(tiled),]
  tiled$pmeth<-tiled$pmeth/100
  colnames(tiled)[4]<-strsplit(filename, ".filtered")[[1]][1]
  return(tiled)
}

permeth_samples<-mclapply(file_list, FUN=process_samples, samples.path, mc.cores=10)

reference_tissues<-fread(paste0(references.path, "MethylMatrix_binned"))

coln<-fread("../Reference_Methylomes/lookup_table.txt", header=F)
colnames(reference_tissues)<-c("chr", "start", "end", coln$V3)
# Initialize variables ----------------------------------------------------------------------------------------
num.tissues<-ncol(reference_tissues)-3 # 3 columns are for chromosome, start and end
num.samples<-length(file_list)

# Table preparation ------------------------------------------------------------------------------------------
merr<-function(sam, ref){
  z=merge(ref, sam, by=c("chr", "start", "end"))
  z=z[complete.cases(z)]
  return(z)
}

reference_and_samples<-mclapply(FUN=merr,
                                X=permeth_samples, reference_tissues,
                                mc.cores = 10)
# Measuring tissue of orign ----------------------------------------------------------------------------------
# Create a list where each element contains the tissues of origin and the error measurement

# Measuring mixing parameters
mp_function<-function(reference_and_samples, num.tissues){
  A<-as.data.frame(reference_and_samples[,4:(num.tissues+3)])
  b_list<-as.list(reference_and_samples[,(num.tissues+4):ncol(reference_and_samples)])
  b<- b_list[[1]]
  G<-diag(ncol(A))
  h<-rep(0,ncol(A))
  E<-(rep(1,ncol(A)))
  f<-1
  sol<-lsei(A=A, B=b, G=G, H=h, E=E, F=f, type=1, fulloutput = T)
  
  cc <- sol$X
  cc<- append(cc, 0)
  names(cc)[136] <- 'mu'
  cc <- append(cc, 1)
  names(cc)[137] <- 'sigma'
  tissue_start_points = lapply(split(cc, names(cc)), unname)
  return(cc)
  #return(tissue_start_points)
}

starting_points <-mclapply(reference_and_samples, FUN=mp_function,
                                 num.tissues, mc.cores=10)[[1]]

starting_points <- data.frame(t(starting_points))
starting_points$sample <- "BRIP01"

group_by_celltype <- function(df){
  new_df <- df[, c('sample'), drop=FALSE]
  counter<-2
  for (i in 1:ncol(df)){
    if (typeof(df[1, i][[1]]) != "character"){
      cell_type <- gsub("\\d+$", "", colnames(df)[[i]])
    }
    if (!(cell_type %in% colnames(new_df))){
      new_df <- cbind(new_df, rowSums(df[, grepl(cell_type, colnames(df)), drop=FALSE]))
      colnames(new_df)[counter] <- cell_type
      counter<-counter+1
    }
  }
  return(new_df)
}

starting_points <- group_by_celltype(starting_points)
starting_points$sample <- NULL

starting_points <- unlist(starting_points[1,])

LL <- function(BCell, bladder, colon, dendritic,
               eosonophil, erythroblast,
               hema_sc_BM, hema_sc_CB, hema_sc_PB,
               kidney, liver, lymphoid_progenitor,
               macro_progenitor, macrophage, monocyte,
               myeloid_progenitor, neutrophil, NKCell,
               pancreas, progenitor_BM, progenitor_CB,
               progenitor_PB, skin, spleen, TCell,
               mu, sigma,
               data=list(A, b)){
  # FROM LSEI
  A <- data[[1]]
  b <- data[[2]]
  
  #A <- as.matrix(data.frame(reference_and_samples)[, c(4:138)])
  #b <- as.vector(reference_and_samples[, c(139)])
  # FOR MLE
  x=A
  y=b
  R <- y - x %*% c(BCell, bladder, colon, dendritic,
                   eosonophil, erythroblast,
                   hema_sc_BM, hema_sc_CB, hema_sc_PB,
                   kidney, liver, lymphoid_progenitor,
                   macro_progenitor, macrophage, monocyte,
                   myeloid_progenitor, neutrophil, NKCell,
                   pancreas, progenitor_BM, progenitor_CB,
                   progenitor_PB, skin, spleen, TCell)
  R <- R[[1]]
  R = suppressWarnings(dnorm(R, mu, sigma, log=TRUE))
  -sum(R)
}

lower_bounds <- rep(0.0001,25)
names(lower_bounds) <- names(starting_points)[!grepl("mu|sigma", names(starting_points))]
higher_bounds <- rep(1,25)
names(higher_bounds) <- names(starting_points)[!grepl("mu|sigma", names(starting_points))]

references<-data.frame(reference_and_samples[[1]])[, c(4:138)]
references$sample<-'wtv'

A <- group_by_celltype(references)
A$sample<-NULL
A <- as.matrix(A)
b <- unlist(reference_and_samples[[1]]$BRIP01)

fit<- mle2(minuslogl=LL, start = as.list(starting_points), data = list(A, b), lower = lower_bounds, upper=higher_bounds, optimizer = "optim", method="L-BFGS-B")

summary(fit)
fit@coef

mp <- fit@coef[1:25]


mp <- mp/sum(mp)
mp

sp <- starting_points[1:15]/sum(starting_points[1:25])
sp

LL <- function(BCell1,BCell2,BCell3,BCell4,BCell5,BCell6,BCell7,BCell8,BCell9,bladder1,
              bladder2,colon1,colon10,colon11,colon12,colon13,colon14,colon15,colon16,colon17,
              colon18,colon19,colon2,colon20,colon21,colon22,colon23,colon24,colon25,colon3,
              colon4,colon5,colon6,colon7,colon8,colon9,dendritic1,dendritic2,eosonophil1,eosonophil2,
              eosonophil3,erythroblast1,erythroblast2,hema_sc_BM1,hema_sc_CB1,hema_sc_CB2,hema_sc_CB3,hema_sc_PB1,hema_sc_PB2,hema_sc_PB3,
              kidney1,kidney10,kidney11,kidney12,kidney13,kidney14,kidney2,kidney3,kidney4,kidney5,
              kidney6,kidney7,kidney8,kidney9,liver1,liver2,liver3,liver4,lymphoid_progenitor1,lymphoid_progenitor2,
              macro_progenitor1,macro_progenitor2,macro_progenitor3,macrophage1,macrophage10,macrophage11,macrophage12,macrophage2,macrophage3,macrophage4,
              macrophage5,macrophage6,macrophage7,macrophage8,macrophage9,monocyte1,monocyte2,monocyte3,monocyte4,monocyte5,
              monocyte6,myeloid_progenitor1,myeloid_progenitor2,myeloid_progenitor3,neutrophil1,neutrophil2,neutrophil3,neutrophil4,neutrophil5,
              neutrophil6,neutrophil7,neutrophil8,neutrophil9,NKCell1,NKCell2,pancreas1,pancreas2,pancreas3,pancreas4,
              pancreas5,pancreas6,pancreas7,progenitor_BM1,progenitor_CB1,progenitor_CB2,progenitor_CB3,progenitor_PB1,progenitor_PB2,progenitor_PB3,
              progenitor_PB4,skin1,skin2,spleen1,TCell1,TCell10,TCell11,TCell12,TCell2,
              TCell3,TCell4,TCell5,TCell6,TCell7,TCell8,TCell9,
              mu, sigma,
              data=list(reference_and_samples[[1]], num.tissues)){
  # FROM LSEI
  reference_and_samples <- data[[1]]
  num_tissues <- data[[2]]
  A <- as.matrix(data.frame(reference_and_samples)[, c(4:138)])
  b <- as.vector(reference_and_samples[, c(139)])
  # FOR MLE
  x=A
  y=b

  R <- y - x %*% c(BCell1,BCell2,BCell3,BCell4,BCell5,BCell6,BCell7,BCell8,BCell9,bladder1,
                   bladder2,colon1,colon10,colon11,colon12,colon13,colon14,colon15,colon16,colon17,
                   colon18,colon19,colon2,colon20,colon21,colon22,colon23,colon24,colon25,colon3,
                   colon4,colon5,colon6,colon7,colon8,colon9,dendritic1,dendritic2,eosonophil1,eosonophil2,
                   eosonophil3,erythroblast1,erythroblast2,hema_sc_BM1,hema_sc_CB1,hema_sc_CB2,hema_sc_CB3,hema_sc_PB1,hema_sc_PB2,hema_sc_PB3,
                   kidney1,kidney10,kidney11,kidney12,kidney13,kidney14,kidney2,kidney3,kidney4,kidney5,
                   kidney6,kidney7,kidney8,kidney9,liver1,liver2,liver3,liver4,lymphoid_progenitor1,lymphoid_progenitor2,
                   macro_progenitor1,macro_progenitor2,macro_progenitor3,macrophage1,macrophage10,macrophage11,macrophage12,macrophage2,macrophage3,macrophage4,
                   macrophage5,macrophage6,macrophage7,macrophage8,macrophage9,monocyte1,monocyte2,monocyte3,monocyte4,monocyte5,
                   monocyte6,myeloid_progenitor1,myeloid_progenitor2,myeloid_progenitor3,neutrophil1,neutrophil2,neutrophil3,neutrophil4,neutrophil5,
                   neutrophil6,neutrophil7,neutrophil8,neutrophil9,NKCell1,NKCell2,pancreas1,pancreas2,pancreas3,pancreas4,
                   pancreas5,pancreas6,pancreas7,progenitor_BM1,progenitor_CB1,progenitor_CB2,progenitor_CB3,progenitor_PB1,progenitor_PB2,progenitor_PB3,
                   progenitor_PB4,skin1,skin2,spleen1,TCell1,TCell10,TCell11,TCell12,TCell2,
                   TCell3,TCell4,TCell5,TCell6,TCell7,TCell8,TCell9)
  R <- R[[1]]
  R = suppressWarnings(dnorm(R, mu, sigma, log=TRUE))
  -sum(R)
}

lower_bounds <- rep(0,135)
names(lower_bounds) <- names(starting_points)[!grepl("mu|sigma", names(starting_points))]
higher_bounds <- rep(1,135)
names(higher_bounds) <- names(starting_points)[!grepl("mu|sigma", names(starting_points))]
fit<- mle2(minuslogl=LL, start = starting_points, data = list(reference_and_samples[[1]], num.tissues), method = "BFGS")
           #lower = lower_bounds, upper=higher_bounds)

library(stats4)


N <- 100
x1 <- runif(N)
x2 <- runif(N)

x <- cbind(x1,x2) # 'MethylMatrix'

y <- 5*x1 + 3 + rnorm(N) + 7*x2 # just replace with observed

# For linear models, the residuals should be normally distributed
LL <- function(beta1, beta2, mu, sigma, data=list(hello, hello)){
  #y = beta1 * x + beta0 +R
  t <- c(1,1)
  
  x %*% t
  R = y - x %*% c(beta1, beta2)
  #R = y - x1*beta1 - x2*beta2
  R = suppressWarnings(dnorm(R, mu, sigma, log=TRUE))
  -sum(R)
}
hello="hi"
#fit <- mle(LL, start = list(beta1 = 1, beta2=1, mu=0, sigma = 1))
#fit
fit<- mle2(minuslogl=LL, start = list(beta1 = 0, beta2=0, mu=0, sigma = 1))
fit

# test each tissue individually -----------------------------------------------

