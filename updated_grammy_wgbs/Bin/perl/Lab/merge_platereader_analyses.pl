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
my $same_exp = get_arg("same_exp", 0, \%args);
my $experiment_time_shift = get_arg("experiment_time_shift" ,"", \%args);

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

foreach my $matrix (keys %matrix_names)
{
  print STDERR "Processing matrix $matrix\n";
  if ($same_exp) {
     Exec("sed 's/__INPUT_MATRIX1__/$matrix/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/merge_plates_from_same_exp_params.xml >> merge_analyses_params.xml");
  }
  else {
    if ($experiment_time_shift ne "") {
       Exec("sed 's/__INPUT_MATRIX1__/$matrix/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/merge_plates_from_different_experiments_params_with_shift.xml | sed 's/__TIMESHIFT__/$experiment_time_shift/g' >> merge_analyses_params.xml");
    }
    else {
       Exec("sed 's/__INPUT_MATRIX1__/$matrix/g' $ENV{DEVELOP_HOME}/Matlab/PlateReaderAnalyzer/merge_plates_from_different_experiments_params.xml >> merge_analyses_params.xml");
    }
  }
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

merge_platereader_analyses.pl <file>

   Merges several plate reader analysis files

   -f <files>: A comma-seprated list of files to merge. Can include wildcards (e.g., NormalizedData/Plate1/*.tab,NormalizedData/Plate2/*.tab)
   -same_exp <1/0>: State if plates were derived from the same experiment. If so, the merge will synchronize their times. Default is 0.
   -experiment_time_shift <str> : A list of times indicating shifts of experiments in time. For example: If for technical reasons the first measure of exp2 was actually 1sec later than exp1 than the string "0,1" will synchronize them. This option is not relevant if -same_exp is used.
    

