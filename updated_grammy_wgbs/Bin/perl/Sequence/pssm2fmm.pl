#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $input_background_matrix_file = &get_arg("input_background_matrix_file", "", \%args);
my $input_pssm_matrix_file = &get_arg("input_pssm_matrix_file", "", \%args);
my $fmm_init_from_pssm_file_name = &get_arg("fmm_init_from_pssm_file_name", "", \%args);
my $output_weight_matrix_name = &get_arg("output_weight_matrix_name", "", \%args);

if ($input_background_matrix_file eq "" ||
    $input_pssm_matrix_file eq "" ||
    $fmm_init_from_pssm_file_name eq ""
   )
{
	die "pssm2fmm abort since one of the needed parameters was not provided:\ninput_background_matrix_file:$input_background_matrix_file\ninput_pssm_matrix_file:$input_pssm_matrix_file\nfmm_init_from_pssm_file_name:$fmm_init_from_pssm_file_name\n";
}



my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/pssm2fmm.map");

$exec_str .= &AddStringProperty("BACKGROUND_MATRIX_FILE", $input_background_matrix_file);
$exec_str .= &AddStringProperty("PSSM_MATRIX_FILE", $input_pssm_matrix_file);
$exec_str .= &AddStringProperty("FMM_INIT_FROM_PSSM_FILE_NAME", $fmm_init_from_pssm_file_name);

if ($output_weight_matrix_name ne "")
{
	$exec_str .= &AddStringProperty("OUTPUT_WEIGHT_MATRIX_NAME", $output_weight_matrix_name);
}

$exec_str .= &AddStringProperty("USE_ONLY_POSITIVE_WEIGHTS", &get_arg("use_only_positive_weights", "false", \%args));



#print "DEBUG, exe str: $exec_str\n";

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file);

__DATA__

pssm2fmm.pl

   description:
   -----------
   create fmm gxw that represent the input pssm in fmm format

   -xml:              Print only the xml file
   -run <str>:        Print the stdout and stderr of the program into the file <str>

   -input_background_matrix_file <str> defualt "" (illegal) name of background zero order marokov weight matrix
   -input_pssm_matrix_file <str> defualt "" (illegal) name of input pssm gxw file 
   -fmm_init_from_pssm_file_name <str> defualt "" (illegal) name of output fmm gxw file
   -output_weight_matrix_name <str> defualt "" name of output matrix, if "" then the matrix name will be as the pssm name
   -use_only_positive_weights <true/false> defualt is false

