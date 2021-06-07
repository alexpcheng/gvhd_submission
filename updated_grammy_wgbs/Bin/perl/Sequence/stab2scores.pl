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

my $matrix_file = get_arg("m", "", \%args);
my $reverse_complement = get_arg("rc", 0, \%args);

open(MATRIX, "<$matrix_file") or die "Could not open matrix file $matrix_file\n";
my $headers_str = <MATRIX>;
chomp $headers_str;
my @headers = split(/\t/, $headers_str);
my %matrix;
my $kmers = 0;
while(<MATRIX>)
{
  chomp;

  my @row = split(/\t/);

  for (my $i = 1; $i < @row; $i++)
  {
    $matrix{$row[0]}{$headers[$i]} = $row[$i];

    #print STDERR "matrix{$row[0]}{$headers[$i]} = $matrix{$row[0]}{$headers[$i]}\n";
  }

  if ($kmers == 0) { $kmers = length($row[0]); }
}

print STDERR "Analyzing k-mers of length $kmers\n";

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  my @max_scores;
  my @max_positions;
  my @max_sequences;

  for (my $i = 0; $i <= length($row[1]) - $kmers; $i++)
  {
    my $subsequence = substr($row[1], $i, $kmers);
    my $subsequence_rc = $reverse_complement == 1 ? &ReverseComplement($subsequence) : "";

    for (my $j = 1; $j < @headers; $j++)
    {
      my $score = $matrix{$subsequence}{$headers[$j]};
      my $score_rc = $reverse_complement == 1 ? $matrix{$subsequence_rc}{$headers[$j]} : "";

      if (length($max_scores[$j]) == 0 or (length($score) > 0 and $score > $max_scores[$j]))
      {
	$max_scores[$j] = $score;
	$max_positions[$j] = $i;
	$max_sequences[$j] = $subsequence;
      }

      if (length($max_scores[$j]) == 0 or (length($score_rc) > 0 and $score_rc > $max_scores[$j]))
      {
	$max_scores[$j] = $score_rc;
	$max_positions[$j] = $i;
	$max_sequences[$j] = $subsequence_rc;
      }
    }
  }

  for (my $j = 1; $j < @headers; $j++)
  {
    print "$row[0]\t$max_positions[$j]\t" . ($max_positions[$j] + $kmers - 1) . "\t$headers[$j]\t$max_scores[$j]\t$max_sequences[$j]\n";
  }
}

__DATA__

stab2scores.pl <file>

   Outputs the score of each sequence given a scoring file

   -m:   Scoring matrix file. First column is list of k-mers
                              Each following column is list of scores (e.g., each column is a TF)
                              First line is header with column names from column 2 and on

   -rc:  Score each k-mer as the max of its forward and reverse complement

