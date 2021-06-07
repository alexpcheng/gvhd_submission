#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

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

my %args = load_args(\@ARGV);

my $sequence_file = get_arg("s", "", \%args);
my $positive_sequences_list = get_arg("p", "", \%args);
my $negative_sequences_list = get_arg("n", "", \%args);
my $positive_sequences_file = get_arg("ps", "", \%args);
my $negative_sequences_file = get_arg("ns", "", \%args);
my $background_matrix_file = get_arg("bck", "", \%args);
my $input_weight_matrices_file = get_arg("gxw", 0, \%args);
my $output_files_prefix = get_arg("o", 0, \%args);
my $max_training_iterations = get_arg("i", 9, \%args);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

if (length($positive_sequences_file) == 0)
{
    system("cat $positive_sequences_list $negative_sequences_list > tmp_sequence_list_$r");

    system("add_column.pl $positive_sequences_list -s 1 | cap.pl 'G,1' > tmp_expression_$r;");
    system("add_column.pl $negative_sequences_list -s 0 >> tmp_expression_$r;");
}
else
{
    system("fasta2stab.pl $positive_sequences_file | cut -f1 > tmp_sequence_list_$r");
    system("fasta2stab.pl $negative_sequences_file | cut -f1 >> tmp_sequence_list_$r");

    system("fasta2stab.pl $positive_sequences_file | cut -f1 | add_column.pl -s 1 | cap.pl 'G,1' > tmp_expression_$r;");
    system("fasta2stab.pl $negative_sequences_file | cut -f1 | add_column.pl -s 0 >> tmp_expression_$r;");

    system("cat $positive_sequences_file $negative_sequences_file > tmp_sequences_$r");
    $sequence_file = "tmp_sequences_$r";
}


system("gxw2tab.pl $input_weight_matrices_file | cut -f1 | add_column.pl -s 1 | cap.pl 'G,1' > tmp_tf_expression_$r;");

system("gxw2tab.pl $input_weight_matrices_file | cut -f1 | add_column.pl -s 0.02 | cap.pl 'P,W' > tmp_tf_scaling_$r;");
system("gxw2tab.pl $input_weight_matrices_file | cut -f1 | add_column.pl -s 3 | cap.pl 'LogisticBias,-3' | cap.pl 'P,W' > tmp_tf_logistic_$r;");

my $exec_str = "sequence_expression_model.pl ";
$exec_str   .= "-m $input_weight_matrices_file ";
$exec_str   .= "-s $sequence_file ";
$exec_str   .= "-l tmp_sequence_list_$r ";
$exec_str   .= "-bck $background_matrix_file ";
$exec_str   .= "-e tmp_expression_$r ";
$exec_str   .= "-r tmp_tf_expression_$r ";
$exec_str   .= "-scaling tmp_tf_scaling_$r ";
$exec_str   .= "-logistic tmp_tf_logistic_$r ";
$exec_str   .= "-oscaling ${output_files_prefix}_scaling.tab ";
$exec_str   .= "-ologistic ${output_files_prefix}_logistic.tab ";
$exec_str   .= "-om ${output_files_prefix}_weight_matrices.gxw ";
$exec_str   .= "-mt SoftmaxSampling ";
$exec_str   .= "-n $max_training_iterations ";
$exec_str   .= "-ns 100 ";
$exec_str   .= "-smc ";
$exec_str   .= "-tswm ";
$exec_str   .= "-tapaswm ";

if ($xml == 1)
{
  $exec_str .= "-xml ";
}

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file, $save_xml_file);

__DATA__

optimize_gxw_by_discrimination.pl

   Takes in a gxw and positive and negative sequences and optimizes the weight matrices
   so that they get a high free energy in the positives and a low free energy in the negatives.

{
   -s <str>:    Sequence file
   -p <str>:    File for positive asequences (one sequence per row)
   -n <str>:    File for negative asequences (one sequence per row)
}
OR
{
   -ps <str>:   Positive sequence file
   -ns <str>:   Negative sequence file
}

   -o <str>:    Prefix for output files

   -bck <str>:  Background matrix file to load (optional, background will be computed form the sequences otherwise)

   -gxw <str>:  File for initial weight matrices

   -i <num>:    Max training iterations (default: 9)

   -xml:        print only the xml file
   -run <str>:  Print the stdout and stderr of the program into the file <str>
   -sxml <str>: Save the xml file into <str>

