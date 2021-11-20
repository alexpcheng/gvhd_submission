#!/usr/bin/env RScript
# Title: Unsupervised clustering of reference methylomes and sample projection
# Authors: Alexandre Pellan Cheng
# Brief description: Generates UMAP

rm(list=ls())

#libraries --------------------------------------------------------------------
library(data.table)
library(parallel)
library(ggplot2)
library(umap)
library(dplyr)
library(ggpubr)
library(pals)
library(scales)
library(ggtern)
source('~/theme_alex.R')
#Colors ------------------------------------------------------------------------
as.vector(pals::alphabet(19))
custom_palette <- c("#0075dc", "#0007dc", "#00dcd5",
                    "#4C005C", "#191919",
                    "#005C31",
                    "#ffcc99", "#ff4da6", "#ff9999",
                    "#94FFB5", "#8F7C00", "#9DCC00",
                    "#C20088", 
                    "#003380",
                    "#FFA405",
                    "#808080", #"#FFA8BB",
                    "#426600",
                    "#FF0010",
                    "#993F00")



#Functions --------------------------------------------------------------------
# Creates a list with each element containing the reference matrix or a sample.
  # NANs are removed from dataframes and sample methylation percentages are 

# scaled to a fraction to be consistent with the reference matrix.

process_files<-function(filename, references.path){
  col<-fread("../Reference_Methylomes/lookup_table.txt", header=F)
  tiled<-fread(paste0(references.path, filename))
  tiled<-tiled[complete.cases(tiled),]
  colnames(tiled)<-c("chr", "start", "end", col$V4)
  return(tiled)
}

# Renames tissues for easier plotting
tissue_names<-function(sample_row, coll){
  if (grepl("kidney", sample_row[coll]))
    colr<-"kidney"
  else if (grepl("mesangial", sample_row[coll]))
    colr<-"kidney"
  else if (grepl("podocyte", sample_row[coll]))
    colr<-"kidney"
  else if (grepl("Large_intestine|sigmoid", sample_row[coll]))
    colr<-"intestine"
  else if (grepl("small_intestine", sample_row[coll]))
    colr<-"intestine"
  else if (grepl("bladder", sample_row[coll]))
    colr<-"bladder" #for layering
  else if (grepl("skin", sample_row[coll]))
    colr<-"skin"
  else if (grepl("liver", sample_row[coll]))
    colr<-"liver"
  else if (grepl("hepatocyte", sample_row[coll]))
    colr<-"liver"
  else if (grepl("pancreas", sample_row[coll]))
    colr<-"pancreas"
  else if (grepl("islet", sample_row[coll]))
    colr<-"pancreas"
  else if (grepl("macrophage", sample_row[coll]) & !grepl("macrophage_progenitor", sample_row[coll]))
    colr<-"macrophage"
  else if (grepl("monocyte", sample_row[coll]))
    colr<-"monocyte"
  else if (grepl("dendritic", sample_row[coll]))
    colr<-"dendritic"
  else if (grepl("eosonophil", sample_row[coll]))
    colr<-"eosonophil"
  else if (grepl("neutrophil", sample_row[coll]))
    colr<-"neutrophil"
  else if (grepl("NK", sample_row[coll]))
    colr<-"NKell"
  else if (grepl("TCell", sample_row[coll]))
    colr<-"Tcell"
  else if (grepl("BCell", sample_row[coll]))
    colr<-"Bcell"
  else if (grepl("spleen", sample_row[coll]))
    colr<-"spleen"
  else if (grepl("erythroblast", sample_row[coll]))
    colr<-"erythroblast"
  else if (grepl("progenitor_bone|hematopoietic", sample_row[coll]))
    colr<-"hema. stem cell/progenitor"
  else if (grepl("lymphoid_progenitor", sample_row[coll]))
    colr<-"lym. progenitor"
  else if (grepl("myeloid_progenitor|macrophage_progenitor", sample_row[coll]))
    colr<-"mye. progenitor"
  else
    colr<-sample_row[coll]
  return(colr)
}

