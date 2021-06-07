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


# my $file_ref;
# my $file = $ARGV[0];
# if (length($file) < 1 or $file =~ /^-/) 
# {
  # $file_ref = \*STDIN;
# }
# else
# {
  # open(FILE, $file) or die("Could not open file '$file'.\n");
  # $file_ref = \*FILE;
# }

my %args = load_args(\@ARGV);

my $sequence_file = get_arg("s", "", \%args);
my $sequences_list = get_arg("l", "", \%args);
my $sequence_alignment_file = get_arg("a", "", \%args);
my $alignment_name = get_arg("an", "SimpleAlignment", \%args);
my $alignment_start = get_arg("as", 0, \%args);
my $alignment_end = get_arg("ae", -1, \%args);
my $markov_order = get_arg("m", 0, \%args);
my $realign_sequences = get_arg("realign", 0, \%args);
my $allow_reverse_complement_when_realigning_sequences = get_arg("rc", 0, \%args);
my $compute_shared_positions = get_arg("shared", 0, \%args);
my $min_unique_positions = get_arg("unique", 1, \%args);
my $weight_matrix_name = get_arg("w", "Matrix", \%args);
my $symmetric_matrix = get_arg("sym", 0, \%args);
my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/alignment2gxw.map ";

$exec_str .= "sequence_file=$sequence_file ";

if (length($sequences_list) > 0)
{
    $exec_str .= "sequence_list=$sequences_list ";
}

$exec_str .= "sequence_alignment_file=$sequence_alignment_file ";
$exec_str .= "alignment_name=$alignment_name ";
$exec_str .= "alignment_start=$alignment_start ";
$exec_str .= "alignment_end=$alignment_end ";

$exec_str .= "markov_order=$markov_order ";
$exec_str .= "weight_matrix_name=$weight_matrix_name ";

my $markov_order_constraints = &get_arg("moc", "", \%args);
$markov_order_constraints =~ s/;/___SEMI_COLON___/g;
$exec_str .= &AddStringProperty("markov_order_constraints", $markov_order_constraints);

$exec_str .= &AddStringProperty("left_padding_positions", get_arg("lp", 0, \%args));
$exec_str .= &AddStringProperty("right_padding_positions", get_arg("rp", 0, \%args));
$exec_str .= &AddBooleanProperty("double_strand_binding", get_arg("ds", 0, \%args));
$exec_str .= &AddBooleanProperty("force_double_strand_binding", get_arg("force_ds", 0, \%args));

$exec_str .= &AddStringProperty("maximum_allowed_sequence_inserts", &get_arg("masi", "", \%args));
$exec_str .= &AddBooleanProperty("force_double_strand_on_sequence_insert", &get_arg("fdsosi", "", \%args));
$exec_str .= &AddStringProperty("sequence_insert_penalty", &get_arg("sip", "", \%args));

$exec_str .= &AddStringProperty("initial_weight_matrix_file", get_arg("init", "", \%args));
$exec_str .= &AddStringProperty("initial_weight_matrix_name", get_arg("initm", "", \%args));

$exec_str .= &AddStringProperty("output_sequence_alignment_file", get_arg("oa", "", \%args));

if ($realign_sequences == 1) { $exec_str .= "realign_sequences=true "; }
if ($allow_reverse_complement_when_realigning_sequences == 1) { $exec_str .= "allow_reverse_complement_when_realigning_sequences=true "; }
if ($compute_shared_positions == 1) { $exec_str .= "compute_shared_positions=true "; }
if (length($min_unique_positions) > 0) { $exec_str .= "min_unique_positions=$min_unique_positions "; }

if ($symmetric_matrix == 1) { $exec_str .= "symmetric_matrix=true "; }

$exec_str .= "weight_matrices_file=$tmp_clu ";

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file)

__DATA__

alignment2gxw.pl 

   Takes in sequences and an alignment file and learns a weight matrix out of it

   -s <str>:     Sequence file
   -l <str>:     Use only these sequences from the file <str> (default: use all sequences in fasta file)

   -a <str>:     Alignment file
   -an <str>:    Alignment name (default: SimpleAlignment)
   -as <num>:    Alignment start (default: 0)
   -ae <num>:    Alignment end (default: -1)

   -m <num>:     Markov order (default: 0)
   -moc <str>:   Markov order constraints. Format example: "1;TA;AA;TT;GC:0;A" will estimate parameters
                 only for the dinucleotides TA,AA,TT,GC and mononucleotide A, and equalize all other entries

   -w <str>:     Weight Matrix name (default: Matrix)

   -shared:      Use Bayesian score to find sharing between the parameters (default: no sharing)
   -unique:      Minimum number of positions that must still be unique  (default: 1)
   -realign:     Realign the sequences based on the weight matrix (default: no realigning)
   -rc:          Allow reverse complement when realigning sequences (default: do not allow)

   -lp <num>:    Left padding positions (default: 0)
   -rp <num>:    Right padding positions (default: 0)
   -ds:          Create the matrix as a double-strand binding matrix
   -force_ds:    Forces double stranded binding but not as part of the matrix

   -masi <num>:  Maximum allowed sequence inserts
   -fdsosi:      Force double strand when doing sequence inserts
   -sip <num>:   Sequence insert penalty

   -init <str>:  Initial weight matrix file (default: construct new matrix)
   -initm <str>: Initial name of weight matrix in initial weight matrix file

   -oa <str>:    Output alignment file

   -sym:         Use Symmetric matrices (default: asymmetric matrix)

   -xml:         Print only the xml file

