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

my $expression_files_str = get_arg("f", 0, \%args);
my $geneset_files_str = get_arg("g", 0, \%args);
my $geneset_clusters_file = get_arg("geneset_clusters", "", \%args);
my $auto_cluster_genesets = get_arg("auto_cluster_genesets", 0, \%args);
my $min_cost_difference_from_parent = get_arg("min_cost_difference", 0.05, \%args);
my $max_cost_of_parent_cluster_for_singleton = get_arg("max_cost_singleton", 0.7, \%args);
my $max_cluster_size = get_arg("max_cluster_size", 50, \%args);
my $gene_attribute_files_str = get_arg("gene_attributes", "", \%args);
my $experiment_attribute_files_str = get_arg("exp_attributes", "", \%args);
my $output_prefix = get_arg("o", "genesets", \%args);
my $min_up_regulation = get_arg("min_up_regulation", "1", \%args);
my $max_down_regulation = get_arg("max_down_regulation", "-1", \%args);
my $max_pvalue = get_arg("p", "0.05", \%args);
my $max_pvalue_expression = get_arg("p_expression", $max_pvalue, \%args);
my $max_pvalue_gene_hits = get_arg("p_gene_hits", $max_pvalue, \%args);
my $max_pvalue_gene_enrichments = get_arg("p_genes", $max_pvalue, \%args);
my $max_pvalue_experiment_enrichments = get_arg("p_exps", $max_pvalue, \%args);
my $min_hits = get_arg("min_hits", "3", \%args);
my $multiple_hypothesis_correction = get_arg("c", "", \%args);
my $multiple_hypothesis_correction_expression = get_arg("c_expression", $multiple_hypothesis_correction, \%args);
my $multiple_hypothesis_correction_gene_enrichments = get_arg("c_genes", $multiple_hypothesis_correction, \%args);
my $multiple_hypothesis_correction_experiment_enrichments = get_arg("c_exps", $multiple_hypothesis_correction, \%args);
my $gxp_output_file = get_arg("gxp", "", \%args);
my $xml = get_arg("xml", 0, \%args);

my @expression_files = split(/\,/, $expression_files_str);
my $num_expression_files = @expression_files;

my @geneset_files = split(/\,/, $geneset_files_str);
my $num_geneset_files = @geneset_files;

my @gene_attribute_files = split(/\,/, $gene_attribute_files_str);
my $num_gene_attribute_files = @gene_attribute_files;

my @experiment_attribute_files = split(/\,/, $experiment_attribute_files_str);
my $num_experiment_attribute_files = @experiment_attribute_files;

my $r = int(rand(100000));

my $auto_cluster_genesets_str = "";
if (length($geneset_clusters_file) == 0)
{
  if ($auto_cluster_genesets == 0)
  {
    $geneset_clusters_file = "tmp_geneset_clusters.$r";
    open(GENESET_CLUSTERS_OUT, ">$geneset_clusters_file");
    my $num_genesets = 0;
    my @all_genesets;
    for (my $i = 0; $i < $num_geneset_files; $i++)
    {
      my $genesets_str = `head -1 $geneset_files[$i] | cut -f2-`;
      chop $genesets_str;
      my @row = split(/\t/, $genesets_str);
      for (my $j = 0; $j < @row; $j++)
      {
	push(@all_genesets, $row[$j]);
      }
      $num_genesets += @row;
    }

    print GENESET_CLUSTERS_OUT "Modules\tModule 1\n";

    for (my $i = 0; $i < $num_genesets; $i++)
    {
      print GENESET_CLUSTERS_OUT "$all_genesets[$i]\t1\n";
    }
  }
  else
  {
    $auto_cluster_genesets_str .= "auto_cluster_genesets=true ";
    $auto_cluster_genesets_str .= "min_cost_difference_from_parent=$min_cost_difference_from_parent ";
    $auto_cluster_genesets_str .= "max_cost_of_parent_cluster_for_singleton=$max_cost_of_parent_cluster_for_singleton ";
    $auto_cluster_genesets_str .= "max_cluster_size=$max_cluster_size ";
  }
}

my $exec_str = "bind.pl $ENV{HOME}/develop/genie/Templates/Runs/genesets.map ";
$exec_str   .= "expression_files=$expression_files_str ";
$exec_str   .= "num_expression_files=$num_expression_files ";
$exec_str   .= "geneset_files=$geneset_files_str ";
$exec_str   .= "num_geneset_files=$num_geneset_files ";

