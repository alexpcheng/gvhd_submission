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

my $restrict_to_markov_order = get_arg("order", "", \%args);

my %matrices_str;
my @matrices;

while(<$file_ref>)
{
  if (/<WeightMatrix[\s]/)
  {
      /Name=\"([^\"]+)\"/;
      my $name = $1;

      my $matrix_str = "";
      my $done = 0;
      while($done == 0)
      {
	  my $line = <$file_ref>;
	  chop $line;

	  if ($line =~ /<[\/]WeightMatrix>/)
	  {
	      $done = 1;
	  }
	  else
	  {
	      if (length($restrict_to_markov_order) == 0 or
		  $line =~ /Markov=[\"]$restrict_to_markov_order[\"]/)
	      {
		  $matrix_str .= "$line\n";
	      }
	  }
      }

      if (length($matrices_str{$matrix_str}) == 0)
      {
	  $matrices_str{$matrix_str} = "$name";
	  push(@matrices, $matrix_str);
      }
      else
      {
 	  $matrices_str{$matrix_str} .= "\t$name";
      }
  }
}

foreach my $matrix_str (@matrices)
{
    print "$matrices_str{$matrix_str}\n";
    print "$matrix_str\n";
}

__DATA__

find_identical_matrices.pl <file>

   Takes in a gxw matrices file and finds the common matrices

   -order <num>: Take only matrices with order of <num> (default: all matrices)

