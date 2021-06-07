#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

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
my $create_composite_matrix = get_arg("c", 0, \%args);
my $insert_mono_into_di = get_arg("m", 0, \%args);
my $direct_cpd_estimation = get_arg("direct", 0, \%args);

my $specified_dinucleotides = 0;
my @columns2dinucleotides;
my $line = <$file_ref>;
chomp $line;
my @row = split(/\t/, $line);
for (my $i = 1; $i < @row; $i++)
{
  my @dinucleotides = split(/\;/, $row[$i]);

  for (my $j = 0; $j < @dinucleotides; $j++)
  {
    if (length($columns2dinucleotides[$i]) > 0)
    {
      $columns2dinucleotides[$i] .= ";";
    }

    $columns2dinucleotides[$i] .= $dinucleotides[$j];
    $specified_dinucleotides++;
  }
}

#print STDERR "@columns2dinucleotides\n";

my %dinucleotide_probabilities;
my @default_probabilities;
my @position_names;

my @id2char = ("A", "C", "G", "T");

my $position = 0;
while(<$file_ref>)
{
  chomp;

  #print STDERR "$_\n";

  my @row = split(/\t/);

  $position_names[$position] = $row[0];

  my $sum = 0;
  for (my $i = 1; $i < @row; $i++)
  {
    $sum += $row[$i];

    my @dinucleotides = split(/\;/, $columns2dinucleotides[$i]);
    my $num_dinucleotides = @dinucleotides;

    for (my $j = 0; $j < @dinucleotides; $j++)
    {
      $dinucleotide_probabilities{$position}{"$dinucleotides[$j]"} = $row[$i] / $num_dinucleotides;

      #print STDERR "dinucleotide_probabilities{$position}{$dinucleotides[$j]} = $dinucleotide_probabilities{$position}{$dinucleotides[$j]}\n";
    }
  }

  $default_probabilities[$position] = $specified_dinucleotides < 16 ? (1 - $sum) / (16 - $specified_dinucleotides) : 0;

  #print STDERR "Default $default_probabilities[$position]\n";

  $position++;
}

my %conditional_probabilities;
my @propagate_probabilities;
for (my $parents = 0; $parents < 4; $parents++)
{
  $propagate_probabilities[$parents] = 1;
}

print "<WeightMatrices>\n";

my $first_weights;
for (my $i = $position - 1; $i >= 0; $i--)
{
  my @next_propagate_probabilities;

  for (my $parents = 0; $parents < 4; $parents++)
  {
    my $parent_char = $id2char[$parents];

    my $sum_parents;
    if ($direct_cpd_estimation == 1)
    {
      $sum_parents = &GetProbability($i, "${parent_char}A") + &GetProbability($i, "${parent_char}C") + &GetProbability($i, "${parent_char}G") + &GetProbability($i, "${parent_char}T");
    }
    else
    {
      $sum_parents = 
	&GetProbability($i, "${parent_char}A") * $propagate_probabilities[0] + 
	  &GetProbability($i, "${parent_char}C") * $propagate_probabilities[1] + 
	    &GetProbability($i, "${parent_char}G") * $propagate_probabilities[2] + 
	      &GetProbability($i, "${parent_char}T") * $propagate_probabilities[3];
    }
    
    $next_propagate_probabilities[$parents] = $sum_parents;
    #print STDERR "Position=$i next_propagate_probabilities[$parents] = $next_propagate_probabilities[$parents]\n";

    for (my $child = 0; $child < 4; $child++)
    {
      my $child_char = $id2char[$child];

      if ($direct_cpd_estimation == 1)
      {
	$conditional_probabilities{$i}{"$parent_char$child_char"} = (&GetProbability($i, "$parent_char$child_char")) / $sum_parents;
      }
      else
      {
	$conditional_probabilities{$i}{"$parent_char$child_char"} = (&GetProbability($i, "$parent_char$child_char") * $propagate_probabilities[$child]) / $sum_parents;
      }
      #print STDERR "dinuc($i,$parent_char$child_char)=" . &GetProbability($i, "$parent_char$child_char") . " conditional_probabilities{$i}{$parent_char$child_char} = " . $conditional_probabilities{$i}{"$parent_char$child_char"} . "\n";
    }
  }

  @propagate_probabilities = @next_propagate_probabilities;

  if ($i == 0)
  {
    my $sum = 0;
    for (my $parents = 0; $parents < 4; $parents++)
    {
      $sum += $propagate_probabilities[$parents];
    }

    if ($insert_mono_into_di == 0)
    {
      print "<WeightMatrix Name=\"Pre$position_names[$i]\" Type=\"MarkovOrder\" LeftPaddingPositions=\"0\" RightPaddingPositions=\"0\" Order=\"0\">\n";
      print "<Order Markov=\"0\" Weights=\"";
      print $propagate_probabilities[0] / $sum;
      print ";";
      print $propagate_probabilities[1] / $sum;
      print ";";
      print $propagate_probabilities[2] / $sum;
      print ";";
      print $propagate_probabilities[3] / $sum;
      print "\"></Order>\n";
      print "</WeightMatrix>\n";
    }
    else
    {
      $first_weights = ($propagate_probabilities[0] / $sum) . ";" . ($propagate_probabilities[1] / $sum) . ";" . ($propagate_probabilities[2] / $sum) . ";" . ($propagate_probabilities[3] / $sum);
    }
  }
}

