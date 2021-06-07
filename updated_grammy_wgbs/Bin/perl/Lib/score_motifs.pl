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

my $output_file = get_arg("o", "", \%args);
my $output_best_positions_file = get_arg("op", "", \%args);
my $output_all_scores_file = get_arg("oa", "", \%args);
my $output_all_positions_file = get_arg("oap", "", \%args);
my $promoters = get_arg("p", "$ENV{HOME}/Map/Data/Genome/Promoters/Yeast/500/data.fad", \%args);
my $pvalue = get_arg("pvalue", 0.05, \%args);
my $gxm_file = get_arg("gxm", "", \%args);
my $motif_score_type = get_arg("s", "Probability", \%args);
my $genelist = get_arg("genelist", "", \%args);
my $xml = get_arg("xml", 0, \%args);

my $r = int(rand(100000));

if (length($genelist) > 0)
{
  system("cp $genelist tmp_genelist.$r");
}
else
{
  system("fasta2stab.pl $promoters | cut -f1 > tmp_genelist.$r");
}

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Evals/score_motifs.map ";
$exec_str   .= "cluster_files=tmp_genelist.$r ";
$exec_str   .= "motif_score_type=$motif_score_type ";
$exec_str   .= "motif_file=$gxm_file ";
$exec_str   .= "promoters_file=$promoters ";
$exec_str   .= "pvalue=$pvalue ";
if (length($output_file) > 0) { $exec_str   .= "motif_scores_file=$output_file "; }
if (length($output_best_positions_file) > 0) { $exec_str   .= "motif_best_positions_file=$output_best_positions_file "; }
if (length($output_all_scores_file) > 0) { $exec_str   .= "motif_all_scores_file=$output_all_scores_file "; }
if (length($output_all_positions_file) > 0) { $exec_str   .= "motif_all_positions_file=$output_all_positions_file "; }
$exec_str   .= " -xml > tmp.$r";

system("$exec_str");

if ($xml == 1)
{
  system("cat tmp.$r");
}
else
{
  `$ENV{GENIE_EXE} tmp.$r >& /dev/null`;
}

`rm tmp.$r`;
`rm tmp_genelist.$r`;


__DATA__

score_motifs.pl

   Scores genes in Promoter files relative to given motifs

   -o <name>:        Output will be saved in this file.
   -oa <name>:       Output of all scores that pass the pvalue will be saved in this file.

   -op <name>:       If specified, best positions for motif hits will be saved in this file.
   -oap <name>:      If specified, all positions for motif hits will be saved in this file.

   -p <name>:        Promoter file (default: $ENV{HOME}/Map/Data/Genome/Promoters/Yeast/500/data.fad)

   -pvalue <num>:    P-value above which scores will be printed in case of printing all the scores (default: 0.05)

   -gxm <name>:      gxm file containing the input motifs

   -s <type>:        motif score type (Probability or MaxZScore, default: Probability)

   -genelist <name>: GeneList to work on (default: use all genes from the promoter file)

   -xml:             Only print the XML

