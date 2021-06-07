#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
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
my $minimum_seed_length = get_arg("ms", 10, \%args);
my $minimum_report_length = get_arg("mr", 1, \%args);
my $exact_match_length = get_arg("e", "", \%args);

my $r = int(rand(100000));
#my $r = "111";

#-------------------------------------------------------------
# Prepare files for blast and blast
#-------------------------------------------------------------
open(OUTFILE, ">tmp_$r");
open(OUTFILE_STAB, ">tmps_$r");
while(<$file_ref>)
#while(0)
{
  chop;

  my @row = split(/\t/);

  print OUTFILE ">$row[0]\n";
  print OUTFILE "$row[1]\n";

  print OUTFILE_STAB "$_\n";
}

system("stab2fasta.pl < $subsequences_file > tmp1_$r");

system("blast.pl tmp_$r -d tmp1_$r > tmp2_$r");

#-------------------------------------------------------------
# Collect blast results
#-------------------------------------------------------------
my %blast_results;
open(FILE, "<tmp2_$r");
while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  my $reverse = $row[8] > $row[9] ? 1 : 0;

  if ($row[3] >= $minimum_seed_length)
  {
    if ($reverse == 1)
    {
      $blast_results{$row[0]} .= "$row[1]\t$row[6]\t$row[7]\t$row[8]\t$row[9]\n";
      #print STDERR "Adding1 blast_results{$row[0]} .= $row[1]\t$row[6]\t$row[7]\t$row[8]\t$row[9]\n";
    }
    else
    {
      $blast_results{$row[0]} .= "$row[1]\t$row[6]\t$row[7]\t$row[8]\t$row[9]\n";
      #print STDERR "Adding1 blast_results{$row[0]} .= $row[1]\t$row[6]\t$row[7]\t$row[8]\t$row[9]\n";
    }
  }
}

#-------------------------------------------------------------
# Collect subsequences
#-------------------------------------------------------------
my $subsequences_str = `cat $subsequences_file`;
my @subsequences = split(/\n/, $subsequences_str);
my %subsequences_hash;
for (my $i = 0; $i < @subsequences; $i++)
{
  my @row = split(/\t/, $subsequences[$i]);

  $row[0] =~ /^([^ ]+)/;
  $row[0] = $1;

  $subsequences_hash{$row[0]} = $row[1];

  #print STDERR "subsequences_hash{$row[0]} = $row[1]\n";
}

#-------------------------------------------------------------
# Perform exact matches
#-------------------------------------------------------------
if (length($exact_match_length) > 0)
{
  open(INPUT_FILE, "<tmps_$r");
  while(<INPUT_FILE>)
  {
    chop;

    my @row = split(/\t/);

    print STDERR "Processing chromosome $row[0]\n";

    for (my $i = 0; $i < @subsequences; $i++)
    {
      my @line = split(/\t/, $subsequences[$i]);

      print STDERR "Processing subsequence $i: $line[0]\t$line[1]\n";

      for (my $j = 0; $j <= length($line[1]) - $exact_match_length; $j++)
      {
	my $sequence = substr($line[1], $j, $exact_match_length);
	my $search_sequence_end = $j + $exact_match_length - 1;

	my $main_sequence = $row[1];
	my $previous_length = 0;
	my $location = index($main_sequence, $sequence);
	while ($location != -1)
	{
	  my $sequence_start = $previous_length + $location;
	  my $sequence_end = $previous_length + $location + $exact_match_length - 1;

	  #print STDERR "Adding blast_results{$row[0]} .= $line[0]\t$sequence_start\t$sequence_end\t$j\t$search_sequence_end\n";
	  $blast_results{$row[0]} .= "$line[0]\t$sequence_start\t$sequence_end\t$j\t$search_sequence_end\n";

	  $main_sequence = substr($main_sequence, $location + 1);
	  $previous_length += $location + 1;
	  
	  $location = index($main_sequence, $sequence);
	}

	$sequence = &ReverseComplement($sequence);

	$main_sequence = $row[1];
	$previous_length = 0;
	$location = index($main_sequence, $sequence);
	while ($location != -1)
	{
	  my $sequence_start = $previous_length + $location;
	  my $sequence_end = $previous_length + $location + $exact_match_length - 1;

	  my $search_reverse_start = $search_sequence_end + 2;
	  my $search_reverse_end = $j + 2;
	  $blast_results{$row[0]} .= "$line[0]\t$sequence_start\t$sequence_end\t$search_reverse_start\t$search_reverse_end\n";
	  #print STDERR "Adding blast_results{$row[0]} .= $line[0]\t$sequence_start\t$sequence_end\t$search_reverse_start\t$search_reverse_end\n";

	  $main_sequence = substr($main_sequence, $location + 1);
	  $previous_length += $location + 1;
	  
	  $location = index($main_sequence, $sequence);
	}
      }
    }
  }
}

