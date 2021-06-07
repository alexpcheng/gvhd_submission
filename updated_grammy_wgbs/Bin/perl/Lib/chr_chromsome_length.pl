#!/usr/bin/perl

use strict;


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $chr="";
my $end;
my $start;
my $i=0;
while(<STDIN>){
  chomp;
  my @row=split/\t/;
  if ($row[0] ne $chr){
    if ($chr ne "") {
      print $chr,"\t",$i,"\t",$start,"\t",$end,"\n";
    }
    $chr=$row[0];
    $end=0;
    $start=$row[2]<$row[3]?$row[2]:$row[3];
    $i++;
  }
  my $max=$row[2]>$row[3]?$row[2]:$row[3];
  if ($max>$end){
    $end=$max;
  }
}
print $chr,"\t",$i,"\t",$start,"\t",$end,"\n";

__DATA__

chr_chromsome_length.pl

extracts chromsome lengths from chr file, assumes chr sorted by
1st col and then min(3rd,4th).


