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
my $background_matrix_file = get_arg("bck", "", \%args);
my $background_to_matrices_ratio = get_arg("bckr", "-1", \%args);
my $weight_matrix_name = get_arg("w", "Matrix", \%args);
my $weight_matrix_length = get_arg("wl", 8, \%args);
my $compute_shared_positions = get_arg("shared", 0, \%args);
my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/optimize_gxw_by_free_energy.map ";

$exec_str .= "sequence_file=$sequence_file ";

if (length($sequences_list) > 0)
{
    $exec_str .= "sequence_list=$sequences_list ";
}

if (length($background_matrix_file) > 0) { $exec_str .= "background_matrix_file=$background_matrix_file "; }

$exec_str .= "input_weight_matrices_file=$input_weight_matrices_file ";
$exec_str .= "markov_order=$markov_order ";
$exec_str .= "weight_matrix_name=$weight_matrix_name ";
$exec_str .= "weight_matrix_length=$weight_matrix_length ";
$exec_str .= &AddStringProperty("background_to_matrices_ratio", $background_to_matrices_ratio);
$exec_str .= &AddStringProperty("max_training_iterations", &get_arg("i", 100, \%args));

if ($compute_shared_positions == 1) { $exec_str .= "compute_shared_positions=true "; }

if (&get_arg("sa", 0, \%args) == 1)
{
    $exec_str .= &AddStringProperty("start_temperature", &get_arg("sast", 0.1, \%args));
    $exec_str .= &AddStringProperty("end_temperature", &get_arg("saet", 1.0, \%args));
    $exec_str .= &AddStringProperty("temperature_increment", &get_arg("sati", 0.02, \%args));
}

$exec_str .= "weight_matrices_file=$tmp_clu ";

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file, $save_xml_file);

__DATA__

optimize_gxw_by_free_energy.pl <file>

   Takes in a gxw and sequences and optimizes the weight matrix on the sequences using free energy

   -s <str>:    Sequence file
   -l <str>:    Use only these sequences from the file <str> (default: use all sequences in fasta file)

   -bck <str>:  Background matrix file to load (optional, background will be computed form the sequences otherwise)
   -bckr <num>: Background matrix to matrices ratio (default: -1 for equal value between background and matrices)

   -gxw <str>:  File for initial weight matrices
   -m <num>:    Markov order (default: 0)
   -w <str>:    Weight Matrix name to use from the file (default: Matrix)
   -wl <num>:   Weight Matrix length (default: 8)

   -i <num>:    Max training iterations (default: 100)

   -shared:     Use Bayesian score to find sharing between the weight matrix parameters (default: no sharing)

   -sa:         Simulated annealing
   -sast <num>: Simulated annealing start temperature (default: 0.1)
   -saet <num>: Simulated annealing end temperature (default: 1.0)
   -sati <num>: Simulated annealing temperature increment (default: 0.02)

   -xml:        Print only the xml file
   -run <str>:  Print the stdout and stderr of the program into the file <str>
   -sxml <str>: Save the xml file into <str>

