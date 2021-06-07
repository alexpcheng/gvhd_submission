#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $output_file = get_arg("o", "cluster.gxp", \%args);
my $num_clusters = get_arg("c", 5, \%args);
my $gene_list = get_arg("g", "", \%args);
my $experiment_list = get_arg("e", "", \%args);
my $cluster_metric = get_arg("m", "PCluster", \%args);
my $treeview = get_arg("treeview", 0, \%args);
my $xml = get_arg("xml", 0, \%args);

my $r = int(rand(100000));

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/cluster.map ";
$exec_str   .= "expression_file=$file ";
$exec_str   .= "num_modules=$num_clusters ";
$exec_str   .= "structure_force_split=true ";

if (length($gene_list) > 0) { $exec_str .= "gene_list=$gene_list "; }
if (length($experiment_list) > 0) { $exec_str .= "experiment_list=$experiment_list "; }

$exec_str .= "cluster_metric=$cluster_metric ";

if ($treeview == 1) { $exec_str .= "output_format=TreeView "; }
else
{
  $exec_str .= "output_format=Attributes ";
  $exec_str .= "print_genexpress=true ";
}

$exec_str .= "output_file=$output_file -xml > tmp.$r";

&RunGenie($exec_str, $xml, "tmp.$r", "");

__DATA__

cluster.pl <file>

   Clusters the input file.

   -o <name>: Cluster output will be saved in this file (default: cluster.gxp)
   -c <num>:  Number of clusters (default: 5)
   -g <name>:  If specified, will use <name> as the gene list
   -e <name>:  If specified, will use <name> as the experiment list
   -m <name>:  Clustering metric Pearson/PCluster/Euclidean (default: PCluster)
   -treeview:  If specified, output will be tree view format

   -xml:       Print only the xml file

