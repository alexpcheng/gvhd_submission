#!/bin/bash

dupfile=$1
nodupfile=$2
sample=$3

COUNTWITHDUP=$(samtools view -c $dupfile)
COUNTNODUP=$(samtools view -c $nodupfile)
NODUPFRAC=$(echo "scale=5; $COUNTNODUP/$COUNTWITHDUP" | bc)

echo -e  $sample"\tnon-duplicate_fraction\t"$NODUPFRAC


