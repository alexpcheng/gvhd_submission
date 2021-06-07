#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $expression_files_str = get_arg("e", 0, \%args);
my $chromosome_locations_file = get_arg("chr_file", "", \%args);
my $output_file = get_arg("o", "chromosome_domains.gxt", \%args);
my $output_track_name = get_arg("t", "Hmm_Track", \%args);
my $genelist = get_arg("genelist", "", \%args);
my $experimentlist = get_arg("explist", "", \%args);
my $min_value = get_arg("min_value", "0.5", \%args);
my $max_value = get_arg("max_value", "-0.5", \%args);
my $initialization_output_file = get_arg("init_output_file", "", \%args);
my $initialization_output_track_name = get_arg("init_output_track", "Statistic_Track", \%args);
my $base_pair_window = get_arg("bp_window", "100000000", \%args);
my $num_genes_window = get_arg("window", "5", \%args);
my $min_count = get_arg("min_count", "3", \%args);
my $min_pvalue = get_arg("min_pvalue", "0.1", \%args);
my $multiple_hypothesis_correction = get_arg("c", "", \%args);
my $cpd_output_track_file = get_arg("cpd_output_track", "", \%args);
my $discrete_model = get_arg("discrete", 0, \%args);
my $no_model = get_arg("no_model", 0, \%args);
my $print = get_arg("print", 0, \%args);
my $log_file = get_arg("log", "map.log", \%args);
my $xml = get_arg("xml", 0, \%args);

$max_value =~ s/\"//g;
$min_value =~ s/\"//g;

my $r = int(rand(100000));

my @expression_files = split(/\,/, $expression_files_str);
my $num_expression_files = @expression_files;

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/find_chromosome_domains.map ";

$exec_str   .= "expression_files=$expression_files_str ";
$exec_str   .= "chromosome_locations_file=$chromosome_locations_file ";
$exec_str   .= "num_expression_files=$num_expression_files ";

if (length($genelist) > 0) { $exec_str .= "gene_list=$genelist "; }
if (length($experimentlist) > 0) { $exec_str .= "experiment_list=$experimentlist "; }

$exec_str   .= "min_value=$min_value ";
$exec_str   .= "max_value=$max_value ";

if (length($initialization_output_file) > 0) { $exec_str .= "initialization_output_file=$initialization_output_file "; }
$exec_str .= "initialization_output_track_name=$initialization_output_track_name ";
$exec_str   .= "base_pair_window=$base_pair_window ";
$exec_str   .= "num_genes_window=$num_genes_window ";
$exec_str   .= "min_count=$min_count ";
$exec_str   .= "min_pvalue=$min_pvalue ";
if (length($multiple_hypothesis_correction) > 0) { $exec_str .= "multiple_hypothesis_correction=$multiple_hypothesis_correction "; }

if ($discrete_model == 1) { $exec_str .= "microarray_discrete_domain=true "; }

if ($no_model == 0) { $exec_str .= "run_model=true "; }

if (length($cpd_output_track_file) > 0) { $exec_str .= "cpd_output_track_file=$cpd_output_track_file "; }

$exec_str   .= "output_track_name=$output_track_name ";
$exec_str   .= "log_file=$log_file ";
$exec_str   .= "output_file=$output_file -xml > tmp.$r";

if ($print == 1) { print STDERR "$exec_str\n"; }
system("$exec_str");

if ($xml eq "1")
{
  system("cat tmp.$r");
}
else
{
  system("$ENV{GENIE_EXE} tmp.$r");
}

system("rm tmp.$r");

__DATA__

find_chromosome_domains.pl

   Uses map_learn to find chromosomal domains

   -e <f1,f2>:                List of all expression files, separated by commas

   -chr_file <name>:          Name of chromosome locations file

   -o <name>:                 Output will be saved in this file (default: chromosome_domains.gxt)
   -t <name>:                 Name of the GeneXPress track to output (default: Hmm_Track)

   -genelist <name>:          GeneList to work on (default: use all genes)
   -explist <name>:           ExperimentList to work on (default: use all experiments)

   -min_value <num>:          Initialization: minimum expression above which a gene is overexpressed (default: 0.5)
   -max_value <num>:          Initialization: maximum expression below which a gene is underexpressed (default: -0.5) (type "'-1'" for negatives)

   -init_output_file <name>:  Initialization: output file for storing the initialization domain results
   -init_output_track <name>: Initialization: name of the GeneXPress track to create (default: Statistic_Track)

   -bp_window <num>:          Initialization: max number of bp for window (default: 100,000,000)
   -window <num>:             Initialization: number of genes in bp window (default: 5)
   -min_count <num>:          Initialization: minimum number of hits in a window (default: 3)
   -min_pvalue <num>:         Initialization: max pvalue for hit (default: 0.1)
   -c <name>:                 Initialization: multiple hypothesis correction (None/FDR/Bonferonni) (default: None)

   -num_cv <num>:             Number of cross validations (default: no test data runs)
   -test_output_file <name>:  Output file for cross validation results

   -cpd_output_track <name>:  Output file for Cpd track

   -discrete:                 Runs a discrete hmm model (default is a continuous model)

   -no_model:                 Does not run the hmm model (only initialization)

   -print:                    Print the command to the xml
   -log:                      Name of the log file (default: map.log)
   -xml:                      Only print the xml to STDOUT without running the program

