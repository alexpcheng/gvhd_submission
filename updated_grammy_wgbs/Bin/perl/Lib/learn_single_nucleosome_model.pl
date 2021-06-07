#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA> ;
   exit;
}

#---------------------------------------------------------------------#
# LOAD ARGUMENTS                                                      #
#---------------------------------------------------------------------#

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

#---------------------------------------------------------------------#
# XML parameters                                                      #
#---------------------------------------------------------------------#

my $SEQUENCES_FAS			       		= get_arg("seq_fas", "sequences.fas", \%args);
my $SEQUENCES_LST			       		= get_arg("seq_lst", "sequences.lst", \%args);
my $SEQUENCES_GROUP_NAME		       		= "target_sequences";

my $BACKGROUND_GXW			       		= get_arg("bck_gxw", "background.gxw", \%args);
my $BACKGROUND_GROUP_NAME		       		= "background_matrix";

my $NUCLEOSOME_GXW			       		= get_arg("nuc_gxw", "nucleosome.gxw", \%args);
my $NUCLEOSOME_GROUP_NAME		       	        = "nucleosome_matrix";
my $NUCLEOSOME_NAME			       	        = get_arg("nuc_name", "Nucleosome", \%args);

my $OBSERVATIONS_GXT			       	        = get_arg("obs_gxt", "observations.gxt", \%args);
my $OBSERVATIONS_GROUP_NAME		     		= "observations";

my $SCALING_FACTORS_TAB				        = get_arg("sca_tab", "scaling_factors.tab", \%args);

my $REVERSE_COMPLEMENT					= "false";
my $REALIGN_BY_MAX_POSTERIOR                            = get_arg("realign", 0, \%args);
$REALIGN_BY_MAX_POSTERIOR = ($REALIGN_BY_MAX_POSTERIOR) ? "true" : "false";

my $OBSERVATION_WEIGHTS_TYPE				= get_arg("obs_type", "GaussianModel", \%args);
my $OBSERVATION_WEIGHTS_LENGTH_MAX			= get_arg("obs_lmax", 192, \%args);
my $OBSERVATION_WEIGHTS_LENGTH_MIN			= get_arg("obs_lmin", 102, \%args);
my $OBSERVATION_WEIGHTS_LENGTH_UNCERTAINTY		= get_arg("obs_lunc", 2, \%args);
my $OBSERVATION_SCORE_TYPE				= get_arg("obs_score", "Sum", \%args);

my $OUTPUT_PREDICTIONS_CHV			       	= get_arg("out_pred_chv", "output_predictions.chv", \%args);
my $OUTPUT_SCALING_FACTORS_TAB				= get_arg("out_sca_tab", "output_scaling_factors.tab", \%args);
my $OUTPUT_NUCLEOSOME_GXW				= get_arg("out_nuc_gxw", "output_nucleosome.gxw", \%args);
my $OUTPUT_MARGINAL_DINUCLEOTIDE_DISTRIBUTION_TAB	= get_arg("out_dinuc_tab", "output_marginal_dinucleotide_distributions.tab", \%args);
my $OUTPUT_OBSERVATIONS_CHV				= get_arg("out_obs_chv", "output_observations.chv", \%args);

my $LEARN_MIN_ITERATIONS				= get_arg("learn_iter", 100, \%args);
my $LEARN_MAX_ITERATIONS				= $LEARN_MIN_ITERATIONS;

my $TRAINING_PROCEDURE_TYPE                             = get_arg("opt_type", "ConjugateGradient", \%args);
my $STEP_TYPE						= get_arg("step_type", "SingleWeightMatrix", \%args);


#---------------------------------------------------------------------#
# Perl script parameters                                              #
#---------------------------------------------------------------------#

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $output_file = "tmp_$r.clu";
my $run_file = $output_file;
my $print_xml = get_arg("xml", 0, \%args);
my $xml_file = $tmp_xml;
my $save_xml_file = get_arg("sxml", "", \%args);

#---------------------------------------------------------------------#
# RUN                                                                 #
#---------------------------------------------------------------------#

my $exec_str = &GetXML();

#print STDERR "EXECUTABLE: $exec_str\n";

&RunGenie($exec_str, $print_xml, $xml_file, $output_file, $run_file, $save_xml_file);

