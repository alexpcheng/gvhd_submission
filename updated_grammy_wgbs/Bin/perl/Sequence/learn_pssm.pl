#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

#my $word_length = get_arg("n", 5, \%args);

my @pssm;
my @lendist;
my $maxlen = 0;
my $nseqs = 0;

# Read sequences and aggregate bases

while(<$file_ref>)
{
	chomp;
	(my $id, my $sequence) = split(/\t/);

	$sequence =~ tr/ACGTUacgtu/0123301233/;
	
	for (my $i=0; $i < length ($sequence); $i++)
	{
		$pssm[$i][substr($sequence,$i,1)]++;
	}

	$lendist[length($sequence)-1]++;

	$maxlen = length($sequence) > $maxlen ? length($sequence) : $maxlen;
	$nseqs++;
}

# Normalize by number of readings per position
for (my $pos=0; $pos<$maxlen; $pos++)
{
	my $readings = $pssm[$pos][0] + $pssm[$pos][1] + $pssm[$pos][2] + $pssm[$pos][3];
	if ($readings)
	{
		$pssm[$pos][0] /= $readings;	
		$pssm[$pos][1] /= $readings;
		$pssm[$pos][2] /= $readings;
		$pssm[$pos][3] /= $readings;
	}	
}

# Print results

for (my $pos=0; $pos<$maxlen; $pos++)
{
	print $pos+1 . "\t" . $pssm[$pos][0] . "\t" . $pssm[$pos][1] . "\t" . 
		  $pssm[$pos][2] . "\t" . $pssm[$pos][3] . "\t" . 
		  ($lendist[$pos] / $nseqs) . "\n";
}



__DATA__

learn_pssm.pl <file>

   Takes in a stab sequence file learns its PSSM and sequence length 
   distribution.
   
   The output is a tab delimited file containing the following information:
   <counter> <p(A)> <p(C)> <p(G)> <p(T or U)> <p(length=counter)> 

