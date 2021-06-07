#!/bin/bash

infile=$1
chromosome=$2
sample=$3
datafile=$4

DEPTH=$(samtools depth $infile -r $chromosome | awk '{sum+=$3;cnt++}END{print sum}')
SIZE=$(awk -v chr=$chromosome '{if ($1 == chr) print $2}' $datafile)
COVER=$(echo "scale=5; $DEPTH/$SIZE" | bc)

echo -e  $sample"\t"$chromosome"_coverage\t"$COVER