#-------------------------------------------------------------
# Expand to largest match
#-------------------------------------------------------------
open(INPUT_FILE, "<tmps_$r");
while(<INPUT_FILE>)
{
  chop;

  my @row = split(/\t/);

  #print STDERR "$row[0]\n";

  my @blasts = split(/\n/, $blast_results{$row[0]});
  for (my $i = 0; $i < @blasts; $i++)
  {
    my @blast = split(/\t/, $blasts[$i]);

    if ($i % 10 == 0)
    {
      my $num_blasts = @blasts;
      my $percent_done = &format_number(100 * $i / $num_blasts, 2);
      print STDERR "Expanding blast match $i of $num_blasts ($percent_done%)\n";
    }

    #print STDERR "$blasts[$i]\n";

    my $subsequence = $subsequences_hash{$blast[0]};
    my $subsequence_length = length($subsequence);
    my $reverse = $blast[3] > $blast[4] ? 1 : 0;

    if ($reverse == 1)
    {
      #print STDERR "PRE $subsequence\n$blast[1]\t$blast[2]\t$blast[3]\t$blast[4]\n";
      $subsequence = &ReverseComplement($subsequence);
      $blast[3] = $subsequence_length - ($blast[3] - 1);
      $blast[4] = $subsequence_length - ($blast[4] - 1);
      #print STDERR "POST $subsequence\n$blast[1]\t$blast[2]\t$blast[3]\t$blast[4]\n\n";
    }

    my $subsequence_start_point = $blast[3] - 1;
    my $sequence_start_point = $blast[1] - 1;

    my $subsequence_end_point = $blast[4] - 1;
    my $sequence_end_point = $blast[2] - 1;

    my $done = 0;
    while ($done == 0 and $subsequence_start_point > 0 and $sequence_start_point > 0)
    {
      my $subsequence_char = substr($subsequence, $subsequence_start_point - 1, 1);
      my $sequence_char = substr($row[1], $sequence_start_point - 1, 1);
      #print STDERR "SS=$subsequence_char S=$sequence_char\n";
      if ($subsequence_char eq "N" or $subsequence_char eq $sequence_char)
      {
	$subsequence_start_point -= 1;
	$sequence_start_point -= 1;
      }
      else
      {
	$done = 1;
      }
    }
    
    my $matched_sequence = "";
    my $matched_start = $sequence_start_point;
    my $matched_subsequence_start = $subsequence_start_point;
    $done = 0;
    while ($done == 0)
    {
      my $subsequence_char = substr($subsequence, $subsequence_start_point, 1);
      my $sequence_char = substr($row[1], $sequence_start_point, 1);
      #print STDERR "SS=$subsequence_char S=$sequence_char\n";

      if ($subsequence_char eq "N" or $subsequence_char eq $sequence_char)
      {
	$matched_sequence .= $sequence_char;
      }
      else
      {
	if (length($matched_sequence) >= $minimum_report_length)
	{
	  my $matched_end = $sequence_start_point - 1;
	  my $matched_subsequence_end = $subsequence_start_point - 1;
	  if ($reverse == 1)
	  {
	    $matched_subsequence_start = $subsequence_length - ($matched_subsequence_start - 1);
	    $matched_subsequence_end = $subsequence_length - ($matched_subsequence_end - 1);
	    print "$row[0]\t$blast[0]\t$matched_start\t$matched_end\t$matched_subsequence_start\t$matched_subsequence_end\t$matched_sequence\n";
	  }
	  else
	  {
	    print "$row[0]\t$blast[0]\t$matched_start\t$matched_end\t$matched_subsequence_start\t$matched_subsequence_end\t$matched_sequence\n";
	  }
	}

	$matched_sequence = "";
	$matched_start = $sequence_start_point + 1;
	$matched_subsequence_start = $subsequence_start_point + 1;

	if ($sequence_start_point > $sequence_end_point)
	{
	  $done = 1;
	}
      }
      
      $subsequence_start_point++;
      $sequence_start_point++;
    }
    
    if (length($matched_sequence) >= $minimum_report_length)
    {
      my $matched_end = $sequence_start_point - 1;
      my $matched_subsequence_end = $subsequence_start_point - 1;
      if ($reverse == 1)
      {
	$matched_subsequence_start = $subsequence_length - ($matched_subsequence_start - 1);
	$matched_subsequence_end = $subsequence_length - ($matched_subsequence_end - 1);
	print "$row[0]\t$blast[0]\t$matched_start\t$matched_end\t$matched_subsequence_start\t$matched_subsequence_end\t$matched_sequence\n";
      }
      else
      {
	print "$row[0]\t$blast[0]\t$matched_start\t$matched_end\t$matched_subsequence_start\t$matched_subsequence_end\t$matched_sequence\n";
      }
    }
  }
  
  #print STDERR "$blasts[$i]\n";
}

__DATA__

extract_sequence_location_by_blast.pl <file>

   Extracts the location of a sub-sequence from a given stab file

   -s <str>:  Stab file containing the subsequences to extract

   -m <num>:  Minimum blast seed size to expand (default: 10)
   -mr <num>: Minimum length of matched sequence to report (default: 1)

   -e <num>:  Search ourselves for exact matches with <num> and use these
              as seeds as well in addition to the Blast (default: no exact matches)

