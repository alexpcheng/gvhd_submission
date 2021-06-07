#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/GeneXPress/gxt_helpers.pl";

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

my $chr_file_name = get_arg("c", "", \%args);

open(CHR_FILE, $chr_file_name) or die("Could not open file '$chr_file_name'.\n");
my %chr_by_name = &GetLocationsByNameFromTabFile(\*CHR_FILE);

my $line = <$file_ref>;
chop $line;
my @header_rows = split(/\t/, $line);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $location_str = $chr_by_name{$row[0]};

  if (length($location_str) > 0)
  {
    my @location = split(/\t/, $location_str);
    my $str = "$location[0]\t$location[1]\t$location[2]\t$location[3]";

    for (my $i = 1; $i < @row; $i++)
    {
      if (length($row[$i]) > 0)
      {
	print "$str\t$header_rows[$i]\t$row[$i]\n";
      }
    }
  }
}

__DATA__

tab2chr.pl <file>

   Takes in a tab delimited file and converts it into a chr file
   where the types are the column headers, and the identifier 
   in the chr file matches the identifier in the rows

   Example: if the input file is 

      E1  E2
   G1  2   3
   G2  4  -5

   and the chr file is

   1  G1  10  20
   3  G2  60  80

   then the output is

   1  G1  10  20  E1  2
   1  G1  10  20  E2  3
   3  G2  60  80  E1  4
   3  G2  60  80  E1 -5

   -c <str>: chr file

