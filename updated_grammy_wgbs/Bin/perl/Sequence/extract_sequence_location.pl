#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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

my $subsequences_file = get_arg("s", "", \%args);
my $check_reverse_complement = get_arg("r", 0, \%args);
my $one_based = get_arg("1", 0, \%args);
my $regexp = get_arg("re", 0, \%args);
my $mismatches = get_arg("mm", 0, \%args);
my $report_mm = get_arg ("rmm", 0, \%args);
my $mismatches_exact = get_arg("mm_exact", 0, \%args);

my @subsequences;
if (length($subsequences_file) > 0)
{
    open(SUBSEQUENCES, "<$subsequences_file");
    while(<SUBSEQUENCES>)
    {
	chop;

	#print STDERR "Pushing $_\n";

	push(@subsequences, $_);
    }
}

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    foreach my $subsequence (@subsequences)
    {
	my @sequence = split(/\t/, $subsequence);
	my $sequence_length = length($sequence[1]);

	my $main_sequence = $row[1];

	&FindLocations($row[0], $main_sequence, $sequence[0], $sequence[1], $sequence_length, 0, $mismatches);

	if ($check_reverse_complement == 1)
	{
	  &FindLocations($row[0], $main_sequence, $sequence[0], &ReverseComplement($sequence[1]), $sequence_length, 1, $mismatches);
	}
    }
}



sub FindLocations
{
  my ($name, $main_sequence, $sequence_name, $sequence, $sequence_length, $is_reverse, $mismatches) = @_;

  if ($mismatches<1){
    $_ = $main_sequence;
    
    while ($regexp?m/($sequence)/g:m/(\Q$sequence\E)/g)
      {
	my $sequence_end = (pos) - 1 ;
	my $sequence_start = $sequence_end - length($1) + 1 ;
	
	pos = ($sequence_start+1);
	
	if ($one_based == 1)
	  {
	    $sequence_start++;
	    $sequence_end++;
	  }
	
	if ($is_reverse == 0)
	  {
	    print "$name\t$sequence_name\t$sequence_start\t$sequence_end\t$1";
	  }
	else
	  {
	    print "$name\t$sequence_name\t$sequence_end\t$sequence_start\t$1";
	  }
	  if ($report_mm) { print "\t0"; }
	  print "\n";
      }
  }
  else{
    my $current_position=0;

    while (length(my $target=substr($main_sequence,$current_position,$sequence_length))==$sequence_length){
      my $mismatch_count=0;
      for my $i (0..$sequence_length-1){
	if((substr($target,$i,1)) ne (substr($sequence,$i,1))){
	  $mismatch_count++;;
	}
      }
      if (($mismatch_count<=$mismatches and !$mismatches_exact) or ($mismatch_count==$mismatches and $mismatches_exact)){
	my $sequence_start=$current_position;
	my $sequence_end=$sequence_start+$sequence_length-1;
	if ($is_reverse == 0)
	  {
	    print "$name\t$sequence_name\t$sequence_start\t$sequence_end\t$target";
	  }
	else
	  {
	    print "$name\t$sequence_name\t$sequence_end\t$sequence_start\t$target";
	  }
	  if ($report_mm) { print "\t$mismatch_count"; }
	  print "\n";
      }
      $current_position++;
    }
  }
}


__DATA__

extract_sequence_location.pl <file>

   Extracts the location of a sub-sequence from a given stab file

   -s <str>:  File containing the subsequences to extract in the format:
              name<tab>sequence

   -r:        Also check the reverse complement of the sequence

   -1:        Print results in 1-based

   -re:       Allows usage of perl-style regular expressions as search strings, e.g.
              searching for "A.G" will find all 3mers starting with A and ending with G.
              NOTE: this may occassionally conflict with -r, since -r reverses the
              string, so "A[AC]A" will become "T]GT[T" which is not a valid expression.

   -mm <num>: Allow no more than <num> mismatches (no indels), currently doesnt work together with -re.
   -rmm     : Report number of mismatches for that hit (as additional column).

   -mm_exact: Together with -mm prints only matching sequences that have EXACTLY <num> mismatches.

