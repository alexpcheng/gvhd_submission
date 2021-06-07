#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $matrices_file_ref;
my $matrices_file = $ARGV[0];
my $output_file_prefix = $ARGV[1];



my %args = load_args(\@ARGV);
my $binding_site_num = get_arg("n", 1, \%args);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);
my $pid = $$;
my $run_tmp_map_file = "tmp_run_" . $pid . ".map";


my $sample_fmm_map = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/sample_fmm.map");


$sample_fmm_map .= &AddStringProperty("TRUE_MODEL_WEIGHT_MATRICES_FILE", $matrices_file);
$sample_fmm_map .= &AddStringProperty("OUTPUT_FILE_PREFIX", $output_file_prefix);
$sample_fmm_map .= &AddStringProperty("DATA_NAME_PREFIX", "SampleData");
$sample_fmm_map .= &AddStringProperty("POSITIVE_OUTPUT_FILES_PREFIX", $output_file_prefix . ".positive");
$sample_fmm_map .= &AddStringProperty("POSITIVE_DATA_NAME_PREFIX", "PositiveSampleData");
$sample_fmm_map .= &AddStringProperty("ALLSEQS_OUTPUT_FILES_PREFIX", $output_file_prefix . ".all");
$sample_fmm_map .= &AddStringProperty("ALLSEQS_DATA_NAME_PREFIX", "AllSeq");
$sample_fmm_map .= &AddStringProperty("NUM_OF_SAMPLES_FROM_BACKGROUND", -1);
$sample_fmm_map .= &AddStringProperty("NUM_OF_SAMPLES_FROM_TRUE_MODEL", $binding_site_num);
$sample_fmm_map .= &AddStringProperty("BACKGROUND_SEQ_CANT_BE_REAL", "false");



if ($xml == 0)
{
	print STDERR "Sampling FMM ...\n";
}
else
{
	print STDERR "Writing xml:\n";
}
# run
&RunGenie($sample_fmm_map, $xml, $run_tmp_map_file, "", $run_file, $save_xml_file);

if ($xml == 0)
{
	`rm -f $run_tmp_map_file;`;
	print STDERR "Done Sampling FMM\n";
	
	my $tmp_all = $output_file_prefix . ".all.*";
	my $tmp_positive = $output_file_prefix . ".positive.*";
	
	`rm -f $tmp_all;`;
	`rm -f $tmp_positive;`;
	
}



__DATA__

sample_fmm.pl <gxw file> <output_file_prefix>

   Samples binding sites. Binding sites are randomly generated from the given an FMM (the first FMM in the collection).
   Notice the memory performace are exponential in the length of the FMM (8/9bp is still ok)
   
   outputs .labels .fa .alignment files

   -n <num>:   Number of binding sites sampled  (default: 1)
   
3. run flags:
----------
-xml:             print only the xml file
-run <str>:       Print the stdout and stderr of the program into the file <str>
-sxml <str>:      Save the xml file into <str>

