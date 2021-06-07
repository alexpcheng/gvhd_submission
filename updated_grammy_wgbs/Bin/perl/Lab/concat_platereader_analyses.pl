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

my $arg_command = get_full_arg_command(\@ARGV);
open OUTFILE, ">>merge_commands.tab";
print OUTFILE "$0 " . get_full_arg_command(\@ARGV) . "\n";
close(OUTFILE);

my %args = load_args(\@ARGV);

my $files_str = get_arg("f", "", \%args);
my $min_dist_between_time = get_arg("min_dist_between_time", "", \%args);
my $sync_zero_time = get_arg("sync_zero_time", "", \%args);
my $exp_time_shift = get_arg("exp_time_shift", "", \%args);
my $fix_time_interval = get_arg("fix_time_interval", "", \%args);
my $concat_horizontal = get_arg("concat_horizontal", "", \%args);
my $suffix = get_arg("suffix","",\%args);

#Exec("rm -f Makefile");
#Exec("ln -s /home/genie/Genie/Develop/Templates/Make/platereader_analysis_only_output.mak Makefile");
Exec("mkdir -p MergedData");

open(OUTFILE, ">MergeAnalyses.private");
print OUTFILE "\nMERGE_FILES = ";

my %matrix_names;
my @files = split(/\,/, $files_str);
my $first = 1;
for (my $i = 0; $i < @files; $i++)
{
	my $dir_files_str = `ls $files[$i]`;
	my @dir_files = split(/\n/, $dir_files_str);
	for (my $j = 0; $j < @dir_files; $j++)
	{
		if ($first == 0) { print OUTFILE ";"; }
		$first = 0;
	  print OUTFILE "$dir_files[$j]";

	  my @dirs1 = split(/\//, $dir_files[$j]);
	  my @dirs2 = split(/\./, $dirs1[@dirs1 - 1]);
		$matrix_names{$dirs2[0]} = "1";
    print STDERR "Adding matrix $dirs2[0]\n";
	}
}
print OUTFILE "\n\n";
close(OUTFILE);

open(OUTFILE, ">merge_analyses_params.xml");
print OUTFILE "<Normalizations>\n";
close(OUTFILE);

my $operation= "ConcatenateMatrices";
if ($concat_horizontal)
{
   $operation= "ConcatenateMatricesHorizontal";
}


foreach my $matrix (keys %matrix_names)
{
  print STDERR "Processing matrix $matrix\n";

     Exec("sed 's/__INPUT_MATRIX__/$matrix/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/merge_plates_concat.xml | sed 's/__MIN_DIST_BETWEEN_TIME__/$min_dist_between_time/g' | sed 's/__SYNC_ZERO_TIME__/$sync_zero_time/g' | sed 's/__EXP_TIME_SHIFT__/$exp_time_shift/g' | sed 's/__FIX_TIME_INTERVAL__/$fix_time_interval/g' | sed 's/__OPERATION__/$operation/g' | sed 's/__SUFFIX__/$suffix/g' >> merge_analyses_params.xml");

}

open(OUTFILE, ">>merge_analyses_params.xml");
print OUTFILE "</Normalizations>\n";
close(OUTFILE);

#--------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------
sub Exec
{
  my ($exec_str) = @_;
  
  print("Running: [$exec_str]\n");
  system("$exec_str");
}

__DATA__

concat_platereader_analyses.pl <file>

   concats several plate reader analysis files

   -f <files>: A comma-seprated list of files to merge. Can include wildcards (e.g., NormalizedData/Plate1/*.tab,NormalizedData/Plate2/*.tab)
  -min_dist_between_time : min time between data points
  -sync_zero_time <True/False> :
  -exp_time_shift <>: A list of times indicating shifts of experiments in time. For example: If for technical reasons the first measure of exp2 was actually 1sec later than exp1 than the string "0,1" will synchronize them. This option is not relevant if -same_exp is used.
  -fix_time_interval <numeric> if a number is provided the time interval will be fixed with the given interval
  -concat_horizontal <1/0>: Enter 1 to join matrices horizontaly. Default:0.
  -suffix <str>: A suffix to be added to each col header after concatinating matrices.

