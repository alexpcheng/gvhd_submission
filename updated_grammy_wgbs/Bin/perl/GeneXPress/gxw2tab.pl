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

while(<$file_ref>)
{
  chomp;

  if (/<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
      print "$1";
  }
  elsif (/<Position.*Weights=[\"]([^\"]+)[\"]/)
  {
      my @row = split(/\;/, $1);

      for (my $i = 0; $i < @row; $i++)
      {
	  print "\t$row[$i]";
      }
  }
  elsif (/<Order.*Markov.*Weights=[\"]([^\"]+)[\"]/)
  {
      my @row = split(/\;/, $1);

      for (my $i = 0; $i < @row; $i++)
      {
	  print "\t$row[$i]";
      }
  }
  elsif (/<[\/]WeightMatrix/)
  {
      print "\n";
  }
}

__DATA__

gxw2tab.pl <gxm file>

   Given a gxw file as input, outputs all the motifs along
   with their description in a flat tab delimited file

