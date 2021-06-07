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
my $errors = get_arg("e", 0, \%args);
my $score_flag = get_arg("score", 0, \%args);
my $min_score_flag = get_arg("min_score", 0, \%args);
my $scores_type = get_arg("scores_type", 0, \%args);


my @alphabet = split(/\;/, $alphabet_str);

my $alphabet_len = @alphabet;

my $matrix_name;
my $consensus;
my $position_num;
my $score;
my $min_score;


while(<$file_ref>)
{
  chop;

  if (/<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
      $matrix_name = $1;
      $consensus = "";
      $position_num = 0;
      $score = 0;
      $min_score = 0;
  }
  elsif (/<Position.*Weights=[\"]([^\"]+)[\"]/)
  {
      my @row = split(/\;/, $1);

      my $sequence_char = "";
      my $max_probability = 0;
      my $min_probability = 1;

      my @row1;
      for (my $i = 0; $i < @row; $i++)
      {
	$row1[$i] = "$i;$row[$i]";
      }
      @row1 = sort { my @aa = split(/\;/, $a); my @bb = split(/\;/, $b); $bb[1] <=> $aa[1] } @row1;

      for (my $i = 0; $i < @row; $i++)
      {
	  if ($i == 0 or $row[$i] > $max_probability)
	  {
	      $max_probability = $row[$i];
	      $sequence_char = $alphabet[$i];
	  }
	  if ($i == 0 or $row[$i] < $min_probability)
	  {
	      $min_probability = $row[$i];
	  }
      }

      if ($position_num < $errors)
      {
	my @row = split(/\;/, $row1[1]);
	$consensus .= "$alphabet[$row[0]]";
      }
      else
      {
	my @row = split(/\;/, $row1[0]);
	$consensus .= "$alphabet[$row[0]]";
      }

      $position_num++;

      if ($position_num == 1)
	{
	  $score = $max_probability;
	  $min_score = $min_probability;
	}
      else
	{
	  $score = $score * $max_probability;
	  $min_score = $min_score * $min_probability;
	}
    }
  elsif (/<[\/]WeightMatrix/)
    {
      print "$matrix_name\t$consensus";

      if ($score_flag)
	{
	  if ($scores_type eq "log_2_uni")
	    {
	      $score = log($score / ( 0.25 ** $position_num ));
	    }
	  elsif ($scores_type eq "log")
	    {
	       $score = log($score);
	    }



	 print "\t$score";

	}

     if ($min_score_flag)
	{
	  if ($scores_type eq "log_2_uni")
	    {
	      $min_score = log($min_score / ( 0.25 ** $position_num ));
	    }
	  elsif ($scores_type eq "log")
	    {
	       $min_score = log($min_score);
	    }

	 print "\t$min_score";
	}

      print "\n";
    }
}

__DATA__

gxw2consensus.pl <gxm file>

   Outputs the consensus for each weight matrix assuming PSSMs

   -a <str>:   Alphabet (default: 'A;C;G;T')

   -e <num>:   Output the second highest letter in the first <num> positions (default: 0)

   -score :        print the score of the consensus
   -min_score :    print the minimal score of the PSSM

  -scores_type <prob,log,log_2_uni> default:probability (prob). log_2_uni: prints the scores as log ratio to uniform background
