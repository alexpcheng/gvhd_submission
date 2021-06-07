library(data.table)

args = commandArgs(trailingOnly=TRUE)

bam = args[1]
blast = args[2]
out = args[3]
sam = args[4]
bam = fread(bam, col.names = c('read_id', 'taxid', 'contig'))
bam$in_bam <- "YES"
blast = fread(blast, col.names = c('read_id', 'taxid', 'contig'))
blast$in_blast <- "YES"

if (nrow(bam) ==1 & ncol(bam)==1){
  df <- blast
  df$in_bam <- NA
}else{
  df <- merge(blast, bam, by=c('read_id', 'taxid', 'contig'), all=TRUE)
}
df$sample <- sam
fwrite(x=df, file = out, sep = '\t', na = 'NA', col.names=TRUE, quote=FALSE)
