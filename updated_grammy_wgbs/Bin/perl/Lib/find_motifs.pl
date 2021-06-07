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

my $output_file = get_arg("o", "motifs.out", \%args);
my $motif_output_file = get_arg("gxm", "motifs.gxm", \%args);
my $promoters = get_arg("p", "$ENV{HOME}/Map/Data/Genome/Promoters/Yeast/500/data.fad", \%args);
my $membership_clusters_file = get_arg("m", "", \%args);
my $motif_length = get_arg("l", 15, \%args);
my $gxp_file = get_arg("gxp", "", \%args);
my $xml = get_arg("xml", 0, \%args);

my $r = int(rand(100000));

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Evals/find_motifs.map ";

if (length($membership_clusters_file) > 0)
{
  $exec_str .= "cluster_file=$membership_clusters_file ";
  $exec_str .= "cluster_file_format=MembershipMatrix ";
}

if (length($gxp_file) > 0)
{
  $exec_str .= "file=$gxp_file ";
}

$exec_str   .= "output_file=$output_file ";
$exec_str   .= "motif_output_file=$motif_output_file ";

$exec_str   .= "pssm_length=$motif_length ";

$exec_str   .= "promoters_file=$promoters ";
$exec_str   .= "positive_negative_ratio=1 ";
$exec_str   .= "pvalue=0.05 ";
$exec_str   .= "-xml > tmp.$r";

system("$exec_str");

#print "$exec_str\n";

if ($xml == 1)
{
  system("cat tmp.$r");
}
else
{
  `$ENV{GENIE_EXE} tmp.$r >& /dev/null`;
}

`rm tmp.$r`;

__DATA__

find_motifs.pl

   Finds motifs in Promoter files from clusters

   -o <name>:        Output will be saved in this file (default: motifs.out)
   -gxm <name>:      Output gxm file for the motifs (default: motifs.gxm)

   -p <name>:        Promoter file (default: $ENV{HOME}/Map/Data/Genome/Promoters/Yeast/500/data.fad)

   -m <file_name>:   Membership matrix for clusters to analyze

   -gxp <file name>: gxp file to analyze

   -l num>:          Motif length (default: 15)

   -xml:             Only print the XML

