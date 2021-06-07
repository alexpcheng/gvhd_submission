#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit(0);
}

my %args = load_args(\@ARGV);

my $gene_list = get_arg("l", "", \%args);
my $gene_universe = get_arg("u", "", \%args);
my $membership_clusters_file = get_arg("m", "", \%args);
my $gxp_file = get_arg("gxp", "", \%args);
my $analyze_experiments = get_arg("exp", 0, \%args);
my $annotation_file = get_arg("a", "", \%args);
my $max_pvalue = get_arg("p", "0.05", \%args);
my $min_hits = get_arg("min_hits", "3", \%args);
my $multiple_hypothesis_correction = get_arg("c", "", \%args);
my $print_members = get_arg("print_members", 0, \%args);
my $statistic_test_type = get_arg("s", "HyperGeometric", \%args);
my $xml = get_arg("xml", 0, \%args);

my $r = int(rand(100000000000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Evals/genesets_overlap.map ";

if (length($gene_list) > 0 and length($gene_universe) > 0)
{
  $exec_str .= "cluster_files=$gene_list,$gene_universe ";
  $exec_str .= "cluster_file_format=MultipleFiles ";
}

if (length($membership_clusters_file) > 0)
{
  $exec_str .= "cluster_file=$membership_clusters_file ";
  $exec_str .= "cluster_file_format=MembershipMatrix ";
}

if ($analyze_experiments == 1)
{
  $exec_str .= "attributes_type=ExperimentAttributes ";
}

$exec_str .= &AddStringProperty("statistic_test_type", $statistic_test_type);

if ($multiple_hypothesis_correction eq "FDR")
{
  $exec_str .= "multiple_hypothesis_correction=FDR ";
}
elsif ($multiple_hypothesis_correction eq "Bonferroni")
{
  $exec_str .= "multiple_hypothesis_correction=Bonferroni ";
}

if (length($gxp_file) > 0)
{
  $exec_str .= "file=$gxp_file ";
}

if ($print_members == 1)
{
  $exec_str .= "output_intersecting_members=true ";
}

$exec_str   .= "max_pvalue=$max_pvalue ";
$exec_str   .= "min_hits=$min_hits ";

$exec_str   .= "genesets_file=$annotation_file ";
$exec_str   .= "output_file=$tmp_clu -xml";

#print STDERR "Executing $exec_str\n";
system("$exec_str > $tmp_xml");

if ($xml == 1)
{
  system("cat $tmp_xml");
}
else
{
  #print STDERR "Executing $ENV{GENIE_EXE} $tmp_xml >& /dev/null\n";
  `$ENV{GENIE_EXE} $tmp_xml >& /dev/null`;
  system("cat $tmp_clu");
  `rm $tmp_clu`;
}

#system("genesets2tab.pl $tmp_clu");

`rm $tmp_xml`;

__DATA__

compute_enrichment.pl <gene list file> <gene universe> <annotation file>

   Computes the hypergeometric enrichment of the gene list
   for the annotation file with respect to the gene universe

   As another input, a membership matrix for clusters can be supplied
   with the -m option (binary file, rows are genes, columns are clusters)

   -l <file name>:   List of genes to analyze
   -u <file name>:   List of all the genes (the 'universe')

   -m <file_name>:   Membership matrix for clusters to analyze

   -gxp <file name>: gxp file to analyze

   -exp:             If specified, then analyze experiments (default: genes)

   -a <file name>:   Annotation file

   -p <num>:         P-value (default: 0.05)
   -min_hits <num>:  Minimum annotation hits (default: 3)

   -print_members:   Print the intersecting members of each significant association

   -c <correction>:  Multiple hypothesis correction (FDR/Bonferroni)

   -s <str>:         Statistic test type (HyperGeometric/KolmogorovSmirnov/TTest, default: HyperGeometric)

   -xml:             Only print the XML