#-------------------------------------------------------------------------
# GetXML()
#-------------------------------------------------------------------------
sub GetXML
{
   # creating the bind str
	
   my $learn_single_nucleosome_model_exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/learn_single_nucleosome_model.map");

   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("SEQUENCES_FAS", $SEQUENCES_FAS);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("SEQUENCES_LST", $SEQUENCES_LST);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("SEQUENCES_GROUP_NAME", $SEQUENCES_GROUP_NAME);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("BACKGROUND_GXW", $BACKGROUND_GXW);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("BACKGROUND_GROUP_NAME", $BACKGROUND_GROUP_NAME);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("NUCLEOSOME_GXW", $NUCLEOSOME_GXW);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("NUCLEOSOME_GROUP_NAME", $NUCLEOSOME_GROUP_NAME);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("NUCLEOSOME_NAME", $NUCLEOSOME_NAME);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OBSERVATIONS_GXT", $OBSERVATIONS_GXT);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OBSERVATIONS_GROUP_NAME", $OBSERVATIONS_GROUP_NAME);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("SCALING_FACTORS_TAB", $SCALING_FACTORS_TAB);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("REVERSE_COMPLEMENT", $REVERSE_COMPLEMENT);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("REALIGN_BY_MAX_POSTERIOR", $REALIGN_BY_MAX_POSTERIOR);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OBSERVATION_WEIGHTS_TYPE", $OBSERVATION_WEIGHTS_TYPE);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OBSERVATION_WEIGHTS_LENGTH_MAX", $OBSERVATION_WEIGHTS_LENGTH_MAX);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OBSERVATION_WEIGHTS_LENGTH_MIN", $OBSERVATION_WEIGHTS_LENGTH_MIN);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OBSERVATION_WEIGHTS_LENGTH_UNCERTAINTY", $OBSERVATION_WEIGHTS_LENGTH_UNCERTAINTY);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OBSERVATION_SCORE_TYPE", $OBSERVATION_SCORE_TYPE);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OUTPUT_PREDICTIONS_CHV", $OUTPUT_PREDICTIONS_CHV);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OUTPUT_SCALING_FACTORS_TAB", $OUTPUT_SCALING_FACTORS_TAB);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OUTPUT_NUCLEOSOME_GXW", $OUTPUT_NUCLEOSOME_GXW);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OUTPUT_MARGINAL_DINUCLEOTIDE_DISTRIBUTION_TAB", $OUTPUT_MARGINAL_DINUCLEOTIDE_DISTRIBUTION_TAB);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("OUTPUT_OBSERVATIONS_CHV", $OUTPUT_OBSERVATIONS_CHV);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("LEARN_MIN_ITERATIONS", $LEARN_MIN_ITERATIONS);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("LEARN_MAX_ITERATIONS", $LEARN_MAX_ITERATIONS);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("TRAINING_PROCEDURE_TYPE", $TRAINING_PROCEDURE_TYPE);
   $learn_single_nucleosome_model_exec_str .= &AddStringProperty("STEP_TYPE", $STEP_TYPE);

   return $learn_single_nucleosome_model_exec_str;
}

__DATA__

learn_single_nucleosome_model.pl

   Bla bla bla (ask yair)


   -seq_fas         <file.fas>         Sequences fasta file (default: "sequences.fas")
   -seq_lst         <file.lst>         Sequences group list file (default: "sequences.lst")
   -bck_gxw         <file.gxw>         Backgroud weight matrix (default: "background.gxw")
   -nuc_gxw         <file.gxw>         Initial nucleosome weight matrix for learning (default: "nucleosome.gxw")
   -nuc_name        <str>              The name of the nucleosome weight matrix (default: "Nucleosome")
   -obs_gxt         <file.gxt>         The observations gxt file (default: "observations.gxt")
   -sca_tab         <file.tab>         The initial scaling factors tab file (default: "scaling_factors.tab")
   -obs_type        <TYPE>             The observation prior type. TYPE=<GaussianModel / UniformModel / BinomialModel / UniformWithoutCenteringModel> (default: "GaussianModel")
   -obs_lmax        <int>              The maximal allowed observation length (default: 192)
   -obs_lmin        <int>              The minimal allowed observation length (default: 102)
   -obs_lunc        <double>           The uncertainty in the observation prior model, e.g. for GaussianModel it is the STD (default: 2.0)
   -obs_score       <TYPE>             The observation score type (what is the objective function per observation). TYPE=<Sum / Max> (default: "Sum")
   -realign                            Realign the sequences before each 'global' iteration (default: dont)
   -out_pred_chv    <file.chv>         The output predictions chv file. Does not work yet... (default: "output_predictions.chv")
   -out_sca_tab     <file.tab>         The output (learned) scaling factors tab file (default: "output_scaling_factors.tab")
   -out_nuc_gxw     <file.gxw>         The output (learned) nucleosome weight matirx (default: "output_nucleosome.gxw")
   -out_dinuc_tab   <file.tab>         The output tab (matrix) file of dinucleotide frequency to position (default: "output_marginal_dinucleotide_distributions.tab")
   -out_obs_chv     <file.chv>         The output prior of observations used in chv format (default: "output_observations.chv")
   -learn_iter      <int>              The number of (conjugate gradient) iterations (default: 100)
   -opt_type        <TYPE>             The optimization tool type. TYPE=<ConjugateGradient / Simplex> (default: "ConjugateGradient")
   -xml                                Print (STDOUT) the XML (default: dont)
   -sxml            <file.xml>         Print (into file.xml) the XML (default: dont)
   -step_type       <TYPE>             The step type. TYPE=<SingleWeightMatrix / PrintDinucProfile> (default: "SingleWeightMatrix")

