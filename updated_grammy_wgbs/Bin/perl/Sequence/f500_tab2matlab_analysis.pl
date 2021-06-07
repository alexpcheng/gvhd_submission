#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";



my $space = "___SPACE___";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my $continuous_measure_params_file   = $ARGV[0];
my $matlab_data_output_file_name     = $ARGV[1];

my $exe_str = "matlabrun.pl -m ContinuousMeasureView -p $continuous_measure_params_file,$matlab_data_output_file_name -po";

system($exe_str) == 0
	 or die "system $exe_str failed: $?";
	 
__DATA__

Usage: 

----------------------------- parameters -------------------------------------

f500_tab2matlab_analysis.pl <continuous_measure_params_file> <matlab_data_output_file_name>

continuous_measure_params_file - File that contains:
1. The input files names.
2. The Matlab analysis parameters.
3. Plots drawing parameters (optional).

matlab_data_output_file_name - the name of the matlab .mat output file
This .mat contains data structures which contain all the data and paramters used for the analysis




