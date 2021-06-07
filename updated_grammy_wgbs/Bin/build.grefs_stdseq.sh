#!/bin/bash

fasta=$1
taxid=$2
ext=$3
# retrieve gis for a particular taxid
awk -v v1=$taxid '$2==v1' $fasta.gis.taxids$ext | cut -f 1 > temp.gis.$taxid$ext
# Create directory for each taxid
mkdir -p grefs/$ext/$taxid
# retrieve gis for a particular taxid
# it not possible to query a database for a specific taxid
blastdbcmd -db $fasta$ext.curated -entry_batch temp.gis.$taxid$ext > grefs/$ext/$taxid/genomes.fna
rm temp.gis.$taxid$ext
