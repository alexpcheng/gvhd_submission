#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $merge = get_arg("merge", 0, \%args);


while (<$file_ref>)
{
	chomp;
		
	my ($chrom, $start, $end, $name, $score, $strand, $thickStart, $thickEnd, $itemRgb, $blockCount, $blockSizes, $blockStarts) = split("\t");
		
	my $tlength = abs ($end - $start) + 1;
	
	$blockSizes  =~ s/\"//g;
	$blockStarts =~ s/\"//g;
	$itemRgb     =~ s/\"//g;
	
	my @blockSize  = split (",", $blockSizes);
	my @blockStart = split (",", $blockStarts);
	
	my @gBlockS;
	my @gBlockE;
	
	if ($strand eq "+")
	{
		for (my $i=0; $i < $blockCount; $i++)
		{
			push (@gBlockS, $blockStart[$i] + $start);
			push (@gBlockE, $blockStart[$i] + $blockSize[$i] + $start);		
		}
	}
	else
	{
		for (my $i=0; $i < $blockCount; $i++)
		{
			push (@gBlockE, $end - $blockStart[$i]);
			push (@gBlockS, $end - ($blockStart[$i] + $blockSize[$i]));		
		}
	}
	
	print "$chrom\t$strand\t$name\t$thickStart\t$thickEnd\t$blockCount\t";
	print join ",", @gBlockS;
	print "\t";
	print join ",", @gBlockE;
	print "\t0\n";
}	

__DATA__

bed2est.pl

    Take an input BED file and convert it to an EST format.
    
    For BED format see for example: http://genome.ucsc.edu/FAQ/FAQformat#format1
    
    -merge:		Merge any overlapping exons into a single exon.

    


