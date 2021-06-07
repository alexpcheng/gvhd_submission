#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";


#######################
#
# Loading args:

my %args = load_args(\@ARGV);


my $xml = get_arg("xml", 0, \%args);
my $log_file = get_arg("log", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $seqs = get_arg("seqs", "", \%args);
die "ERROR - input sequences file name not given.\n" if ( $seqs eq "" );
die "ERROR - input sequences file ($seqs) not found.\n" unless ( -e $seqs );

my $locations = get_arg("locations", "", \%args);
die "ERROR - nucleosome locations file name not given.\n" if ( $locations eq "" );
die "ERROR - nucleosome locations file ($locations) not found.\n" unless ( -e $locations );

my $nuc = get_arg("nuc", "", \%args);
die "ERROR - nucleosome weight matrix file name not given.\n" if ( $nuc eq "" );

my $nuc_pos_indep = get_arg("nuc_pos_indep", "", \%args);

my $nuc_name = get_arg("nuc_name", "Nucleosome", \%args);
my $bg_name = get_arg("bg_name", "NucleosomeBackground", \%args);
my $sub_matrix_prefix = get_arg("sub_matrix_prefix", "Nuc", \%args);

my $kmer_length = get_arg("kmer_length", -1, \%args);
die "ERROR - kmer length not given.\n" if ( $kmer_length == -1 );

my $kmer_stats_outfile = get_arg("kmer_stats_outfile", "", \%args);

my $smoothing_window = get_arg("smoothing_window", -1, \%args);
die "smoothing_window must be positive.\n" if ( $smoothing_window != -1 and $smoothing_window <= 0 );

my $uniform_edge_len = get_arg("uniform_edge_len", 5, \%args);
die "uniform_edge_len must be positive.\n" if ( $uniform_edge_len <= 0 );

#######################
#
# Binding:

my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/learn_nucleosome_model_from_kmer_stats.map");

$exec_str .= &AddStringProperty("SEQUENCES_FILE", $seqs);
$exec_str .= &AddStringProperty("NUCLEOSOMES_LOCATIONS_FILE", $locations);
$exec_str .= &AddStringProperty("NUCLEOSOME_WEIGHT_MATRIX_OUTPUT_FILE", $nuc);
$exec_str .= &AddStringProperty("NUCLEOSOME_WEIGHT_MATRIX_NAME", $nuc_name);
$exec_str .= &AddStringProperty("BACKGROUND_MATRIX_NAME", $bg_name);
$exec_str .= &AddStringProperty("NUCLEOSOME_MODEL_SUB_MATRIX_NAME_PREFIX", $sub_matrix_prefix);
$exec_str .= &AddStringProperty("NUCLEOSOME_MODEL_KMER_LENGTH", $kmer_length);

unless ( $kmer_stats_outfile eq "" ) {
  $exec_str .= &AddStringProperty("NUCLEOSOME_MODEL_KMER_STATS_OUTPUT_FILE", $kmer_stats_outfile);
}

unless ( $smoothing_window > 0 ) {
  $exec_str .= &AddStringProperty("NUCLEOSOME_MODEL_DATA_SMOOTHING_WINDOW_SIZE", $smoothing_window);
}

$exec_str .= &AddStringProperty("NUCLEOSOME_MODEL_UNIFORMLY_DISTRIBUTED_EDGE_LENGTH", $uniform_edge_len);

unless ( $nuc_pos_indep eq "" ) {
  $exec_str .= &AddStringProperty("KMER_POSITION_INDEPENDENT_NUCLEOSOME_WEIGHT_MATRIX_OUTPUT_FILE", $nuc_pos_indep);
}

#######################
#
# Running:

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $log_file, $save_xml_file);

#
#######################


#
# END
#


__DATA__

learn_nucleosome_model_from_kmer_stats.pl

  Yet another approach to learning a nucleosome model. This time, using kmer occurrence stats at different positions within nucleosome reads.

  -seqs <str>:               sequences fasta file
  -locations <str>:          nucleosome locations gxt file. expected to contain 147 long nucleosome reads
  -nuc <str>:                learned nucleosome matrix gxw output file name
  -nuc_pos_indep <str>:      learned nucleosome kmer-position independant matrix gxw output file name. if not given, will not be learned.
  -nuc_name <str>:           name of nucleosome matrix (default: Nucleosome)
  -bg_name <str>:            name of nucleosome background matrix (default: NucleosomeBackground)
  -sub_matrix_prefix <str>:  name prefix for the nucleosome matrix sub-matrices (default: Nuc). the added suffix will be the position number
  -kmer_length <int>:        kmer length to use
  -kmer_stats_outfile <str>: kmer stats output file (if not given, will not be created)
  -smoothing_window <int>:   size of moving average window to be used for smoothing the data (if not given, data will not be smoothed)
  -uniform_edge_len <int>:   MNase biases nucleosome reads edges in favor of 'TA'. to avoid this, the model assigns a uniform distribution
                             over the last (first) few bases (default: 5)
				

  -xml:                      print only the xml file
  -log <str>:                print the stdout and stderr of the program into the file <str>
  -sxml <str>:               save the xml file into <str>

