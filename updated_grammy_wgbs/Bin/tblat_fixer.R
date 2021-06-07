### tblat_fixer.R


# Description: Used to create a table an alignment table.
# with combined and matched reads, and eliminate duplicate sequences.

# Input files: {sample}.tblat.0, {sample}.match.tblat, tblat.combo.tblat

# Output files: {sample}.tblat.1

#Library
if (!require('data.table')) install.packages('data.table')
library(data.table)

#Function
reformat_tblat = function(old.tblat, sub.tblat){
  
  tblat.2 = merge(old.tblat, sub.tblat, by = c("sReadID", "TaxID"), all.x = T)
  tblat.2$GI.x = tblat.2$GI.y ;
  #tblat.2$CommonName.x = tblat.2$CommonName.y ;
  #tblat.2$Kingdom.x = tblat.2$Kingdom.y ;
  
  tblat.3 = tblat.2[,2:16] ;
  tblat.4 = cbind(tblat.3[,2:13], tblat.3[,14:15], tblat.3$TaxID) ;
  colnames(tblat.4) = header ;
  
  return(tblat.4) ;
}


#
args = commandArgs(trailingOnly=TRUE)
tblat.0 = args[[1]]
tblat.m = args[[2]]
tblat.c = args[[3]]


#dir = as.character(args[1]) ; #"~/Downloads/"
#sample = as.character(args[2]) ; #"PS50short"

#header = c("ReadID", "GI", "PercMatch", "LenMatch", 
 #          "M1","M2","M3", "LenMatch2","PosStart", 
  #         "PosEnd", "EValue", "Length", "TaxID", 
   #        "CommonName", "Kingdom", "LenMatch3") ;

header = c("ReadID", "GI", "PercMatch", "LenMatch",
           "M1", "M2", "M3", "LenMatch2", "PosStart",
           "PosEnd", "EValue", "Length", "LenMatch3", "strand", "TaxID")

# read in files
#tblat.1 = data.frame(fread(paste0(dir,"/", sample, ".tblat.0"))) ;
#tblat.match = data.frame(fread(paste0(dir, "/", sample, ".match.tblat"))) ;
#tblat.combo = data.frame(fread(paste0(dir, "/", sample, ".combo.tblat"))) ;

tblat.1 = fread(tblat.0, data.table = FALSE)
tblat.match = fread(tblat.m, data.table = FALSE)
tblat.combo = fread(tblat.c, data.table = FALSE)
colnames(tblat.1) = colnames(tblat.match) = colnames(tblat.combo) = header ;

#sub.tblat.1 = subset.data.frame(tblat.1, select = c("ReadID", "GI", "TaxID", "CommonName", "Kingdom")) ;
sub.tblat.1 = subset.data.frame(tblat.1, select=c("ReadID", "GI", "TaxID"))

sub.tblat.1$sReadID = gsub("-.$","",sub.tblat.1$ReadID) ;
sub.tblat.1 = unique(sub.tblat.1[,-1]) ;

tblat.match$sReadID = gsub("-M$","",tblat.match$ReadID) ;

tblat.ref.match = reformat_tblat(tblat.match, sub.tblat.1) ;

tblat.merge = rbind(tblat.ref.match, tblat.combo) ;


tblat = tblat.merge[order( tblat.merge[,11], tblat.merge[,4],decreasing = T ),] ;
tblat.final = tblat[!duplicated(tblat$ReadID),] ;

write.table(x = tblat.final,file = paste0(dir,"/",sample,".tblat.1"), 
            sep = "\t", quote = F, row.names = F, col.names = F) 
