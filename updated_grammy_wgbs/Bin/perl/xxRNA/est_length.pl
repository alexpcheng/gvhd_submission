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

while (<$file_ref>)
{
	chomp;
	
	my ($chrom, $strand, $name, $tstart, $tend, $AccCount, $exstarts, $exends, $exoccurrence) = split("\t");
	
	my $tlength = abs ($tend - $tstart) + 1;
	
	my @exonS = split (",", $exstarts);			@exonS = grep /\S/, @exonS;
	my @exonE = split (",", $exends);			@exonE = grep /\S/, @exonE;
	my $nExons = scalar @exonS;
	my $total_length = 0;
	
	for (my $i=0; $i< $nExons; $i++)
	{
		$total_length += ($exonE[$i] - $exonS[$i]) + 1;
	}
	
	print "$tlength\t$total_length\t$nExons\t$_\n";
}	

__DATA__

est_length.pl

    Take an EST file and add two columns to it's beginning representing the
    transcript span and the total total transcript length (obtained by summing
    the size of exons).

