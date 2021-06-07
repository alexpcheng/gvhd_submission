#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $output_file = get_arg("o", "pairwise_correlations.tab", \%args);
my $metric = get_arg("m", "Pearson", \%args);
my $genelist = get_arg("genelist", "", \%args);
my $cutoff = get_arg("c", "", \%args);
my $absolute_cutoff = get_arg("ac", "", \%args);
my $experimentlist = get_arg("explist", "", \%args);
my $experiment_correlations = get_arg("exps", 0, \%args);
my $randomize_columns = get_arg("rand_col", 0, \%args);
my $randomize_rows = get_arg("rand_row", 0, \%args);
my $randomize_matrix = get_arg("rand_matrix", 0, \%args);
my $min_dimensions = get_arg("mind", "", \%args);
my $pairs_file = get_arg("pairs", "", \%args);
my $xml = get_arg("xml", 0, \%args);

my $r = int(rand(100000));

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/pairwise_correlations.map ";
$exec_str   .= "expression_file=$file ";
if (length($cutoff) > 0) { $exec_str .= "cutoff=$cutoff "; }
if (length($absolute_cutoff) > 0) { $exec_str .= "absolute_cutoff=$absolute_cutoff "; }
if (length($genelist) > 0) { $exec_str .= "gene_list=$genelist "; }
if (length($experimentlist) > 0) { $exec_str .= "experiment_list=$experimentlist "; }
if ($randomize_columns == 1) { $exec_str .= "randomize_microarrays=true permute_type=ByColumns "; }
if ($randomize_rows == 1) { $exec_str .= "randomize_microarrays=true permute_type=ByRows "; }
if ($randomize_matrix == 1) { $exec_str .= "randomize_microarrays=true permute_type=Matrix "; }
if ($experiment_correlations == 1) { $exec_str .= "attributes_type=ExperimentAttributes "; }
if (length($min_dimensions) > 0) { $exec_str .= "min_dimensions=$min_dimensions "; }
if (length($pairs_file) > 0) { $exec_str .= "pairs_file=$pairs_file "; }
$exec_str   .= "output_file=$output_file -xml > tmp.$r";

print "$exec_str\n";
system("$exec_str");

if ($xml == 1)
{
  system("cat tmp.$r");
}
else
{
  system("$ENV{GENIE_EXE} tmp.$r");
}

#system("rm tmp.$r");

__DATA__

pairwise_correlations.pl <file>

   Uses map_learn to compute the pairwise correlations

   -o <name>:        Output will be saved in this file (default: pairwise_correlations.tab)

   -m <name>:        Metric name (default: Pearson)

   -c <num>:         Cutoff of metric (default: no cutoff)
   -ac <num>:        Absolute Cutoff of metric (default: no cutoff)

   -mind <num>:      Minimum number of dimensions that must exist between the vectors (default: 1)

   -exps:            If specified, then compute correlations between experiments (default: genes)

   -rand_col:        If specified, then randomize the columns of the microarray before computing correlations
   -rand_row:        If specified, then randomize the rows of the microarray before computing correlations
   -rand_matrix:     If specified, then randomize the matrix of the microarray before computing correlations

   -genelist <name>: GeneList to work on (default: use all genes)
   -explist <name>:  ExperimentList to work on (default: use all experiments)

   -pairs <name>:    Pairs file (compute only correlations between these pairs)

   -xml:             Only output the xml of map_learn

