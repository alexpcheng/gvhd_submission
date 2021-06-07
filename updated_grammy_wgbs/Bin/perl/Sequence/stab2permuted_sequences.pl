#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $randomization_iterations = get_arg("i", 1, \%args);
my $permutation_order = get_arg("po", 1, \%args);
my $num_permutations = get_arg("np", 1, \%args);
my $seed = get_arg("s", "", \%args);

my $MAX_ITERATIONS = 1000;
my @sequence_vec;

if (length($seed) > 0)
{
   srand($seed);
}

my $first = 1;
while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);
  my $sequence = $row[1];

  for (my $k = 1; $k <= $num_permutations; $k++)
  {
    my $kk = ($num_permutations == 1) ? "" : "_$k";
    print "$row[0]$kk\t";

    @sequence_vec = ();
    my $sequence_length = length($sequence);
    for (my $i = 0; $i < $sequence_length; $i++)
    {
      $sequence_vec[$i] = substr($sequence, $i, 1);
    }

    for (my $i = 0; $i < $randomization_iterations; $i++)
    {
      #print STDERR "$row[0] $i\n";
      for (my $j = $permutation_order - 1; $j < @sequence_vec - 2 * ($permutation_order - 1); $j++)
      {
	my $new_position = $permutation_order - 1 + int(rand($sequence_length - 3 * ($permutation_order - 1)));
	my $done = 0;
	my $iterations = 0;
	while ($done == 0)
	{
	  if ($permutation_order == 1 or $iterations == $MAX_ITERATIONS or &CheckContext($j, $new_position) == 1)
	  {
	    $done = 1;
	  }
	  else
	  {
	    $new_position = $permutation_order - 1 + int(rand($sequence_length - 3 * ($permutation_order - 1)));
	    $iterations++;
	  }
	}

	if ($iterations < $MAX_ITERATIONS)
	{
	  #print STDERR "i=$iterations\t$j\t$new_position\t" . $sequence_vec[$j - 1] . "\t" . $sequence_vec[$new_position - 1] . "\t" . $sequence_vec[$j + 2] . "\t" . $sequence_vec[$new_position + 2] . "\n";
	  #print STDERR "i=$iterations\t$j\t$new_position\t" . $sequence_vec[$j] . "\t" . $sequence_vec[$new_position] . "\t" . $sequence_vec[$j + 1] . "\t" . $sequence_vec[$new_position + 1] . "\n";
	  for (my $k = $j; $k < $j + $permutation_order; $k++)
	  {
	    my $temp = $sequence_vec[$k];
	    $sequence_vec[$k] = $sequence_vec[$new_position + $k - $j];
	    $sequence_vec[$new_position + $k - $j] = $temp;
	  }
	  #print STDERR "i=$iterations\t$j\t$new_position\t" . $sequence_vec[$j] . "\t" . $sequence_vec[$new_position] . "\t" . $sequence_vec[$j + 1] . "\t" . $sequence_vec[$new_position + 1] . "\n";
	}
      }
    }

    for (my $i = 0; $i < @sequence_vec; $i++)
    {
      print "$sequence_vec[$i]";
    }

    print "\n";
  }
}

sub CheckContext
{
  my ($from, $to) = @_;

  if (abs($from - $to) < $permutation_order + 2 * ($permutation_order - 1))
  {
    return 0;
  }

  for (my $i = 0; $i < $permutation_order - 1; $i++)
  {
    #print STDERR " from=" . $from . " to=" . $to;
    #print STDERR " p1=" . $sequence_vec[$from - ($permutation_order - 1) + $i];
    #print STDERR " p2=" . $sequence_vec[$to - ($permutation_order - 1) + $i];
    #print STDERR " n1=" . $sequence_vec[$from + $permutation_order + $i];
    #print STDERR " n2=" . $sequence_vec[$to + $permutation_order + $i] . "\n";

    if (not(($sequence_vec[$from - ($permutation_order - 1) + $i] eq $sequence_vec[$to - ($permutation_order - 1) + $i]) and ($sequence_vec[$from + $permutation_order + $i] eq $sequence_vec[$to + $permutation_order + $i])))
    {
      return 0;
    }
  }

  return 1;
}

__DATA__

stab2permuted_sequences.pl <file>

   Takes in a stab sequence file and permutes every sequence

   -i <int>:  Number of times to go over the sequence during the randomization (default: 1)
   -po <int>: The order at which to permute the sequence (default: 1 for single bps)
              E.g., put 2 for permuting the sequences by dinucleotide frequencies

   -np <int>: The number of permutations per sequence (default: 1).

   -s <int>:  Seed for rand(). Different seeds will produces different outputs.
