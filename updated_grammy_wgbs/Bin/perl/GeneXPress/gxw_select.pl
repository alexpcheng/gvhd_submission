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

my $weight_matrices_str = get_arg("w", "", \%args);
my $weight_matrices_file = get_arg("f", "", \%args);

my %weight_matrices_hash;
my @weight_matrices = split(/\,/, $weight_matrices_str);
foreach my $weight_matrix (@weight_matrices)
{
  $weight_matrices_hash{$weight_matrix} = "1";

  #print STDERR "weight_matrices_hash{$weight_matrix}\n";
}

if (length($weight_matrices_file) > 0)
{
  open(INFILE, "<$weight_matrices_file");
  while(<INFILE>)
  {
    chomp;

    my @row = split(/\t/);

    $weight_matrices_hash{$row[0]} = "1";
  }
}

print "<WeightMatrices>\n";

my $inside = 0;

while(<$file_ref>)
{
  chop;

  if (/<WeightMatrix[\s]/)
  {
      /Name=\"([^\"]+)\"/;
      my $name = $1;

      #print STDERR "$name\n";
      if (length($weight_matrices_hash{$name}) > 0)
      {
	  $inside = 1;
	  print "$_\n";
      }
  }
  elsif (/<Position Weights=[\"]/ and $inside == 1)
  {
      print "$_\n";
  }
  elsif (/<[\/]WeightMatrix>/)
  {
      if ($inside == 1)
      {
	  print "$_\n";
      }

      $inside = 0;
  }
}

print "</WeightMatrices>\n";

__DATA__

gxw_select.pl <gxm file>

   Selects a weight matrix from a gxw file

   -w <str>: Name of weight matrix to select (specify multiple matrices with comma separated)
   -f <str>: File with weight matrices to select, one per line