get_UMAP <- function(references.path, random_state, n_neighbors, min_dist){
  references_list<-list.files(path=references.path, pattern="MethylMatrix_binned")
  #Select common regions to references and samples ------------------------------
  refs <- process_files(references_list[[1]], references.path)
  num_references<-ncol(refs)-3
  refs.features<-refs[,4:ncol(refs)]
  ref <- data.frame(t(refs.features))
  
  
  m<- melt(refs.features)
  
  ggplot(data=m)+geom_density(aes(x=value, color=variable))+theme(legend.position="none")
  
  # Perform unsupervised clustering on references -------------------------------
  # Kmeans
  pca <- prcomp(t(refs.features))
  
  # UMAP
  UMAP=umap(t(refs.features), #pca$x, 
            random_state=random_state, #3
            n_neighbors= n_neighbors, #15,
            min_dist= min_dist, #0.1,
            metric = 'euclidean') #random state set for consistency
  UMAP_dims<-data.frame(UMAP$layout)
  UMAP_dims$sample<-factor(colnames(refs.features), levels=colnames(refs.features))
  UMAP_dims$tissue<-apply(X = UMAP_dims, MARGIN = 1, FUN = tissue_names, ncol(UMAP_dims))
  UMAP_dims$tissue<- factor(UMAP_dims$tissue, levels = c("macrophage", "monocyte", "dendritic",
                                                         "eosonophil", "neutrophil",
                                                         "erythroblast",
                                                         "Bcell", "NKell", "Tcell",
                                                         "hema. stem cell/progenitor", "lym. progenitor", "mye. progenitor",
                                                         "spleen",
                                                         "bladder",
                                                         "skin",
                                                         "kidney",
                                                         "liver",
                                                         "pancreas",
                                                         "intestine"))
  return(UMAP_dims)
}

UMAP_dims_golden <- get_UMAP(references.path = "../Reference_Methylomes/MethylMatrix/golden_markers/",
                             random_state = 1,
                             n_neighbors = 15,
                             min_dist=0.1)

ggplot(data=UMAP_dims_golden %>% arrange(tissue))+
  #stat_ellipse(geom="polygon",alpha=0.5, aes(x=X1, y=X2, fill=factor(cluster)), color='black')+scale_fill_manual(values=c(NA, NA, NA, NA))+
  geom_point(aes(x=X1, y=X2, fill=(tissue)), size=3, pch=21, color='black')+
  scale_fill_manual(values = as.vector(custom_palette))+
  #scale_color_gradient2(low='red', mid='purple', high='green', midpoint=5)+
  theme_bw()+xlab("UMAP1")+ylab("UMAP2")+
  theme(plot.background=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())+
  theme(axis.title=element_text(family="Helvetica", size=8),
        axis.text=element_text(family="Helvetica", size=6),
        plot.title=element_text(family="Helvetica", size=6))


UMAP_dims_golden$tissue <- factor(
  UMAP_dims_golden$tissue, levels = c(
    "neutrophil", "macrophage", "spleen", "monocyte", "Tcell", 
    "intestine", "NKell", "skin", "eosonophil", "mye. progenitor",
    "Bcell", "hema. stem cell/progenitor", "lym. progenitor", "erythroblast", "dendritic", 
    "bladder", "kidney", "liver", "pancreas"
  )
)

pdf(file="figures/UMAP_refs_golden_markers_colors_new.pdf",
    width=45/25.4, height=45/25.4, paper="special", bg="transparent",
    fonts="Helvetica", colormodel = "cmyk", pointsize=6)