if (length($geneset_clusters_file) > 0)
{
  $exec_str   .= "geneset_clusters_file=$geneset_clusters_file ";
}

$exec_str .= $auto_cluster_genesets_str;

if ($num_gene_attribute_files > 0)
{
  $exec_str   .= "gene_attribute_files=$gene_attribute_files_str ";
  $exec_str   .= "num_gene_attribute_files=$num_gene_attribute_files ";
}

if ($num_experiment_attribute_files > 0)
{
  $exec_str   .= "experiment_attribute_files=$experiment_attribute_files_str ";
  $exec_str   .= "num_experiment_attribute_files=$num_experiment_attribute_files ";
}

$exec_str   .= "min_up_regulation=$min_up_regulation ";
$exec_str   .= "max_down_regulation=$max_down_regulation ";

$exec_str   .= "max_pvalue_expression=$max_pvalue_expression ";
$exec_str   .= "max_pvalue_gene_hits=$max_pvalue_gene_hits ";
$exec_str   .= "max_pvalue_gene_enrichments=$max_pvalue_gene_enrichments ";
$exec_str   .= "max_pvalue_experiment_enrichments=$max_pvalue_experiment_enrichments ";

if (length($multiple_hypothesis_correction_expression) > 0)
{
  $exec_str   .= "multiple_hypothesis_correction_expression=$multiple_hypothesis_correction_expression ";
}

if (length($multiple_hypothesis_correction_gene_enrichments) > 0)
{
  $exec_str   .= "multiple_hypothesis_correction_gene_enrichments=$multiple_hypothesis_correction_gene_enrichments ";
}

if (length($multiple_hypothesis_correction_experiment_enrichments) > 0)
{
  $exec_str   .= "multiple_hypothesis_correction_experiment_enrichments=$multiple_hypothesis_correction_experiment_enrichments ";
}

if (length($gxp_output_file) > 0)
{
  $exec_str   .= "gxp_output_file=$gxp_output_file ";
}

$exec_str   .= "min_hits=$min_hits ";

$exec_str   .= "output_file_prefix=$output_prefix ";

$exec_str   .= "-xml > tmp.$r";
#print STDERR "$exec_str\n";
system("$exec_str");

if ($xml eq "1")
{
  system("cat tmp.$r");
}
else
{
  system("$ENV{GENIE_EXE} tmp.$r");
}

#system("rm -f tmp.$r tmp_geneset_clusters.$r");
system("rm -f tmp.$r");

__DATA__

genesets.pl <file>

   Performs a geneset analysis 

   -f <f1,f2>:                 List of all expression files, separated by commas

   -g <c1,c2>:                 List of all input geneset files, separated by commas

   -geneset_clusters <file>:   Geneset clusters from which to create modules
                               (default: make a module from each gene set separately)

   -auto_cluster_genesets:     Find the clusters of gene sets automatically
   -min_cost_difference <num>: The min. difference between a node and parent cost for a cluster
                               to be called interesting (only applicable with the auto_geneset_cluster option)
                               (default: 0.05)
   -max_cost_singleton <num>:  The max. cost of a parent cluster below which a leaf is called interesting 
                               (only applicable with the auto_geneset_cluster option) (default: 0.7)
   -max_cluster_size <num>:    The max. size of an interesting cluster (default: 50)

   -gene_attributes <f1,f2>:   List of all gene attribute enrichment files, separated by commas
   -exp_attributes <f1,f2>:    List of all experiment attribute enrichment files, separated by commas

   -o <name>:                  Prefix of the output to save

   -min_up_regulation <num>:   Min up-regulation (default: 1)
   -max_down_regulation <num>: Max down-regulation (default: -1)

   -p <num>:                   Max pvalue for all statistical analyses (default: 0.05)
   -p_expression <num>:        Max pvalue for expression enrichments (default: take from the -p option)
   -p_gene_hits <num>:         Max pvalue for expression enrichments (default: take from the -p option)
   -p_genes <num>:             Max pvalue for gene enrichments (default: take from the -p option)
   -p_exps <num>:              Max pvalue for gene enrichments (default: take from the -p option)

   -min_hits <num>:            Minimum number of hits for all statistical analyses (default: 3)
   -c <correction>:            Multiple hypothesis correction for all statistical analyses (FDR/Bonferroni)

   -gxp <name>:                If specified, the name of the gxp file to output (default: no gxp is printed)

   -xml:                       Only print the XML