for (my $i = 0; $i < $position; $i++)
{
  print "<WeightMatrix Name=\"$position_names[$i]\" Type=\"MarkovOrder\" LeftPaddingPositions=\"0\" RightPaddingPositions=\"0\" Order=\"1\">\n";
  print "<Order Markov=\"0\" Weights=\"";
  if ($insert_mono_into_di == 1 and $i == 0)
  {  
    print "$first_weights";
  }
  else
  {
    print "0.25;0.25;0.25;0.25";
  }
  print "\"></Order>\n";

  for (my $parents = 0; $parents < 4; $parents++)
  {
    print "<Order Markov=\"1\" Parents=\"$parents\" Weights=\"";

    my $parent_char = $id2char[$parents];

    for (my $child = 0; $child < 4; $child++)
    {
      if ($child > 0) { print ";"; }

      my $child_char = $id2char[$child];

      print $conditional_probabilities{$i}{"$parent_char$child_char"};
    }

    print "\"></Order>\n";
  }

  print "</WeightMatrix>\n";
}

if ($create_composite_matrix == 1)
{
  print "<WeightMatrix Name=\"Matrix\" Type=\"Composite\" LeftPaddingPositions=\"0\" RightPaddingPositions=\"0\" DoubleStrandBinding=\"false\" EffectiveAlphabetSize=\"4\" Alphabet=\"ACGT\" Symmetric=\"false\" Even=\"false\">\n";

  print "<SubMatrix Name=\"Pre$position_names[0]\"></SubMatrix>\n";
  for (my $i = 0; $i < $position; $i++)
  {
    print "<SubMatrix Name=\"$position_names[$i]\"></SubMatrix>\n";
  }
  
  print "</WeightMatrix>\n";
}

print "</WeightMatrices>\n";

sub GetProbability
{
  my ($position, $dinucleotide) = @_;

  return length($dinucleotide_probabilities{$position}{$dinucleotide}) > 0 ? $dinucleotide_probabilities{$position}{$dinucleotide} : $default_probabilities[$position];
}

__DATA__

dinucleotides2gxw.pl <file>

   Takes in dinucleotide frequencies and produces a gxw file from them
   Format is a tab delimited file, with one row per markov order matrix:

   Matrices        AA;TT;TA   GC
   <matrix name>   0.3        0.2
   <matrix name>   0.24       0.3

   The above means that AA,TT,TA have probability 0.1 each, GC has probability 0.2 and
   the rest of the probability (0.5 total) is divided up between all other dinucleotides.
   For the second row AA,TT,TA have p=0.08 each, GC has p=0.3.

   -c:      Create a composite weight matrix from all weight matrices

   -m:      Insert the first mononucleotide matrix into the first dinucleotide one (default: make it its own matrix)

   -direct: Compute the CPDs directly from the counts without marginalization

