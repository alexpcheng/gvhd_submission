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

my $r=int(rand(10000));

my $coordinates = get_arg("c", "tmp_$r" . "_coord", \%args);
my $genome = get_arg("g", "", \%args);
my $debug  = get_arg("debug", 0, \%args);
my $chromosomes = get_arg("chr", "", \%args);

my $min3  = get_arg("min3", 0, \%args);
my $min5  = get_arg("min5", 0, \%args);
my $pred3  = get_arg("pred3", 0, \%args);
my $pred5  = get_arg("pred5", 0, \%args);

open COORDINATES, "> tmp_$coordinates" or die "Can't open tmp_$coordinates : $!";

print STDERR "Building coordinate lists... ";

while (<$file_ref>)
{
	chomp;

	my ($bin, $name, $chrom, $strand, $txStart, $txEnd, $cdsStart, $cdsEnd, $exonCout, $exonStarts, $exonEnds, $id, $name2, $cdsStartStat, $cdsEndStat, $exonFrames) = split("\t");
	
	$chrom =~ s/chr//g;
	
	if ($strand eq "+")
	{
		printLocations ($name, $chrom, "5UTR", $txStart, $cdsStart, $exonStarts, $exonEnds, $strand, $min5, $pred5);
		printLocations ($name, $chrom, "CDS", $cdsStart, $cdsEnd, $exonStarts, $exonEnds, $strand, 0, 0);
		printLocations ($name, $chrom, "3UTR", $cdsEnd, $txEnd, $exonStarts, $exonEnds, $strand, $min3, $pred3);
	}
	else
	{
		printLocations ($name, $chrom, "5UTR", $cdsEnd, $txEnd, $exonStarts, $exonEnds, $strand, $min5, $pred5);
		printLocations ($name, $chrom, "CDS", $cdsStart, $cdsEnd, $exonStarts, $exonEnds, $strand, 0, 0);
		printLocations ($name, $chrom, "3UTR", $txStart, $cdsStart, $exonStarts, $exonEnds, $strand, $min3, $pred3);	
	}
}	

close COORDINATES;

if ($chromosomes ne "")
{
	system ("cat tmp_$coordinates | filter.pl -c 0 -estr_list \"$chromosomes\" > $coordinates");
	system ("rm -rf tmp_$coordinates");
}
else
{
	system ("mv tmp_$coordinates $coordinates");
}

if ($genome ne "")
{
	print STDERR "   OK.\nExtracting sequence from $genome... ";
	system ("extract_sequence.pl -dn -f $coordinates < $genome > tmp_$r" . "_seq1");
	
	print STDERR "   OK.\nMerging sequences... ";
	system ("cat tmp_$r" . "_seq1 | modify_column.pl -c 0 -splt_d \"\\|\" | merge_columns.pl -d \"|\" | cut -f 1,3 | average_rows.pl -list -delim \",\" -n | modify_column.pl -c 2 -rmre \",\" | modify_column.pl -c 1 -splt_d \"\\|\" | cut.pl -f 2,4,3,1 > tmp_$r" . "_merged");
	
	print STDERR "   OK.\nConstructing output... ";
	system ("cat tmp_$r" . "_merged");
}


if ($debug == 0)
{
	system ("rm -rf tmp_$r" . "_*");
}

print STDERR "   OK.\n";

