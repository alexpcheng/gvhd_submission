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

my $pseudo_counts = get_arg("p", "0.1", \%args);
my $print_num_binding_sites = get_arg("c", 0, \%args);

print "<WeightMatrices>\n";

my $in_matrix = 0;
my $matrix_name;
my $num_positions = 0;
my $sum_binding_sites = 0;
while(<$file_ref>)
{
  chop;

  if (/^[\>]([^\t]+)/)
  {
      $matrix_name = $1;

      $in_matrix = 1;
      $num_positions = 0;
      $sum_binding_sites = 0;

      if ($print_num_binding_sites == 0)
      {
	  print "<WeightMatrix Name=\"$matrix_name\" Type=\"PositionSpecific\" ZeroWeight=\"0\">\n";
      }
  }
  elsif (/^</)
  {
      if ($in_matrix == 1)
      {
	  if ($print_num_binding_sites == 0)
	  {
	      print "</WeightMatrix>\n";
	  }
	  elsif ($print_num_binding_sites == 1)
	  {
	      print "$matrix_name\t" . &format_number($sum_binding_sites / $num_positions, 3) . "\t$num_positions\t$sum_binding_sites\n";
	  }
      }

      $in_matrix == 0;
  }
  elsif ($in_matrix == 1)
  {
      if ($print_num_binding_sites == 0)
      {
	  print "  <Position Weights=\"";
      }

      $num_positions++;

      my @row = split(/\t/);

      my $sum = 0;
      for (my $i = 0; $i < @row; $i++)
      {
	  $sum += $row[$i] + $pseudo_counts;
	  $sum_binding_sites += $row[$i];
      }

      if ($print_num_binding_sites == 0)
      {
	  for (my $i = 0; $i < @row; $i++)
	  {
	      if ($i > 0) { print ";"; }

	      print &format_number(($row[$i] + $pseudo_counts) / $sum, 3);
	  }
      }

      if ($print_num_binding_sites == 0)
      {
	  print "\"></Position>\n";
      }
  }
}

print "</WeightMatrices>\n";

__DATA__

parse_binding_sites.pl <file>

   Parses binding sites into weight matrices.
   The format of binding sites is:

   >Matrix name
   c_11<tab>c_12<tab>c_13<tab>c_14
   c_21<tab>c_22<tab>c_23<tab>c_24
   <
   
   where c_ij represents the count of the j-th character in the i-th position

   -p <num>: Pseudo count to use for constructing the matrix (default: 0.1)

   -c:       Only print the number of binding sites that went into each matrix

