#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $r = int(rand(100000));
my $tmp_xml = "tmp_xml_".$r.".map";

my $coop_func_type = "ExponentialyDecayingFunction";

#######################
#
# Loading args:

my %args = load_args(\@ARGV);

my $xml = get_arg("xml", 0, \%args);
my $log_file = get_arg("log", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $seqs = get_arg("seqs", "", \%args);
die "ERROR - input FASTA file name not given\n" if ( $seqs eq "" );
die "ERROR - cannot find input FASTA file '$seqs'\n" unless ( -e $seqs );

my $nucleosome_matrix_file = get_arg("nuc", "", \%args);
die "ERROR - input nucleosome model file name not given\n" if ( $nucleosome_matrix_file eq "" );
die "ERROR - cannot find input nucleosome model file '$nucleosome_matrix_file'\n" unless ( -e $nucleosome_matrix_file );

my $nucleosome_matrix_name = get_arg("nuc_name", "Nucleosome", \%args);

my $background_matrix_file = get_arg("bck", "", \%args);
if ( $background_matrix_file ne "" ) {
  die "ERROR - cannot find input background model file '$background_matrix_file'\n" unless ( -e $background_matrix_file );
}

my $background_order = get_arg("b", 0, \%args);
my $use_local_background_matrix = get_arg("local_bck", 0, \%args);

my $coop_params = get_arg("exp_params", "6,2", \%args);
my @coop_params = split(/,/,$coop_params);
my $num_coop_params = @coop_params;
die "ERROR - wrong number of exp_params\n" if ($num_coop_params != 2);

my $temperature = get_arg("temperature", 0.5, \%args);
my $nuc_ctr = get_arg("nuc_ctr", 0.1, \%args);
my $max_coop_dist = get_arg("max_coop_dist", 100, \%args);

my $out_file = get_arg("out_file", "", \%args);
die "ERROR - output file name not given\n" unless ( $out_file ne "" or $xml );

my $precision = get_arg("precision", 3, \%args);

#######################


#######################
#
# create tmp coop file:

my $tmp_coop_file = "tmp_coop_$r.tab";
open(COOP_FILE,">$tmp_coop_file");

print COOP_FILE "regulator1\tregulator2\tfunction\tcoefficient";
for ( my $i=1 ; $i <= $num_coop_params ; $i++ ) {
  print COOP_FILE "\tparameter$i";
}
print COOP_FILE "\n$nucleosome_matrix_name\t$nucleosome_matrix_name\t$coop_func_type\t1";

foreach my $param (@coop_params) {
  print COOP_FILE "\t$param";
}
print COOP_FILE "\n";

close COOP_FILE;

#######################


#######################
#
# create tmp scaling file:

my $tmp_scaling_file = "tmp_scaling_$r.tab";
open(SCALING_FILE,">$tmp_scaling_file");
print SCALING_FILE "Background\t1\n";
print SCALING_FILE "$nucleosome_matrix_name\t$nuc_ctr\n";
close SCALING_FILE;

#######################


#######################
#
# run model:

my $exec_str = "gxw2stats.pl";
$exec_str .= " -m $nucleosome_matrix_file";
$exec_str .= " -n $nucleosome_matrix_name";
$exec_str .= " -s $seqs";
$exec_str .= " -temp $temperature";

if ( $background_matrix_file ne "" ) {
  $exec_str .= " -bck $background_matrix_file";
}
else {
  $exec_str .= " -b $background_order";
  $exec_str .= " -local_bck $use_local_background_matrix" if ( $use_local_background_matrix );
}

$exec_str .= " -sff $tmp_scaling_file";
$exec_str .= " -coop $tmp_coop_file";
$exec_str .= " -mcd $max_coop_dist";
$exec_str .= " -ghmm Cooperative";
$exec_str .= " -precision $precision";
$exec_str .= " -norc";
$exec_str .= " -t WeightMatrixAverageOccupancy";
$exec_str .= " -run $log_file" unless ( $log_file eq "" );
$exec_str .= " -sxml $save_xml_file" unless ( $save_xml_file eq "" );

if ( $xml ) {
  $exec_str .= " -xml > $tmp_xml";
  `$exec_str`;
  system("cat $tmp_xml");
}
else {
  $exec_str .= " > $out_file";
  `$exec_str`;
}

#######################


#######################
#
# remove tmp files:

unlink $tmp_coop_file, $tmp_scaling_file unless ( $xml or $save_xml_file ne "" );
unlink $tmp_xml if ( -e $tmp_xml );
unlink "map.log" if ( -e "map.log" );

#######################


#
# END
#

__DATA__

linker_model_wrapper.pl

  Computes nucleosome average occupancy predictions along input sequences using a model that accounts
  interactions between adjacent nucleosomes. These interactions are represented by an exponentially decaying
  function (Exp) of the linker length, that may introduce a bias in favor of short linker lengths.
  The Exp function has 2 parameters, a and b.
  For linker length x: Exp(x) = exp{ -a * 0.01 * x + b }.


 Parameters:

  -seqs <str>:             A FASTA file with the input DNA sequences (assumes {A,C,G,T} alphabet).
  -nuc <str>:              The nucleosome model weight matrix to use.
  -nuc_name <str>:         Name of nucleosome matrix (default: Nucleosome).

  -bck <str>:              Background matrix to use. If not given, then background matrix will be computed
                           from the input sequences.
  -b <int>:                Background order (default: 0). Relevant if not using -bck.
  -local_bck:              Compute the background locally for each sequence (as opposed to a single global matrix).
                           Relevant if not using -bck.

  -exp_params <a,b>:       A comma seperated list of the two Exp function parameters (doubles). (default: 6,2).
  -temperature <double>:   The model (inverse) temperature parameter. (AKA the thermodynamic beta parameter. default: 0.5).
  -nuc_ctr <double>:       The model nucleosome concentration parameter. (default: 0.1).

                           NOTE: the above default parameters were learned from yeast in-vivo data.

  -max_coop_dist <int>:    Interactions between adjacent nucleosomes will only be modeled (by the Exp function)
                           for linker lengths of up to that length. (default: 100).
                           WARNING: the running time scales linearly with this parameter.

  -out_file <file_name>:   Name of output file.
  -precision <int>:        Output precision (number of digits after the decimal point. default: 3)

  -log <str>:              print the stdout and stderr of the program into the file <str>
  -sxml <str>:             save the xml file into <str>
  -xml:                    print only the xml file

                           NOTE: if -sxml or -xml is used, will not remove the temporary coop and scaling files.

