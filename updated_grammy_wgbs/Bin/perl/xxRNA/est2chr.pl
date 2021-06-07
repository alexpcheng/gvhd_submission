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
my $no_overlap = get_arg("nol", 0, \%args);
my $half_open = get_arg("ho", 0, \%args);


while (<$file_ref>)
{
	chomp;

	my ($chrom, $strand, $name, $tstart, $tend, $AccCount, $exstarts, $exends, $exoccurrence) = split("\t");
	
	$chrom =~ s/chr//g;
	
	my @exonS = split (",", $exstarts);			@exonS = grep /\S/, @exonS;
	my @exonE = split (",", $exends);			@exonE = grep /\S/, @exonE;
	my @value = split (",", $exoccurrence);		@value = grep /\S/, @value;
	my $nExons = scalar @exonS;
	
	my $outputline = "";
	my $exclude = 0;
	
	for (my $i=0; $i< $nExons; $i++)
	{
		my $curline = "$chrom\t$name" . "_" . $strand . ($i+1) . "\t" . SE ($exonS[$i], $exonE[$i], $strand) . "\t1\t" . $value[$i] . "\n";

		if ($strand eq "+")
		{
			$outputline = $outputline . $curline;
		}
		else
		{
			$outputline = $curline . $outputline;		
		}
		
		if ($no_overlap and ($i>0))
		{
			if ($exonS[$i] < $exonE[$i-1])
			{
				print STDERR $name . "\tExon " . ($i-1) . " and $i overlap!\n";
				$exclude = 1;
			}
		}
	}
	
	if (!$exclude)
	{
		print $outputline;
	}
}	

################################
sub SE {

	my ($start, $end, $strand) = @_;

	if ($strand eq "+")
	{
		return ($start + 1) . "\t" . ($end + 1 - $half_open);	
	}
	else
	{
		return ($end + 1 - $half_open) . "\t" . ($start + 1);
	}
}

__DATA__

est2chr.pl

    Take an EST file and convert it to a chr file containing a line
    for each exon described in the input EST.
    
    The ID of the newly created chr lines is the original ID from the
    EST file, followed by the exon number.
    
    -nol:	No Over-lap. Exclude any EST lines that have overlapping exons.

    -ho:	Half-open. Assumes EST end coordinates are 1 base larger (exclusive).

