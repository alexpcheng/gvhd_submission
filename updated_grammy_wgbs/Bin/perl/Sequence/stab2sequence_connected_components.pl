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

my $max_alignment = get_arg("a", 1, \%args);
my $max_alignment_mismatches = get_arg("am", 0, \%args);
my $max_mismatches = get_arg("m", 1, \%args);

my @sequences;
my %all_sequences;

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  if (length($all_sequences{$row[1]}) == 0)
  {
    push(@sequences, $row[1]);

    $all_sequences{$row[1]} = 1;
  }
}

for (my $i = 0; $i < @sequences; $i++)
{
  my $sequence1 = $sequences[$i];

  my @other_sequences;
  my @other_sequences_alignment;
  my @other_sequences_mismatches;
  my $max_sequence1_alignment = 0;

  for (my $j = 0; $j < @sequences; $j++)
  {
    my $sequence2 = $sequences[$j];

    if ($i != $j)
    {
      my $num_mismatches = &ComputeMismatchesBetweenAlignedSequences($sequence1, 0, length($sequence1) - 1, $sequence2, 0, $max_mismatches, 0);
      if ($num_mismatches != -1)
      {
	push(@other_sequences, $sequence2);
	push(@other_sequences_alignment, 0);
	push(@other_sequences_mismatches, $num_mismatches);
      }
      else
      {
	my @alignment = &AlignSequences($sequence1, $sequence2, $max_alignment, $max_alignment_mismatches, $max_alignment);
	if (length($alignment[0]) > 0)
	{
	  push(@other_sequences, $sequence2);
	  push(@other_sequences_alignment, $alignment[0]);
	  push(@other_sequences_mismatches, $alignment[1]);

	  if ($alignment[0] > $max_sequence1_alignment)
	  {
	    $max_sequence1_alignment = $alignment[0];
	  }
	}
      }
    }
  }

  print "$sequence1\t$sequence1\t0\t0\t";
  for (my $j = 0; $j < $max_sequence1_alignment; $j++)
  {
    print " ";
  }
  print "$sequence1\n";

  for (my $j = 0; $j < @other_sequences; $j++)
  {
    my $other_sequence = $other_sequences[$j];
    print "$sequence1\t$other_sequence\t$other_sequences_alignment[$j]\t$other_sequences_mismatches[$j]\t";

    if ($other_sequences_alignment[$j] >= 0)
    {
      for (my $k = 0; $k < $max_sequence1_alignment - $other_sequences_alignment[$j]; $k++)
      {
	print " ";
      }
    }
    else
    {
      for (my $k = 0; $k < $max_sequence1_alignment - $other_sequences_alignment[$j]; $k++)
      {
	print " ";
      }
    }
    print "$other_sequence\n";
  }
}

__DATA__

stab2sequence_connected_components.pl <file>

   clusters sequences from a stab file together according to distances bewteen them

   -a <num>:   The maximum number of bp alignment movements between sequences (default: 1)
   -am <num>:  The maximum number of bp mutations allowed when aligning (default: 0)
   -m <num>:   The maximum number of bp mutations between sequences when not changing alignment (default: 1)

