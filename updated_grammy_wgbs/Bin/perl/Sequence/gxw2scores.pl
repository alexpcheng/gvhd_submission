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
my $alphabet_str = get_arg("a", "A;C;G;T", \%args);
my $print_min_score = get_arg("min", 0, \%args);
my $print_max_score = get_arg("max", 0, \%args);
my $take_log_scores = get_arg("log", 0, \%args);
my $take_ratio_to_background = get_arg("ratio", 0, \%args);
my $scores_file = get_arg("f", "", \%args);
my $scores_file_column = get_arg("fc", 2, \%args);

my @alphabet = split(/\;/, $alphabet_str);

my $matrix_name;
my $min_score = $take_log_scores == 1 ? 0 : 1;
my $max_score = $take_log_scores == 1 ? 0 : 1;
my $background_score = $take_log_scores == 1 ? 0 : 1;
my %min_scores;
my %max_scores;
while(<$file_ref>)
{
  chop;

  if (/<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
      $matrix_name = $1;
      $min_score = $take_log_scores == 1 ? 0 : 1;
      $max_score = $take_log_scores == 1 ? 0 : 1;
      $background_score = $take_log_scores == 1 ? 0 : 1;
  }
  elsif (/<Position.*Weights=[\"]([^\"]+)[\"]/)
  {
      my @row = split(/\;/, $1);

      @row = sort { $a <=> $b } @row;

      if ($take_log_scores == 1)
      {
	$min_score += log($row[0]);
	$max_score += log($row[@row - 1]);
	$background_score += log(0.25);
	#print STDERR "max=$max_score L=" . (log($row[@row - 1])) . "\n";
	#print STDERR "bck=$background_score L=" . (log(0.25)) . "\n\n";
      }
      else
      {
	$min_score *= $row[0];
	$max_score *= $row[@row - 1];
	$background_score *= 0.25;
      }

      #print "@row\n\n";
  }
  elsif (/<[\/]WeightMatrix/)
  {
    $min_scores{$matrix_name} = $min_score;
    $max_scores{$matrix_name} = $max_score;

    if ($take_ratio_to_background == 1 and $take_log_scores == 1)
    {
      $min_scores{$matrix_name} -= $background_score;
      $max_scores{$matrix_name} -= $background_score;
    }
    elsif ($take_ratio_to_background == 1 and $take_log_scores == 0)
    {
      $min_scores{$matrix_name} /= $background_score;
      $max_scores{$matrix_name} /= $background_score;
    }

    if ($print_min_score == 1 or $print_max_score == 1)
    {
      print "$matrix_name";

      if ($print_min_score == 1)
      {
	print "\t$min_scores{$matrix_name}";
      }
      if ($print_max_score == 1)
      {
	print "\t$max_scores{$matrix_name}";
      }

      print "\n";
    }
  }
}

if (length($scores_file) > 0)
{
  open(SCORES_FILE, "<$scores_file");
  while(<SCORES_FILE>)
  {
    chop;

    my @row = split(/\t/);

    print "$row[0]";
    for (my $i = 1; $i < @row; $i++)
    {
      print "\t";

      if ($i == $scores_file_column - 1)
      {
	my $fraction = &format_number(($row[$i] - $min_scores{$row[0]}) / ($max_scores{$row[0]} - $min_scores{$row[0]}), 3);
	print $fraction;
      }
      else
      {
	print "$row[$i]";
      }
    }
    print "\n";
  }
}

__DATA__

gxw2scores.pl <gxm file>

   Outputs statistics about matrix scores

   -a <str>:  Alphabet (default: 'A;C;G;T')

   -min:      Extract the min score
   -max:      Extract the max score

   -log:      Output scores in log-space

   -ratio:    Take the score as a ratio to a uniform matrix
              (when working with probabilities, like dividing by 0.25^Length,
                            with logs, like subtracting Length*0.25

   -f <str>:  Scores file in the format <matrix><tab><score>.
              Outputs the percentile score of each score from the min max of the matrix
   -fc <num>: Column of scores in the scores file (default: 2, 1-based)

