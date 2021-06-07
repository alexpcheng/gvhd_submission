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

my $start_position = get_arg("s", 0, \%args);
my $end_position = get_arg("e", -1, \%args);
my $binary_matrix = get_arg("b", 0, \%args);
my $exclude_positions_by_consensus = get_arg("x", "", \%args);

$end_position =~ s/\"//g;

my %counts;
my %alignment;
my @proteins;
my $alignment_length = 0;

while(<$file_ref>)
{
  chop;

  /[ ]*([^ ]+)[ ][ ]([^ ]*)/;

  my $protein = $1;
  my $sequence = $2;

  push(@proteins, $protein);

  my $end = $end_position == -1 ? length($sequence) : $end_position + 1;

  for (my $i = $start_position; $i < $end; $i++)
  {
    my $element = substr($sequence, $i, 1);
    $counts{$i}{"$element"}++;
    $alignment{"$protein"}{$i} = $element;
  }

  if (length($sequence) > $alignment_length)
  {
    $alignment_length = length($sequence);
  }	
}

my @consensus_elements;
my @consensus_counts;

if ($end_position >= 0) { $alignment_length = $end_position + 1; }

for (my $i = $start_position; $i < $alignment_length; $i++)
{
  foreach my $protein (@proteins)
  {
    my $element = $alignment{"$protein"}{$i};
    if ($counts{$i}{"$element"} > $consensus_counts[$i])
    {
      $consensus_counts[$i] = $counts{$i}{"$element"};
      $consensus_elements[$i] = $alignment{"$protein"}{$i};
    }
  }
}

print "Variant";
my $position_counter = 1;
for (my $i = $start_position; $i < $alignment_length; $i++)
{
  if (index($exclude_positions_by_consensus, $consensus_elements[$i]) == -1)
  {
    print "\t$consensus_elements[$i] (Pos: $position_counter)";
    $position_counter++;
  }
}
print "\n";

foreach my $protein (@proteins)
{
  print "$protein";
  for (my $i = $start_position; $i < $alignment_length; $i++)
  {
    if (index($exclude_positions_by_consensus, $consensus_elements[$i]) == -1)
    {
      my $element = $alignment{"$protein"}{$i};

      if ($binary_matrix == 1)
      {
	if ($element eq $consensus_elements[$i]) { print "\t0"; }
	else { print "\t1"; }
      }
      else
      {
	print "\t$element";
      }
    }
  }
  print "\n";
}

__DATA__

alignment2tab.pl <source file> <order file>

   Reads in a multiple protein alignment and converts it into a tab-delimited
   file according to specified instructions (e.g., 0/1 matrix of mutations)

   -s <num>: Start position in the alignment to print (default: 0)
   -e <num>: End position in the alignment to print (default: last position)

   -b:       Binary 0/1 matrix relative to consensus (default: print original character)

   -x <str>: Exclude positions that have as their consensus one of the characters in <str>

