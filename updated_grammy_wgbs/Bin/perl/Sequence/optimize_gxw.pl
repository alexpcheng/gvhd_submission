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
my $sequences_list = get_arg("l", "", \%args);
my $input_weight_matrices_file = get_arg("gxw", 0, \%args);
my $markov_order = get_arg("m", 0, \%args);
my $weight_matrix_name = get_arg("w", "Matrix", \%args);
my $weight_matrix_length = get_arg("wl", 8, \%args);
my $realign_sequences = get_arg("realign", 0, \%args);
my $allow_reverse_complement_when_realigning_sequences = get_arg("rc", 0, \%args);
my $compute_shared_positions = get_arg("shared", 0, \%args);
my $min_unique_positions = get_arg("unique", 1, \%args);
my $symmetric_matrix = get_arg("sym", 0, \%args);
my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/optimize_gxw.map ";

$exec_str .= "sequence_file=$sequence_file ";

if (length($sequences_list) > 0)
{
    $exec_str .= "sequence_list=$sequences_list ";
}

$exec_str .= "input_weight_matrices_file=$input_weight_matrices_file ";
$exec_str .= "markov_order=$markov_order ";
$exec_str .= "weight_matrix_name=$weight_matrix_name ";
$exec_str .= "weight_matrix_length=$weight_matrix_length ";

if ($realign_sequences == 1) { $exec_str .= "realign_sequences=true "; }
if ($allow_reverse_complement_when_realigning_sequences == 1) { $exec_str .= "allow_reverse_complement_when_realigning_sequences=true "; }
if ($compute_shared_positions == 1) { $exec_str .= "compute_shared_positions=true "; }
if (length($min_unique_positions) > 0) { $exec_str .= "min_unique_positions=$min_unique_positions "; }

if ($symmetric_matrix == 1) { $exec_str .= "symmetric_matrix=true "; }

$exec_str .= "weight_matrices_file=$tmp_clu ";

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file, $save_xml_file);

__DATA__

optimize_gxw.pl <file>

   Takes in a gxw and sequences and optimizes the weight matrix on the sequences

   -s <str>:   Sequence file
   -l <str>:   Use only these sequences from the file <str> (default: use all sequences in fasta file)

   -gxw <str>: File for initial weight matrices
   -m <num>:   Markov order (default: 0)
   -w <str>:   Weight Matrix name to use from the file (default: Matrix)
   -wl <num>:  Weight Matrix length (default: 8)

   -shared:    Use Bayesian score to find sharing between the weight matrix parameters (default: no sharing)
   -unique:    Minimum number of positions that must still be unique  (default: 1)
   -realign:   Realign the sequences based on the weight matrix (default: no realigning)
   -rc:        Allow reverse complement when realigning sequences (default: do not allow)

   -sym:       Use Symmetric matrices (default: asymmetric matrix)

   -xml:       Print only the xml file
   -run <str>:  Print the stdout and stderr of the program into the file <str>
   -sxml <str>: Save the xml file into <str>