################################
sub printLocations {

	my ($id, $chrom, $type, $start, $end, $exonStarts, $exonEnds, $strand, $minLength, $predLength) = @_;
	
	my @exonS = split (",", $exonStarts);
	my @exonE = split (",", $exonEnds);

	my $firstExon = -1;
	my $lastExon = -1;
	my $nExons = scalar @exonS;
	my $byPrediction = 0;

	if ($end - $start < $minLength)
	{
		if (!$predLength) { return; }
		
		my $predStart;
		my $predEnd;
		
		# Create a prediction of the given length
		if ( (($type eq "5UTR") && ($strand eq "+")) || (($type eq "3UTR") && ($strand eq "-")) )
		{
			$predStart = $end - $predLength;
			$predEnd = $end;
		}
		else
		{
			$predStart = $start;
			$predEnd = $start + $predLength;
		}
		
		$byPrediction = 1;
		
		$start = $predStart;
		$end = $predEnd;
		
		$type = "P" . $type;
	}	
	
	#print STDERR "Searching $id ($start to $end) on $nExons exons ... \n";
	
	if (!$byPrediction)
	{
		# Find first segment
		for (my $i=0; $i< $nExons; $i++)
		{
			#print STDERR "Checking $i: $exonS[$i] to $exonE[$i]...\n";
			
			if ( ($exonS[$i] >= $start) || ($exonE[$i] >= $start) )
			{
				$firstExon = $i;
				last;
			}
		}
		
		# Find last segment
		for (my $i = $nExons-1; $i>=0; $i--)
		{
			#print STDERR "Checking $i: $exonS[$i] to $exonE[$i]...\n";
	
			if ( ($exonS[$i] <= $end) )
			{
				$lastExon = $i;
				last;
			}
		}
		
		if ( ($firstExon == -1) || ($lastExon == -1) )
		{
			print STDERR "Error pasing $id ($type)\n";
			print STDERR "First is $firstExon; Last is $lastExon\n";
			exit;
		}
	}	
	# Print the locations
	
	if ($firstExon == $lastExon)
	{
		print COORDINATES "$chrom\t$id" . "|" . $type . "|" . ($firstExon+1) . "\t" . SE($start, ($end-1), $strand) . "\n";
		return;
	}
	
	
	if ($strand eq "+")
	{
		print COORDINATES "$chrom\t$id" . "|" . $type . "|" . ($firstExon+1) . "\t" . SE($start, ($exonE[$firstExon]-1), $strand) . "\n";
		
		for (my $i=$firstExon+1; $i<$lastExon; $i++)
		{	
			print COORDINATES "$chrom\t$id" . "|" . $type . "|" . ($i+1) . "\t" . SE ($exonS[$i], ($exonE[$i]-1), $strand) . "\n";
		}
	
		print COORDINATES "$chrom\t$id" . "|" . $type . "|" . ($lastExon+1) . "\t" . SE ($exonS[$lastExon], ($end-1), $strand) . "\n";
	}
	else
	{
		print COORDINATES "$chrom\t$id" . "|" . $type . "|" . ($lastExon+1) . "\t" . SE ($exonS[$lastExon], ($end-1), $strand) . "\n";	
		
		for (my $i=$lastExon-1; $i>$firstExon; $i--)
		{	
			print COORDINATES "$chrom\t$id" . "|" . $type . "|" . ($i+1) . "\t" . SE ($exonS[$i], ($exonE[$i]-1), $strand) . "\n";
		}

		print COORDINATES "$chrom\t$id" . "|" . $type . "|" . ($firstExon+1) . "\t" . SE($start, ($exonE[$firstExon]-1), $strand) . "\n";	
	}
}

################################
sub SE {

	my ($start, $end, $strand) = @_;

	if ($strand eq "+")
	{
		return ($start + 1) . "\t" . ($end + 1);	
	}
	else
	{
		return ($end + 1) . "\t" . ($start + 1);
	}
}

__DATA__

refGene2sequences.pl

    Take a refGene UCSC file and output the sequences associated with
    each gene 5' UTR, coding sequence and 3' UTR.
    
    -c <string>   Filename where to save the extracted coordinates. If not given, then
                  a temporary file is used and deleted when program ends.
                  
                  NOTE: coordinates in this file are 1-based, although the input refGene
                        file is 0-based.
                  
    -g <string>   Genome file name (STAB format).
    
    -chr <string> List of choromosomes from which sequences should be extracted. For
                  example "2L;2R;3L". If omitted, all choromosomes are processed.
                 
