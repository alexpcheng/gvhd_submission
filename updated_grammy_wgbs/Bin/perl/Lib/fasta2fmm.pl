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
my $out_gxw_file  = $ARGV[1];


print STDERR "Making sure all sequences have the same length\n";

my $num_of_lengths =`cat $in_fasta_file | fasta_length.pl | cut.pl -f 2 | sort.pl -c0 0 -n0 | uniq | wc -w`;

chomp($num_of_lengths);
trim($num_of_lengths);
chomp($num_of_lengths);

#print STDERR "DEBUG num_of_lengths: |$num_of_lengths| \n";

if ($num_of_lengths ne "1")
{
	die "Not all sequences in $in_fasta_file are of the same length, or wronge format.\n";
}
else
{
	print STDERR "All sequences have the same length\n";
}

#print STDERR "DEBUG all sequences are of the same length \n";

my $pid = $$;

# tmp file names
my $in_tmp_alignment_file = "tmp_" . $pid . ".alignment";
my $in_tmp_labels_file = "tmp_" . $pid . ".labels";
my $run_tmp_map_file = "tmp_run_" . $pid . ".map";


#print STDERR "DEBUG in_tmp_alignment_file:$in_tmp_alignment_file \n";
#print STDERR "DEBUG in_tmp_labels_file:$in_tmp_labels_file \n";



print STDERR "Getting Input Arguments\n";

# getting the flags
my %args = &load_args(\@ARGV);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);


if ($xml == 0)
{
	print STDERR "Creating Run Files\n";

	# removing tmp files if exist before running
	`rm -f $in_tmp_alignment_file;`;
	`rm -f $in_tmp_labels_file;`;
	`rm -f $run_tmp_map_file;`;
	`rm -f $out_gxw_file;`;

	# creating the alignment file
	`fasta2stab.pl < $in_fasta_file | stab2alignment.pl | sed 's/SequenceAlignment Name="SimpleAlignment"/SequenceAlignment Name="TrainData"/' > $in_tmp_alignment_file;`;
	# creating the labels file
	`fasta2stab.pl < $in_fasta_file | cut -f1 | add_column.pl -s 1 | cap.pl 'Gene,Label' > $in_tmp_labels_file;`;

}



my $learn_fmm_from_aligned_sequences = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/learn_fmm_from_aligned_sequences.map");



# major input/output files
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("TRAIN_DATA_FILE_SEQ", $in_fasta_file);
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("TRAIN_DATA_FILE_ALIGNMENT", $in_tmp_alignment_file);
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("TRAIN_DATA_FILE_LABELS", $in_tmp_labels_file);
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("LEARN_FEATURE_WEIGHT_OUTPUT_FILE", $out_gxw_file);

# more output files

my $estimator_output_file                                        = &get_arg("estimator_output_file","", \%args);
if ($estimator_output_file ne "")
{
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("ESTIMATOR_OUTPUT_FILE", $estimator_output_file);
}

my $statistics_output_file                                        = &get_arg("statistics_output_file","", \%args);
if ($statistics_output_file ne "")
{
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("STATISTICS_OUTPUT_FILE", $statistics_output_file);
}

my $feature_stat_output_file                                      = &get_arg("feature_stat_output_file","", \%args);
if ($feature_stat_output_file ne "")
{
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_STAT_OUTPUT_FILE", $feature_stat_output_file);
}

my $training_iteration_score_out_file_name                        = &get_arg("training_iteration_score_out_file_name","", \%args);
if ($training_iteration_score_out_file_name ne "")
{
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("TRAINING_ITERATION_SCORE_OUT_FILE_NAME", $training_iteration_score_out_file_name);
}

my $features_statistical_tests_filter_out_file_name               = &get_arg("features_statistical_tests_filter_out_file_name","", \%args);
if ($features_statistical_tests_filter_out_file_name ne "")
{
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURES_STATISTICAL_TESTS_FILTER_OUT_FILE_NAME", $features_statistical_tests_filter_out_file_name);
}

my $feature_loopy_inference_iter_log               = &get_arg("feature_loopy_inference_iter_log","", \%args);
if ($feature_loopy_inference_iter_log ne "")
{
	$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_ITER_LOG_TOKEN", $feature_loopy_inference_iter_log);
}