ggplot(data=UMAP_dims_golden)+
  geom_point(aes(x=X1, y=X2, fill=(tissue)), size=3, pch=21, color='black')+
  #geom_text(aes(x=X1,y=X2, label=tissue))+
  scale_fill_manual(values = as.vector(ggthemes::tableau_color_pal(palette = 'Tableau 20')(19)))+
  #scale_fill_manual(values = UMAP_dims_golden$hex)+
  theme_alex()+xlab("UMAP1")+ylab("UMAP2")+
  theme(panel.background = element_blank(),
        #panel.border = element_blank(),
        panel.grid = element_blank(),
        axis.ticks=element_blank(),
        axis.text=element_blank(),
        axis.title = element_blank())
dev.off()

# Aggregate and save new color scheme for later ----

color_aggregate <- function(coll){
  rgbs <- data.frame(col2rgb(coll))
  means <- rowMeans(rgbs)

  hex <- rgb(means[1],
             means[2],
            means[3],
      maxColorValue = 255)
  return(hex)
}

tissues_and_colors <- UMAP_dims_golden[, c("tissue", "hex")]
tissues_and_colors <- aggregate(.~tissue, tissues_and_colors, color_aggregate)

fwrite(file = "/workdir/apc88/GVHD/tissue_hex_new.txt", x=tissues_and_colors, quote = FALSE, col.names = TRUE, sep = '\t')


dd <- fread('/workdir/apc88/GVHD/Alignment_analysis/sample_output/V1/binned_samples/golden_markers/BRIP01')
ggplot(data=dd)+geom_density(aes(x=dd$V4))




get_PCA <- function(references.path){
  references_list<-list.files(path=references.path, pattern="MethylMatrix_binned")
  #Select common regions to references and samples ------------------------------
  refs <- process_files(references_list[[1]], references.path)
  num_references<-ncol(refs)-3
  refs.features<-refs[,4:ncol(refs)]
  ref <- data.frame(t(refs.features))
  
  m<- melt(refs.features)

  # Perform unsupervised clustering on references -------------------------------
  # Kmeans
  pca <- prcomp(t(refs.features))
  pca <- data.frame(pca$x)
  PCA_dims<-data.frame(pca[, c('PC1', 'PC2')])
  PCA_dims$sample<-factor(colnames(refs.features), levels=colnames(refs.features))
  PCA_dims$tissue<-apply(X = PCA_dims, MARGIN = 1, FUN = tissue_names, ncol(PCA_dims))
  PCA_dims$tissue<- factor(PCA_dims$tissue, levels = c("macrophage", "monocyte", "dendritic",
                                                         "eosonophil", "neutrophil",
                                                         "erythroblast",
                                                         "Bcell", "NKell", "Tcell",
                                                         "hema. stem cell/progenitor", "lym. progenitor", "mye. progenitor",
                                                         "spleen",
                                                         "bladder",
                                                         "skin",
                                                         "kidney",
                                                         "liver",
                                                         "pancreas",
                                                         "intestine"))
  return(PCA_dims)
}

PCA_dims_golden <- get_PCA(references.path = "../Reference_Methylomes/MethylMatrix/golden_markers/")

# Coloring by UMAP coordinates -----

PCA_dims_golden$hex <- UMAP_dims_golden$hex
PCA_dims_golden$n <- UMAP_dims_golden$n

if(save_fig)pdf(file="../Figures/PCA_refs_golden_markers_colors_new.pdf",
                width=45/25.4, height=45/25.4, paper="special", bg="transparent",
                fonts="Helvetica", colormodel = "cmyk", pointsize=6)
ggplot(data=PCA_dims_golden)+
  geom_point(aes(x=PC1, y=PC2, fill=(n)), size=3, pch=21, color='black')+
  #geom_text(aes(x=X1,y=X2, label=tissue))+
  scale_fill_manual(values = PCA_dims_golden$hex)+
  theme_alex()+xlab("PC1")+ylab("PC2")+
  theme(panel.background = element_blank(),
        #panel.border = element_blank(),
        panel.grid = element_blank())
        #axis.ticks=element_blank(),
        #axis.text=element_blank(),
        #axis.title = element_blank())
if(save_fig)dev.off()