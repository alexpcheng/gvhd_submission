#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $LOG2 = log(2);

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

print "Matrix\tPositions\tEntropy\tAvg. Entropy\tInformation bits\tAvg. Information bits\n";

my $sum = 0;
my $num_positions = 0;
while(<$file_ref>)
{
  chop;

  if (/<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
      print "$1";

      $sum = 0;
      $num_positions = 0;
  }
  elsif (/<Position.*Weights=[\"]([^\"]+)[\"]/)
  {
      $num_positions++;

      my @row = split(/\;/, $1);

      for (my $i = 0; $i < @row; $i++)
      {
	  $sum -= $row[$i] * log($row[$i]) / $LOG2;
      }
  }
  elsif (/<[\/]WeightMatrix/)
  {
      print "\t$num_positions";
      print "\t";
      print &format_number($sum, 3);
      print "\t";
      print &format_number($sum / $num_positions, 3);
      print "\t";
      print &format_number(2 * $num_positions - $sum, 3);
      print "\t";
      print &format_number((2 * $num_positions - $sum) / $num_positions, 3);
      print "\n";
  }
}

__DATA__

gxw2entropy.pl <gxm file>

   Given a gxm file as input, outputs the entropy of each motif

