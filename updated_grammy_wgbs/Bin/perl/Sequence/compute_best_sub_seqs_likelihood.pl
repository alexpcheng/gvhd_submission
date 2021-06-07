#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

# exracting in and out file names
my $in_fasta_file = $ARGV[0];
my $in_gxw_file  = $ARGV[1];
my $out_res_file  = $ARGV[2];



# getting the flags
my %args = &load_args(\@ARGV);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $compute_best_sub_seqs_likelihood = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/run_compute_best_sub_seqs_likelihood.map");


$compute_best_sub_seqs_likelihood .= &AddStringProperty("SEQS_FILE_NAME", $in_fasta_file);
$compute_best_sub_seqs_likelihood .= &AddStringProperty("WM_FILE_NAME", $in_gxw_file);
$compute_best_sub_seqs_likelihood .= &AddStringProperty("SUB_SEQS_BEST_LIKELIHOOD_OUTPUT_FILE", $out_res_file);



my $try_also_reverse_complement             = &get_arg("try_also_reverse_complement","true", \%args);
$compute_best_sub_seqs_likelihood .= &AddStringProperty("TRY_ALSO_REVERSE_COMPLEMENT", $try_also_reverse_complement);

if ($xml == 0)
{
	print STDERR "Scoring sub sequences ...\n";
}
else
{
	print STDERR "Writing xml:\n";
}

my $pid = $$;

# tmp file names
my $run_tmp_map_file = "tmp_run_" . $pid . ".map";


# run
&RunGenie($compute_best_sub_seqs_likelihood, $xml, $run_tmp_map_file, "", $run_file, $save_xml_file);


if ($xml == 0)
{
	print STDERR "Done! results in file: $out_res_file \n";
	`rm -f $run_tmp_map_file;`;
}



__DATA__

compute_best_sub_seqs_likelihood.pl <sub sequences fasta file> <pssm gxw> <output tab file>

$in_fasta_file = $ARGV[0];
my $in_gxw_file  = $ARGV[1];
my $out_res_file  = $ARGV[2];

Usage: 
compute the best likelihood of a subsequence of a pssm, according to the PSSM.

the gxw must be a PSSM, and longer (or equal length) from all sub sequences

output format:
<seq name> \t <weight matrix name> \t <best likelihood> 

2. params flags:
----------
   -try_also_reverse_complement <true/fale> default is true - tries also the reverse complement of the sequence
   
   
2. run flags:
----------
   -xml:             print only the xml file
   -run <str>:       Print the stdout and stderr of the program into the file <str>
   -sxml <str>:      Save the xml file into <str>
-------------------------------------------------------------------------------------

