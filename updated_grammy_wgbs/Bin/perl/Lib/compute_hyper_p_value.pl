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

my $k_column = get_arg("k", 1, \%args);
my $n_column = get_arg("n", 2, \%args);
my $K_column = get_arg("K", 3, \%args);
my $N_column = get_arg("N", 4, \%args);
my $ratio_on = get_arg("r", 0, \%args);
my $precision = get_arg("p", 4, \%args);
my $log10 = get_arg("log10", 0, \%args);
my $ver2 = get_arg("ver2", 0, \%args);
my $ignore_zero = get_arg("ignore_zero", 0, \%args);

while (<$file_ref>)
{
	chomp;
	print "$_\t";
	
	my @row = split(/\t/);
	if (($ignore_zero) && (($row[$n_column] == 0) || ($row[$K_column] == 0) || ($row[$N_column] == 0))){
	    #print $n_column.":".$row[$n_column].".".$K_column.":".$row[$K_column].".".$N_column.":".$row[$N_column]." + 1\n";
	    print "NaN\n";
	    next;
	}
	my $result;
	if ($log10){
	  $result = ComputeLog10HyperPValue ($row[$k_column], $row[$n_column], $row[$K_column], $row[$N_column]);	
	}
	elsif ($ver2){
	  $result = ComputeHyperPValue2 ($row[$k_column], $row[$n_column], $row[$K_column], $row[$N_column]);
	}
	else {
	  $result = ComputeHyperPValue ($row[$k_column], $row[$n_column], $row[$K_column], $row[$N_column]);	
	}
	print &format_number ($result, $precision);
	
	if ($ratio_on)
	{
		print "\t" . format_number (($row[$k_column] / $row[$K_column]) * 100, $precision) . 
		      "\t" . format_number (($row[$n_column] / $row[$N_column]) * 100, $precision);
	}
	
	print "\n";
}

__DATA__

compute_hyper_p_value.pl <file>

	Compute the Hyper-Geometric p-value associated with results described
	in each line of the input file. The Log10 of the p-value is added as a new
	column to the end of each line.
	
	-k <num>       Number of column where "k" is found (default: 1)
	-n <num>       Number of column where "n" is found (default: 2)
	-K <num>       Number of column where "K" is found (default: 3)
	-N <num>       Number of column where "N" is found (default: 4)

	-log10         print log10 of p-value (default: normal p-value)
	-ver2          use version2 to calculate (Noam's)
	-r             Add two columns representing the ratios k/n and K/N (in percents)
        -p <num>       Precision (number of digits after decimal point) for printouts
        -ignore_zero   when used, lines that have a zero parameter (n,K or N) do not crash but are ignored 
                       with a p-value result of 1 (default: crash)

