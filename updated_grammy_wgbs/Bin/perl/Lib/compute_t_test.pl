#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

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

my $n1_column = get_arg("n1", 1, \%args);
my $m1_column = get_arg("m1", 2, \%args);
my $s1_column = get_arg("s1", 3, \%args);
my $n2_column = get_arg("n2", 4, \%args);
my $m2_column = get_arg("m2", 5, \%args);
my $s2_column = get_arg("s2", 6, \%args);

my $precision = get_arg("p", 4, \%args);

while (<$file_ref>)
{
	chomp;
	print "$_\t";
	
	my @row = split(/\t/);
	my $dof = $row[$n1_column] + $row[$n2_column] - 2;

	my $t_statistic = ComputeTValue ($row[$n1_column], $row[$m1_column], $row[$s1_column], $row[$n2_column], $row[$m2_column], $row[$s2_column]);		
	my $p_value = ComputeTTest ($t_statistic, $dof);
	
	print &format_number ($t_statistic, $precision) . "\t" . &format_number ($p_value, $precision) . "\n";
	
}

__DATA__

compute_t_test.pl <file>

	The t-test assesses whether the means of two groups are statistically different
	from each other. The t-test p-value associated with results described
	in each line of the input file are computed. Two new columns are added to the end
	of every line, with the t-statistic and the p-value associated with that t-statistic.
	
	-n1 <num>       Number of column where the number of items in group 1 is found             (default: 1)
	-m1 <num>       Number of column where the mean of items in group 1 is found               (default: 2)
	-s1 <num>       Number of column where the standard deviation of items in group 1 is found (default: 3)

	-n2 <num>       Number of column where the number of items in group 1 is found             (default: 4)
	-m2 <num>       Number of column where the mean of items in group 1 is found               (default: 5)
	-s2 <num>       Number of column where the standard deviation of items in group 1 is found (default: 6)

	-p <num>        Precision (number of digits after decimal point) for printouts (default: 4)
 
 