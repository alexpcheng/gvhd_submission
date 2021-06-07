#!/bin/bash

infile=$1
stat=$2
sample=$3

COUNT=$(echo `cat $infile | wc -l`/4 | bc)
echo -e  $sample"\t"$stat"\t"$COUNT