# params

my $weight_matrix_name                                            = &get_arg("weight_matrix_name","LearnedWeightMatrix", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("WEIGHT_MATRIX_NAME", $weight_matrix_name);

my $init_fmm_by_first_learning_pssm                               = &get_arg("init_fmm_by_first_learning_pssm","true", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("INIT_FMM_BY_FIRST_LEARNING_PSSM", $init_fmm_by_first_learning_pssm);

my $reverse_complement                               = &get_arg("reverse_complement","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("REVERSE_COMPLEMENT", $reverse_complement);


# learning procedures

my $use_secondary_training_procedure                               = &get_arg("use_secondary_training_procedure","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("USE_SECONDARY_TRAINING_PROCEDURE", $use_secondary_training_procedure);

my $major_training_procedure_type                                  = &get_arg("major_training_procedure_type","ConjugateGradientUsingOnlyGradient", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MAJOR_TRAINING_PROCEDURE_TYPE", $major_training_procedure_type);
my $major_training_parameter_initial_step_size                     = &get_arg("major_training_parameter_initial_step_size","0.1", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_INITIAL_STEP_SIZE", $major_training_parameter_initial_step_size);
my $major_training_parameter_tolerance                             = &get_arg("major_training_parameter_tolerance","0.005", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_TOLERANCE", $major_training_parameter_tolerance);
my $major_training_parameter_max_train_iterations                  = &get_arg("major_training_parameter_max_train_iterations","1000", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_MAX_TRAIN_ITERATIONS", $major_training_parameter_max_train_iterations);
my $major_training_parameter_notify_iteration_completions          = &get_arg("major_training_parameter_notify_iteration_completions","true", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_NOTIFY_ITERATION_COMPLETIONS", $major_training_parameter_notify_iteration_completions);

my $secondary_training_procedure_type                                  = &get_arg("secondary_training_procedure_type","Simplex", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("SECONDARY_TRAINING_PROCEDURE_TYPE", $secondary_training_procedure_type);
my $secondary_training_parameter_initial_step_size                     = &get_arg("secondary_training_parameter_initial_step_size","0.1", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_INITIAL_STEP_SIZE", $secondary_training_parameter_initial_step_size);
my $secondary_training_parameter_tolerance                             = &get_arg("secondary_training_parameter_tolerance","0.005", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_TOLERANCE", $secondary_training_parameter_tolerance);
my $secondary_training_parameter_max_train_iterations                  = &get_arg("secondary_training_parameter_max_train_iterations","1000", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_MAX_TRAIN_ITERATIONS", $secondary_training_parameter_max_train_iterations);
my $secondary_training_parameter_notify_iteration_completions          = &get_arg("secondary_training_parameter_notify_iteration_completions","true", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_NOTIFY_ITERATION_COMPLETIONS", $secondary_training_parameter_notify_iteration_completions);


#  loopy inference params

my $feature_loopy_inference_calibrated_node_percent_tresh          = &get_arg("feature_loopy_inference_calibrated_node_percent_tresh",1, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $feature_loopy_inference_calibrated_node_percent_tresh);

my $feature_loopy_inference_calibration_tresh          = &get_arg("feature_loopy_inference_calibration_tresh",0.001, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_TRESH_TOKEN", $feature_loopy_inference_calibration_tresh);

my $feature_loopy_inference_max_iterations          = &get_arg("feature_loopy_inference_max_iterations",1000, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_MAX_ITERATIONS_TOKEN", $feature_loopy_inference_max_iterations);

my $feature_loopy_inference_potential_type          = &get_arg("feature_loopy_inference_potential_type","CpdPotential", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_POTENTIAL_TYPE_TOKEN", $feature_loopy_inference_potential_type);

my $feature_loopy_inference_distance_method_type          = &get_arg("feature_loopy_inference_distance_method_type","DmNormLInf", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_DISTANCE_METHOD_TYPE_TOKEN", $feature_loopy_inference_distance_method_type);

my $feature_loopy_inference_use_max_spanning_trees_reduction          = &get_arg("feature_loopy_inference_use_max_spanning_trees_reduction","true", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_MAX_SPANNING_TREES_REDUCTION_TOKEN", $feature_loopy_inference_use_max_spanning_trees_reduction);

my $feature_loopy_inference_use_gbp          = &get_arg("feature_loopy_inference_use_gbp","true", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_GBP_TOKEN", $feature_loopy_inference_use_gbp);

my $feature_loopy_inference_use_only_exact          = &get_arg("feature_loopy_inference_use_only_exact","true", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_ONLY_EXACT", $feature_loopy_inference_use_only_exact);

my $feature_loopy_inference_success_calibrated_node_percent_tresh          = &get_arg("feature_loopy_inference_success_calibrated_node_percent_tresh",0.95, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $feature_loopy_inference_success_calibrated_node_percent_tresh);

my $feature_loopy_inference_success_calibration_tresh          = &get_arg("feature_loopy_inference_success_calibration_tresh",0.02, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATION_TRESH_TOKEN", $feature_loopy_inference_success_calibration_tresh);

my $feature_loopy_inference_calibration_method_type          = &get_arg("feature_loopy_inference_calibration_method_type","SynchronicBP", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_METHOD_TYPE", $feature_loopy_inference_calibration_method_type);

my $feature_loopy_inference_average_messages_in_message_update          = &get_arg("feature_loopy_inference_average_messages_in_message_update","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_AVERAGE_MESSAGES_IN_MESSAGE_UPDATE", $feature_loopy_inference_average_messages_in_message_update);

# function params

my $feature_function_type          = &get_arg("feature_function_type","SeqsLGradientUsingFeatureEstimation", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_FUNCTION_TYPE_TOKEN", $feature_function_type);

my $feature_expectation_estimation_method_type          = &get_arg("feature_expectation_estimation_method_type","CliqueGraph", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_EXPECTATION_ESTIMATION_METHOD_TYPE_TOKEN", $feature_expectation_estimation_method_type);


# structure learning pramas

my $max_features_parameters_num          = &get_arg("max_features_parameters_num",1000, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MAX_FEATURES_PARAMETERS_NUM", $max_features_parameters_num);
my $max_learning_iterations_num          = &get_arg("max_learning_iterations_num",20, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MAX_LEARNING_ITERATIONS_NUM", $max_learning_iterations_num);
my $feature_selection_method_type          = &get_arg("feature_selection_method_type","Grafting", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_SELECTION_METHOD_TYPE_TOKEN", $feature_selection_method_type);


my $remove_features_under_weight_thresh          = &get_arg("remove_features_under_weight_thresh",0.0001, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH", $remove_features_under_weight_thresh);
my $structure_learning_sum_weights_penalty_coefficient          = &get_arg("structure_learning_sum_weights_penalty_coefficient",0.5, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("STRUCTURE_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT", $structure_learning_sum_weights_penalty_coefficient);
my $parameters_learning_sum_weights_penalty_coefficient          = &get_arg("parameters_learning_sum_weights_penalty_coefficient",0.5, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("PARAMETERS_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT", $parameters_learning_sum_weights_penalty_coefficient);
my $feature_selection_score_thresh          = &get_arg("feature_selection_score_thresh",0.5, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FEATURE_SELECTION_SCORE_THRESH", $feature_selection_score_thresh);


my $remove_features_under_weight_thresh_after_each_iter          = &get_arg("remove_features_under_weight_thresh_after_each_iter","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH_AFTER_EACH_ITER", $remove_features_under_weight_thresh_after_each_iter);
my $remove_features_under_weight_thresh_after_full_grafting          = &get_arg("remove_features_under_weight_thresh_after_full_grafting","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH_AFTER_FULL_GRAFTING", $remove_features_under_weight_thresh_after_full_grafting);
my $do_parameters_learning_iteration_after_learning_structure          = &get_arg("do_parameters_learning_iteration_after_learning_structure","true", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("DO_PARAMETERS_LEARNING_ITERATION_AFTER_LEARNING_STRUCTURE", $do_parameters_learning_iteration_after_learning_structure);
my $pseudo_count_equivalent_size          = &get_arg("pseudo_count_equivalent_size",0.4, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("PSEUDO_COUNT_EQUIVALENT_SIZE", $pseudo_count_equivalent_size);



# features filtering params

my $letters_at_position_feature_max_positions_num          = &get_arg("letters_at_position_feature_max_positions_num",2, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("LETTERS_AT_POSITION_FEATURE_MAX_POSITIONS_NUM", $letters_at_position_feature_max_positions_num);
my $initial_filter_count_percent_thresh          = &get_arg("initial_filter_count_percent_thresh",0.06, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("INITIAL_FILTER_COUNT_PERCENT_THRESH", $initial_filter_count_percent_thresh);
my $use_initial_p_value_filter          = &get_arg("use_initial_p_value_filter","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("USE_INITIAL_P_VALUE_FILTER", $use_initial_p_value_filter);

my $initial_filter_p_value_thresh          = &get_arg("initial_filter_p_value_thresh",0.25, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("INITIAL_FILTER_P_VALUE_THRESH", $initial_filter_p_value_thresh);

my $filter_only_positive_features          = &get_arg("filter_only_positive_features","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("FILTER_ONLY_POSITIVE_FEATURES", $filter_only_positive_features);
my $use_only_positive_weights          = &get_arg("use_only_positive_weights","false", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("USE_ONLY_POSITIVE_WEIGHTS", $use_only_positive_weights);
my $letters_at_two_positions_chi2_filter_fdr_thresh          = &get_arg("letters_at_two_positions_chi2_filter_thresh",-1, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("LETTERS_AT_TWO_POSITIONS_CHI2_FILTER_FDR_THRESH", $letters_at_two_positions_chi2_filter_fdr_thresh);
my $letters_at_multiple_positions_binomial_filter_fdr_thresh          = &get_arg("letters_at_multiple_positions_binomial_filter_thresh",0.25, \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("LETTERS_AT_MULTIPLE_POSITIONS_BINOMIAL_FILTER_FDR_THRESH", $letters_at_multiple_positions_binomial_filter_fdr_thresh);
my $multiple_hypothesis_correction          = &get_arg("multiple_hypothesis_correction","None", \%args);
$learn_fmm_from_aligned_sequences .= &AddStringProperty("MULTIPLE_HYPOTHESIS_CORRECTION", $multiple_hypothesis_correction);


if ($xml == 0)
{
	print STDERR "Learning FMM ...\n";
}
else
{
	print STDERR "Writing xml:\n";
}
# run
&RunGenie($learn_fmm_from_aligned_sequences, $xml, $run_tmp_map_file, "", $run_file, $save_xml_file);

if ($xml == 0)
{
	print STDERR "Done Learning FMM\n";
	print STDERR "Removing tmp files\n";
}

	
# removing tmp files if exist before exit
`rm -f $in_tmp_alignment_file;`;
`rm -f $in_tmp_labels_file;`;
`rm -f $run_tmp_map_file;`;

if ($xml == 0)
{
	print STDERR "Done! results in file: $out_gxw_file \n";
}

#########################################################################

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
# Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

#########################################################################

__DATA__

fasta2fmm.pl


Usage: 

Learn FMM from aligned sequences.
The sequence in the fasta file need to be of the same length.

fasta2fmm.pl <in fasta file> <out FMM gxw file>

1. Other output files for debug and run analysis purposes:
-----------------------------------------------------

For all the following: 
The default is not to write the file. 
If a file name is given the file will be produced.

-estimator_output_file <str>
-statistics_output_file <str>
-feature_stat_output_file <str>
-training_iteration_score_out_file_name <str>
-features_statistical_tests_filter_out_file_name <str>
-feature_loopy_inference_iter_log <str>


2. Params:
----------

There are many parameters, so the important parameters are marked with three stars (***) before the minus sign of the flag.  

2.1 structure learning parameters
---------------------------------

-weight_matrix_name <str> (defualt LearnedWeightMatrix) the name of the weight matrix in the output gxw file
(***) -init_fmm_by_first_learning_pssm <true/false> (defualt true) Starts with learning a all single position features. Recommended.
-reverse_complement <true/false> (defualt false) use the reverse complement of the sequences instead
-feature_function_type <SeqsLGradientUsingFeatureEstimation> (default SeqsLGradientUsingFeatureEstimation) type of function used for the optimization for developer use.
-feature_expectation_estimation_method_type <CliqueGraph> (default CliqueGraph) method of feature expectation computation for developer use.

(***) -max_features_parameters_num <positive int> (default 1000)
(***) -max_learning_iterations_num <positive int> (default 20)
-feature_selection_method_type <str> (default: Grafting)
(***) -remove_features_under_weight_thresh <[0,1]> (default 0.0001) removes features with very small weights. 
(***) -structure_learning_sum_weights_penalty_coefficient <positive real> (default 0.5) the weight of the penalty term in the structure learning step
(***) -parameters_learning_sum_weights_penalty_coefficient <positive real> (default 0.5) the weight of the penalty term after the structure learning step, for a single parameter learning iteration
-feature_selection_score_thresh <positive real> (default 0.5) threshold for the minimum feature gradient that the grafting will select
-remove_features_under_weight_thresh_after_each_iter <true/false> (defualt false) removes weights with small values (value under threshold) after each iteration
-remove_features_under_weight_thresh_after_full_grafting <true/false> (defualt false) removes weights with small values (value under threshold) at the end of the learning
-do_parameters_learning_iteration_after_learning_structure <true/false> (defualt true) do single parameter learning iteration after structure learning
(***) -pseudo_count_equivalent_size <non-negative real> (default 0.4) adds uniform distributed pseudo sequences


2.2 learning procedure params
-----------------------------

-use_secondary_training_procedure <false/true> default true

-major_training_procedure_type <ConjugateGradientUsingOnlyGradient/ConjugateGradient/Simplex> default ConjugateGradientUsingOnlyGradient. the method for convex optimization in the major train
-major_training_parameter_initial_step_size <real> default 0.1
-major_training_parameter_tolerance <real> default 0.005
-major_training_parameter_max_train_iterations <int> default 1000
-major_training_parameter_notify_iteration_completions <true/false> default true

-secondary_training_procedure_type <ConjugateGradientUsingOnlyGradient/ConjugateGradient/Simplex> default Simplex. the method for convex optimization in the secondary train
-secondary_training_parameter_initial_step_size <real> default 0.1
-secondary_training_parameter_tolerance <real> default 0.005
-secondary_training_parameter_max_train_iterations <int> default 1000
-secondary_training_parameter_notify_iteration_completions <true/false> default true

2.3 loopy inference params
-----------------------------

-feature_loopy_inference_calibrated_node_percent_tresh <[0,1]> default 1
-feature_loopy_inference_calibration_tresh <[0,1]> default 0.001
-feature_loopy_inference_max_iterations <int> default 1000
-feature_loopy_inference_potential_type <CpdPotential> default CpdPotential
-feature_loopy_inference_distance_method_type <DmNormLInf> default DmNormLInf
-feature_loopy_inference_use_max_spanning_trees_reduction <true/false> default true
-feature_loopy_inference_use_gbp <true/false> default true
-feature_loopy_inference_use_only_exact <true/false> default true
-feature_loopy_inference_success_calibrated_node_percent_tresh <[0,1]> default 0.95
-feature_loopy_inference_success_calibration_tresh <[0,1]> default 0.02
-feature_loopy_inference_calibration_method_type <SynchronicBP/AsynchronyRBP> default SynchronicBP
-feature_loopy_inference_average_messages_in_message_update <true/false> default false

2.4 feature filtering params
-----------------------------

(***) -letters_at_position_feature_max_positions_num <1,2,...> default 2. The maximum domain size of a sequence feature
(***) -initial_filter_count_percent_thresh <-1 / [0,1]> default 0.06. The thresh of the initial percent form sequences filter (-1 for ignoring this filter)
-use_initial_p_value_filter  <true/false> default false. {not relevant for this version}
-initial_filter_p_value_thresh <[0,1]> default 0.25 {not relevant for this version}
-filter_only_positive_features <true/false> default false
(***) -use_only_positive_weights <true/false> default false


(***) -letters_at_two_positions_chi2_filter_thresh <-1 / [0,1]> default -1
(***) -letters_at_multiple_positions_binomial_filter_thresh  <-1 / [0,1]> default 0.25 
(***) -multiple_hypothesis_correction <None/FDR/Bonferroni> default None. this control the two above tests for false positives


3. run flags:
----------
-xml:             print only the xml file
-run <str>:       Print the stdout and stderr of the program into the file <str>
-sxml <str>:      Save the xml file into <str>

-------------------------------------------------------------------------------------

