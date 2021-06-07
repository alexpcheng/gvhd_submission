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

my $polytract_sequences_str = get_arg("s", "A,T", \%args);
my $multiple_nucs =  get_arg("multi", "", \%args);

my $minimum_count = get_arg("m", "12", \%args);
my $mismatches_allowed = get_arg("mm", "0", \%args);
my $exact_mismatches = get_arg("mm_exact", "0", \%args);
my $print_mismatches_count = get_arg("print_mm", "0", \%args);
my $one_based = get_arg("1", "0", \%args);

if ($one_based) {$one_based=1}

my @polytract_sequences = split(/\,/, $polytract_sequences_str);

my %alphabet_hash;
my @alphabet;
for (my $i = 0; $i < @polytract_sequences; $i++)
{
    if ($multiple_nucs) {
	$alphabet_hash{$polytract_sequences[$i]} = 1;
    }
    else {
	$alphabet_hash{$polytract_sequences[$i]} = $i;
    }
    push(@alphabet, $polytract_sequences[$i]);
    #print STDERR "alphabet[$i] = $polytract_sequences[$i]\n";
}


my $buffer_size=10000000;
my $buffer="";
my $buffer_position=$buffer_size;

my $id = 1;
my $finished=0;
my $char;

while(($char=read_file()) ne "")
{
  my $chr="";
  while($char ne "\t"){
      $chr.=$char;
      $char=read_file();
  }

  my @mismatches_counts;
  my @sequence_counts;
  my $mismatch_tail=0;
  my $sequence_position=0;

  $char=read_file();
  while($char ne "\n"){
    my $index = $alphabet_hash{$char};
    if (length($index) == 0) { $index = -1; }

    for (my $j = 0; $j < @alphabet; $j++)
    {
      if ($j == $index or ($mismatches_counts[$j]<$mismatches_allowed and $sequence_counts[$j]>=1))
      {
	if ($j != $index) {
	  $mismatches_counts[$j]++;
	  $mismatch_tail++;
	}
	else{
	  $sequence_counts[$j]++;
	  $mismatch_tail=0;
	}
      }
      else
      {
	if ($sequence_counts[$j] >= $minimum_count)
	{
	  $mismatches_counts[$j]-=$mismatch_tail;
	  my $end = $sequence_position - $mismatch_tail - 1;
	  my $start = $end - $sequence_counts[$j] - $mismatches_counts[$j] + 1;
          $end+=$one_based;
          $start+=$one_based;
	  if(!$exact_mismatches or ($exact_mismatches and $mismatches_counts[$j]==$mismatches_allowed)){
	    print "$chr\t$id\t$start\t$end\tpoly$alphabet[$j]_$sequence_counts[$j]\t$sequence_counts[$j]";
	    if ($print_mismatches_count) { print "\t$mismatches_counts[$j]" }
	    print "\n";
	    $id++;
	  }
	}
	$mismatch_tail=0;
	$mismatches_counts[$j] = 0;
	$sequence_counts[$j] = 0;
      }
    }
    $char=read_file();
    $sequence_position++;
  }

  for (my $j = 0; $j < @alphabet; $j++)
  {
    if ($sequence_counts[$j] >= $minimum_count)
    {
      $mismatches_counts[$j]-=$mismatch_tail;
      my $end = $sequence_position - $mismatch_tail - 1 ;
      my $start = $end - $sequence_counts[$j] - $mismatches_counts[$j] + 1;
      $end+=$one_based;
      $start+=$one_based;
      if(!$exact_mismatches or ($exact_mismatches and $mismatches_counts[$j]==$mismatches_allowed)){
	print "$chr\t$id\t$start\t$end\tpoly$alphabet[$j]_$sequence_counts[$j]\t$sequence_counts[$j]";
	if ($print_mismatches_count) { print "\t$mismatches_counts[$j]" }
	print "\n";
	$id++;
      }
    }
  }
}


sub read_file{
  $buffer_position++;
  if ($buffer_position>=$buffer_size){
    $buffer_position=0;
    read $file_ref,$buffer,$buffer_size;
  }
  return substr $buffer,$buffer_position,1;
}


__DATA__

extract_polytracts.pl <file>

   Extracts locations of polytracts from a stab file.
   NOTE: Found polytracts will be mutually exclusive.

   -s <str>:  Extract consecutive patches of either character (default: A,T)
              NOTE: each character is counted separately (i.e., A,T is poly-A OR poly-T tracts)

   -multi:    Allow a polytract consisting of any of the given letters (e.g., ATTATAT for -s A,T)

   -m <num>:  Minimum number of characters that need to occur within the window (default: 12)

   -mm <num>: Maximum number of mismatches allowed (default: 0)
              NOTE: requires using only one character type in -s .
              NOTE: matches are never allowed to start or end with a mismatch.

   -mm_exact: Together with -mm prints only polytracts that have EXACTLY <num> mismatches

   -print_mm: for each polytract found, print number of mismatches.

   -1:        one-based coordinates (default: zero-based)
   
