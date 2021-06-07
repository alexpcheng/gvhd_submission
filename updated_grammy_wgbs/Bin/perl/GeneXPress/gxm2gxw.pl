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

#my $search_string = get_arg("s", "", \%args);

print "<WeightMatrices>\n";

while(<$file_ref>)
{
  chop;

  if (/<Motif[\s]/ and /Consensus/)
  {
      /Name=\"([^\"]+)\"/;
      my $name = $1;

      print "<WeightMatrix Name=\"$name\" Type=\"PositionSpecific\" ZeroWeight=\"0\">\n";
  }
  elsif (/<Position Num.*Weights=[\"]([^\"]+)/)
  {
      my $weights = $1;
      my @row = split(/\;/, $weights);
      my $sum = 0;
      for (my $i = 0; $i < @row; $i++)
      {
	  $sum += exp($row[$i]);
      }

      print "<Position Weights=\"";

      for (my $i = 0; $i < @row; $i++)
      {
	  if ($i > 0) { print ";"; }

	  print exp($row[$i]) / $sum;
      }

      print "\"></Position>\n";
  }
  elsif (/<[\/]Motif>/)
  {
      print "</WeightMatrix>\n";
  }
}

print "</WeightMatrices>\n";

__DATA__

gxm2gxw.pl <gxm file>

   Converts from the old gxm format to the gxw format, 
   including the conversion to probability space

