#!/usr/bin/perl

use strict;
use List::Util qw[shuffle min max];

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAddG_EXE_DIR 		= "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs/";


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
my $debug = get_arg("D", 0, \%args);

# Step over all Locations ###########################################################

my $done = 0;
my $bunch_size = 1000;

while (!$done)
{
	my @dGduplexesInputArray = ();
	my @headerInputArray     = ();
	my $record;
	
	for (my $nlines=0; $nlines < $bunch_size; $nlines++)
	{
		if (!($record = <$file_ref>))
		{
			$done = 1;
			last;
		}
	
		chomp ($record);
		my @row = split(/\t/, $record);
		my $id = $row[0];
		my $seq1 = $row[1];
		my $seq2 = $row[2];
		
		push (@headerInputArray,     $id);
		push (@dGduplexesInputArray, join ("\t", $seq1, $seq2));
	}
	
	my  $arraySize = @headerInputArray;

	print STDERR "\nComputing $arraySize results: ";
	
	my @dGduplexesOutputArray = &getdGduplexes (@dGduplexesInputArray);
		
	for (my $i=0; $i < $arraySize; $i++)
	{
			# my ($mir_length, $target_length, $dGall, $dG5, $dG3) = split (/\t/, $dGduplexesOutputArray[$i]);
			# print $headerInputArray[$i] . "\t$mir_length\t$target_length\t$dGall\t$dG5\t$dG3\n";
			print $headerInputArray[$i] . "\t" . $dGduplexesOutputArray[$i] . "\n";
	}
}

print STDERR " Done.\n";


################################################################################

sub getdGduplexes {

	my @inArray = @_;
	my @outArray = ();
	
	open (SEQFILE, ">tmp_seqfile1") or die ("Could not open temporary sequence file.\n");
	
	my $insize = @inArray;
	
	foreach my $oneTarget (@inArray)
	{
		(my $seq1, my $seq2) = split (/\t/, $oneTarget);
		print SEQFILE "$seq1\n$seq2\n";
	}
	
	close (SEQFILE);


	# Call RNAduplex and extract result dGs and length
	
	my $cmd = "$RNAddG_EXE_DIR/RNAduplex -a 1 -D $debug < tmp_seqfile1";
	print STDERR "Calling RNAduplex with " . @inArray . " targets... ";

	my $result_of_cmd = `$cmd`;
	
	my @resArray = split (/\n/, $result_of_cmd);
	
	my $outsize = @resArray;
	
	if ($insize ne $outsize)
	{
		die "RNAduplex failure. Result was $result_of_cmd\n";
	}
	
	foreach my $resline (@resArray)
	{
		# my ($ret_structure, $ret_start_miR, $ret_end_miR, $ret_start_target, $ret_end_target, $ret_miR_len, $ret_target_len, $ret_dGall, $ret_dG5, $ret_dG3) = split (/\t/, $resline);
		# push (@outArray, join ("\t", $ret_miR_len, $ret_target_len, $ret_dGall, $ret_dG5, $ret_dG3));
		push (@outArray, $resline);
	}
	
	return @outArray;
}


################################################################################


__DATA__

RNAduplex.pl <file>

	Compute the structure upon hybridization of two RNA strands. The input is assumed
	to consist of an ID column, followed by two RNA sequences to be hybrid.
	
	Output columns are ID, hybridization structure, start and end coordinates of the
	hybridization on the first and second sequences, lengths of the hybridization
	on the first and second sequences, total energy, 5' energy and 3' energy (used
	for microRNA binding).
	

     
 