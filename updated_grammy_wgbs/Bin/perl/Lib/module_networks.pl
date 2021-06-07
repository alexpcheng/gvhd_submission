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
my $output_file = get_arg("o", "module_networks.gxp", \%args);
my $metric = get_arg("m", "PCluster", \%args);
my $num_modules = get_arg("n", "50", \%args);
my $learn_num_modules_automatically = get_arg("auto_num_modules", 0, \%args);
my $separate_regulators = get_arg("separate_regulators", 0, \%args);
my $regulator_list = get_arg("r", "/u/erans/Data/Regulators/Yeast/all_regulators.lst", \%args);
my $continuous_splits = get_arg("continuous_splits", "0", \%args);
my $min_split_value = get_arg("min_split_value", "0.5", \%args);
my $max_split_value = get_arg("max_split_value", "-0.5", \%args);
my $min_split_size = get_arg("min_split_size", 5, \%args);
my $genelist = get_arg("genelist", "", \%args);
my $experimentlist = get_arg("explist", "", \%args);
my $genenames = get_arg("genenames", "", \%args);
my $print = get_arg("print", 0, \%args);
my $xml = get_arg("xml", 0, \%args);

$min_split_value =~ s/\"//g;
$max_split_value =~ s/\"//g;

my $r = int(rand(100000));

my @expression_files = split(/\,/, $expression_files_str);
my $num_expression_files = @expression_files;

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/module_networks.map ";
$exec_str   .= "expression_files=$expression_files_str ";
$exec_str   .= "num_expression_files=$num_expression_files ";
$exec_str   .= "metric=$metric ";
$exec_str   .= "num_modules=$num_modules ";
if ($learn_num_modules_automatically == 1) { $exec_str   .= "learn_num_modules_automatically=true "; }
if ($separate_regulators == 1) { $exec_str   .= "separate_regulators=$regulator_list "; }
$exec_str   .= "regulator_list=$regulator_list ";
if ($continuous_splits == 1)
{
  $exec_str .= "regulators_domain=Continuous ";
  $exec_str .= "min_split_value=$min_split_value ";
  $exec_str .= "max_split_value=$max_split_value ";
}
$exec_str .= "min_experiments_per_split=$min_split_size ";
if (length($genelist) > 0) { $exec_str .= "gene_list=$genelist "; }
if (length($experimentlist) > 0) { $exec_str .= "experiment_list=$experimentlist "; }
if (length($genenames) > 0) { $exec_str .= "gene_names_file=$genenames "; }
$exec_str   .= "output_file=$output_file -xml > tmp.$r";

if ($print == 1) { print "$exec_str\n"; }
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

module_networks.pl

   Uses map_learn to run Module Networks

   -e <f1,f2>:             List of all expression files, separated by commas

   -o <name>:              Output will be saved in this file (default: module_networks.gxp)

   -m <name>:              Metric name for clustering (default: PCluster)
   -n <num>:               Number of modules (default: 50)
   -auto_num_modules:      Automatically learn the number of modules (default: fixed number)
   -separate_regulators:   Regulators are initially in their own cluster (default: cluster regulators together with all data)

   -r <num>:               Regulator list (default: /u/erans/Data/Regulators/Yeast/all_regulators.lst)

   -continuous_splits      If specified, then splits on regulators will be continuous (default: discretize regulators)
   -min_split_value <num>: Minimum value to split on (for continuous splits, default: 0.5)
   -max_split_value <num>: Maximum value to split on (for continuous splits, default: -0.5)
   -min_split_size <num>:  Minimum number of experiments per split (default: 5)

   -genelist <name>:       GeneList to work on (default: use all genes)
   -explist <name>:        ExperimentList to work on (default: use all experiments)

   -genenames <name>:      Gene names to print (default: the yeast gene list)

   -print:                 Print the command to the xml
   -xml:                   Only print the xml to STDOUT without running the program

