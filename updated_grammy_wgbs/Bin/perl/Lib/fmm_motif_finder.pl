#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my %args = &load_args(\@ARGV);


my $not_quiet = get_arg("quiet", 1, \%args);
my $xml = get_arg("xml", 0, \%args);
my $log_file = get_arg("log", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $pid = $$;

my $find_motifs = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/run_fmm_motif_finder.map");


# output dir:

my $output_dir = &get_arg("output_dir", ".", \%args);


# map file:
# the temp map file will be created in the output dir, since no write permission problems are expected there...
my $run_tmp_map_file = "$output_dir/tmp_run_" . $pid . ".map";


# input files:

my $positive_seqs_file = &get_arg("p","", \%args);
die "Positive sequences file not given\n" if ( $positive_seqs_file eq "" );
die "Cannot find positive sequences file $positive_seqs_file\n" unless ( -f $positive_seqs_file );
my $tmp_num_rows = &GetNumRows($positive_seqs_file);
die "Positive sequences file is empty\n" if ( $tmp_num_rows == 0 );

$find_motifs .= &AddStringProperty("TRAIN_POSITIVE_SEQS_FILE", $positive_seqs_file);


my $generate_random_negative = get_arg("rand_n", 0, \%args);
my $save_random_negative = get_arg("save_rand_n", 0, \%args);
my $random_seed = get_arg("rand_seed", 0, \%args);
$random_seed = $pid unless ( $random_seed > 0 );

my $negative_seqs_file = &get_arg("n","", \%args);
my $negative_seqs_file_to_use = $negative_seqs_file;
unless ( $generate_random_negative ) {
  die "Negative sequences file not given\n" if ( $negative_seqs_file eq "" );
  die "Cannot find negative sequences file $negative_seqs_file\n" unless ( -f $negative_seqs_file );
  $tmp_num_rows = &GetNumRows($negative_seqs_file);
  die "Negative sequences file is empty\n" if ( $tmp_num_rows == 0 );
}

# if we got here, then if $negative_seqs_file eq "" then also $generate_random_negative == 1
if ( $negative_seqs_file eq "" ) {
  $negative_seqs_file_to_use = "$output_dir/tmp_neg_$pid.fa";
  if ( $xml == 0 ) {
    system ("cat $positive_seqs_file | fasta2stab.pl | stab2permuted_sequences.pl -s $random_seed -i 3 | stab2fasta.pl > $negative_seqs_file_to_use");
  }
}

$find_motifs .= &AddStringProperty("TRAIN_BACKGROUND_SEQS_FILE", $negative_seqs_file_to_use);


my $background_matrix_file = &get_arg("b","", \%args);
unless ( $background_matrix_file eq "" ) {
  die "Cannot find background matrix file $background_matrix_file\n" unless ( -f $background_matrix_file );

  $tmp_num_rows = &GetNumRows($background_matrix_file);
  die "Background matrix file is empty\n" if ( $tmp_num_rows == 0 );

  $find_motifs .= &AddStringProperty("BACKGROUND_MATRIX_FILE", $background_matrix_file);
  $find_motifs .= &AddStringProperty("BACKGROUND_MATRIX", "background_matrix");
}



# other motif finder params:

my $input_includes_masks = &get_arg("input_includes_masks", "true", \%args);
$find_motifs .= &AddStringProperty("LABELED_SEQUENCES_INITIALIZE_MASKS", $input_includes_masks);

my $use_rev_comp = &get_arg("use_rev_comp", "true", \%args);
$find_motifs .= &AddStringProperty("USE_ALSO_REVERSE_COMPLEMENT_OF_UN_ALIGNED_SEQS", $use_rev_comp);

my $min_seed = &get_arg("min_seed", 5, \%args);
$find_motifs .= &AddStringProperty("MOTIF_FINDER_MIN_SEED_LENGTH", $min_seed);

my $max_seed = &get_arg("max_seed", 8, \%args);
$find_motifs .= &AddStringProperty("MOTIF_FINDER_MAX_SEED_LENGTH", $max_seed);

my $num_motifs = &get_arg("num_motifs", 5, \%args);
$find_motifs .= &AddStringProperty("MOTIF_FINDER_MAX_OUTPUT_MOTIFS_NUM", $num_motifs);

my $learn_fmm = &get_arg("learn_fmm", "true", \%args);
die "ERROR - learn_fmm is set to '$learn_fmm'. accpets only 'true' or 'false'.\n" unless ( $learn_fmm eq "true" or $learn_fmm eq "false" );
$find_motifs .= &AddStringProperty("DO_LEARN_FMM", $learn_fmm);

my $learn_pssm = &get_arg("learn_pssm", "false", \%args);
die "ERROR - learn_pssm is set to '$learn_pssm'. accpets only 'true' or 'false'.\n" unless ( $learn_pssm eq "true" or $learn_pssm eq "false" );
$find_motifs .= &AddStringProperty("DO_LEARN_PSSM", $learn_pssm);


die "ERROR - both learn_fmm and learn_pssm options set to false.\n" if ( $learn_fmm eq "false" and $learn_pssm eq "false" );


my $hg_dim = &get_arg("hg_dim", 2, \%args);
$find_motifs .= &AddStringProperty("HYPER_GEOMETRIC_MULTIPLICITY_THRESHOLD", $hg_dim);

my $max_edge_hamm_dist = &get_arg("max_edge_hamm_dist", 1, \%args);
$find_motifs .= &AddStringProperty("MAX_HAMMING_DIST_FOR_KMER_GRAPH_EDGE", $max_edge_hamm_dist);

my $seed_significance = &get_arg("seed_significance", 0.001, \%args);
$find_motifs .= &AddStringProperty("SEED_SIGNIFICANCE", $seed_significance);

my $seed_significance_correction = &get_arg("seed_significance_correction", "None", \%args);
$find_motifs .= &AddStringProperty("SEED_SIGNIFICANCE_MULTIPLE_HYPOTHESIS_CORRECTION", $seed_significance_correction);

my $max_significant_seeds = &get_arg("max_significant_seeds", 200, \%args);
$find_motifs .= &AddStringProperty("MAX_SIGNIFICANT_SEEDS_TO_USE", $max_significant_seeds);

my $force_tfbs_on_all_positive = &get_arg("force_tfbs_on_all_positive", "false", \%args);
$find_motifs .= &AddStringProperty("USE_BEST_HITS_FROM_ALL_POSITIVE_SEQS", $force_tfbs_on_all_positive);

my $tfbs_files_prefix = &get_arg("tfbs_files_prefix", "Out_motif_seqs", \%args);
$find_motifs .= &AddStringProperty("MOTIF_FINDER_OUTPUT_SEQS_FILES_PREFIX", "$output_dir/$tfbs_files_prefix");

my $fmm_output_files_prefix = &get_arg("fmm_output_files_prefix", "Out_FMM", \%args);
$find_motifs .= &AddStringProperty("FEATURE_WEIGHT_MATRIX_OUTPUT_FILE_PREFIX", "$output_dir/$fmm_output_files_prefix");

my $pssm_output_files_prefix = &get_arg("pssm_output_files_prefix", "Out_PSSM", \%args);
$find_motifs .= &AddStringProperty("PSSM_WEIGHT_MATRIX_OUTPUT_FILE_PREFIX", "$output_dir/$pssm_output_files_prefix");

my $output_debug_files = &get_arg("output_debug_files", "false", \%args);
$find_motifs .= &AddStringProperty("OUTPUT_DEBUG_FILES", $output_debug_files);

my $output_kmer_set_motif_model_files = &get_arg("output_kmer_set_motif_model_files", "true", \%args);
$find_motifs .= &AddStringProperty("PRINT_KMER_SET_MODEL_FILES", $output_kmer_set_motif_model_files);

my $gen_likelihood_files = &get_arg("gen_likelihood_files", "false", \%args);
my $output_kmer_set_stats_files = &get_arg("output_kmer_set_stats_files", "true", \%args);
my $do_keep_kmer_set_stats_files = $output_kmer_set_stats_files;
if ( $gen_likelihood_files eq "true" ) {
  $output_kmer_set_stats_files = "true";
}
$find_motifs .= &AddStringProperty("PRINT_KMER_SET_STATS_FILES", $output_kmer_set_stats_files);

my $kmer_set_motif_model_file_prefix = &get_arg("kmer_set_motif_model_file_prefix", "kmer_set_", \%args);
$find_motifs .= &AddStringProperty("KMER_SET_MODEL_FILE_PREFIX", "$output_dir/$kmer_set_motif_model_file_prefix");

my $kmer_set_stats_file_prefix = &get_arg("kmer_set_stats_file_prefix", "kmm_stats_", \%args);
$find_motifs .= &AddStringProperty("KMER_SET_STATS_FILE_PREFIX", "$output_dir/$kmer_set_stats_file_prefix");


my $kmer_set_motif_models_pvalues_file = &get_arg("kmer_set_motif_models_pvalues_file", "", \%args);
unless ( $kmer_set_motif_models_pvalues_file eq "" ) {
  $find_motifs .= &AddStringProperty("KMER_SETS_PVALUES_FILE", "$output_dir/$kmer_set_motif_models_pvalues_file");
}



# The following are expert-only
my $max_kmer_to_pssm_align_gap = &get_arg("max_kmer_to_pssm_align_gap", 5, \%args);
$find_motifs .= &AddStringProperty("MAX_KMER_TO_PSSM_ALIGNMENT_GAP", $max_kmer_to_pssm_align_gap);
#my $force_align_kmer_at_each_hit = &get_arg("force_align_kmer_at_each_hit", "false", \%args);
#$find_motifs .= &AddStringProperty("FORCE_ALIGN_KMER_AT_EACH_HIT", $force_align_kmer_at_each_hit);
#my $align_kmer_by_edge_offset = &get_arg("align_kmer_by_edge_offset", "false", \%args);
#$find_motifs .= &AddStringProperty("ALIGN_BY_EDGE_OFFSET", $align_kmer_by_edge_offset);



# hits scoring params:

my $output_motif_hits_files = &get_arg("output_motif_hits_files", "false", \%args);
$find_motifs .= &AddStringProperty("OUTPUT_MOTIF_HITS_FILES", $output_motif_hits_files);

my $find_all_high_scoring_motif_hits = &get_arg("find_all_high_scoring_motif_hits", "false", \%args);
$find_motifs .= &AddStringProperty("FIND_OTHER_HIGH_SCORING_MOTIF_HITS", $find_all_high_scoring_motif_hits);

my $hits_scoring_thresh_type = &get_arg("hits_scoring_thresh_type", "MinMotifHit", \%args);
$find_motifs .= &AddStringProperty("HIT_SCORE_THRESH_TYPE", $hits_scoring_thresh_type);

my $hit_name_prefix = &get_arg("hit_name_prefix", "Id", \%args);
$find_motifs .= &AddStringProperty("HIT_NAME_PREFIX", $hit_name_prefix);

my $hit_score_scaling_factor = &get_arg("hit_score_scaling_factor", 1, \%args);
$find_motifs .= &AddStringProperty("HIT_SCORE_SCALING_FACTOR", $hit_score_scaling_factor);

my $fmm_motif_hits_file_prefix =  &get_arg("fmm_motif_hits_file_prefix", "fmm_motif_hits", \%args);
$find_motifs .= &AddStringProperty("FEATURE_HITS_SCORES_OUTPUT_FILE_NAME_PREFIX", "$output_dir/$fmm_motif_hits_file_prefix");

my $fmm_other_motif_hits_file_prefix =  &get_arg("fmm_other_motif_hits_file_prefix", "fmm_motif_hits_extended", \%args);
$find_motifs .= &AddStringProperty("FEATURE_OTHER_HIGH_SCORING_MOTIF_HITS_OUTPUT_FILE_NAME_PREFIX", "$output_dir/$fmm_other_motif_hits_file_prefix");

my $pssm_motif_hits_file_prefix =  &get_arg("pssm_motif_hits_file_prefix", "pssm_motif_hits", \%args);
$find_motifs .= &AddStringProperty("PSSM_HITS_SCORES_OUTPUT_FILE_NAME_PREFIX", "$output_dir/$pssm_motif_hits_file_prefix");

my $pssm_other_motif_hits_file_prefix =  &get_arg("pssm_other_motif_hits_file_prefix", "pssm_motif_hits_extended", \%args);
$find_motifs .= &AddStringProperty("PSSM_OTHER_HIGH_SCORING_MOTIF_HITS_OUTPUT_FILE_NAME_PREFIX", "$output_dir/$pssm_other_motif_hits_file_prefix");


# fmm learning procedures params:

my $use_secondary_training_procedure                               = &get_arg("use_secondary_training_procedure","false", \%args);
$find_motifs .= &AddStringProperty("USE_SECONDARY_TRAINING_PROCEDURE", $use_secondary_training_procedure);

my $major_training_procedure_type                                  = &get_arg("major_training_procedure_type","ConjugateGradientUsingOnlyGradient", \%args);
$find_motifs .= &AddStringProperty("MAJOR_TRAINING_PROCEDURE_TYPE", $major_training_procedure_type);
my $major_training_parameter_initial_step_size                     = &get_arg("major_training_parameter_initial_step_size","0.1", \%args);
$find_motifs .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_INITIAL_STEP_SIZE", $major_training_parameter_initial_step_size);
my $major_training_parameter_tolerance                             = &get_arg("major_training_parameter_tolerance","0.005", \%args);
$find_motifs .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_TOLERANCE", $major_training_parameter_tolerance);
my $major_training_parameter_max_train_iterations                  = &get_arg("major_training_parameter_max_train_iterations","1000", \%args);
$find_motifs .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_MAX_TRAIN_ITERATIONS", $major_training_parameter_max_train_iterations);
my $major_training_parameter_notify_iteration_completions          = &get_arg("major_training_parameter_notify_iteration_completions","true", \%args);
$find_motifs .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_NOTIFY_ITERATION_COMPLETIONS", $major_training_parameter_notify_iteration_completions);

my $secondary_training_procedure_type                                  = &get_arg("secondary_training_procedure_type","Simplex", \%args);
$find_motifs .= &AddStringProperty("SECONDARY_TRAINING_PROCEDURE_TYPE", $secondary_training_procedure_type);
my $secondary_training_parameter_initial_step_size                     = &get_arg("secondary_training_parameter_initial_step_size","0.1", \%args);
$find_motifs .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_INITIAL_STEP_SIZE", $secondary_training_parameter_initial_step_size);
my $secondary_training_parameter_tolerance                             = &get_arg("secondary_training_parameter_tolerance","0.005", \%args);
$find_motifs .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_TOLERANCE", $secondary_training_parameter_tolerance);
my $secondary_training_parameter_max_train_iterations                  = &get_arg("secondary_training_parameter_max_train_iterations","1000", \%args);
$find_motifs .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_MAX_TRAIN_ITERATIONS", $secondary_training_parameter_max_train_iterations);
my $secondary_training_parameter_notify_iteration_completions          = &get_arg("secondary_training_parameter_notify_iteration_completions","true", \%args);
$find_motifs .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_NOTIFY_ITERATION_COMPLETIONS", $secondary_training_parameter_notify_iteration_completions);


# fmm loopy inference params:

my $feature_loopy_inference_calibrated_node_percent_tresh          = &get_arg("feature_loopy_inference_calibrated_node_percent_tresh",1, \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $feature_loopy_inference_calibrated_node_percent_tresh);

my $feature_loopy_inference_calibration_tresh          = &get_arg("feature_loopy_inference_calibration_tresh",0.001, \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_TRESH_TOKEN", $feature_loopy_inference_calibration_tresh);

my $feature_loopy_inference_max_iterations          = &get_arg("feature_loopy_inference_max_iterations",1000, \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_MAX_ITERATIONS_TOKEN", $feature_loopy_inference_max_iterations);

my $feature_loopy_inference_potential_type          = &get_arg("feature_loopy_inference_potential_type","CpdPotential", \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_POTENTIAL_TYPE_TOKEN", $feature_loopy_inference_potential_type);

my $feature_loopy_inference_distance_method_type          = &get_arg("feature_loopy_inference_distance_method_type","DmNormLInf", \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_DISTANCE_METHOD_TYPE_TOKEN", $feature_loopy_inference_distance_method_type);

my $feature_loopy_inference_use_max_spanning_trees_reduction          = &get_arg("feature_loopy_inference_use_max_spanning_trees_reduction","true", \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_MAX_SPANNING_TREES_REDUCTION_TOKEN", $feature_loopy_inference_use_max_spanning_trees_reduction);

my $feature_loopy_inference_use_gbp          = &get_arg("feature_loopy_inference_use_gbp","true", \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_GBP_TOKEN", $feature_loopy_inference_use_gbp);

my $feature_loopy_inference_use_only_exact          = &get_arg("feature_loopy_inference_use_only_exact","true", \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_ONLY_EXACT", $feature_loopy_inference_use_only_exact);

my $feature_loopy_inference_success_calibrated_node_percent_tresh          = &get_arg("feature_loopy_inference_success_calibrated_node_percent_tresh",0.95, \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $feature_loopy_inference_success_calibrated_node_percent_tresh);

my $feature_loopy_inference_success_calibration_tresh          = &get_arg("feature_loopy_inference_success_calibration_tresh",0.02, \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATION_TRESH_TOKEN", $feature_loopy_inference_success_calibration_tresh);

my $feature_loopy_inference_calibration_method_type          = &get_arg("feature_loopy_inference_calibration_method_type","SynchronicBP", \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_METHOD_TYPE", $feature_loopy_inference_calibration_method_type);

my $feature_loopy_inference_average_messages_in_message_update          = &get_arg("feature_loopy_inference_average_messages_in_message_update","false", \%args);
$find_motifs .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_AVERAGE_MESSAGES_IN_MESSAGE_UPDATE", $feature_loopy_inference_average_messages_in_message_update);


# fmm structure learning params:

my $init_fmm_by_first_learning_pssm = &get_arg("init_fmm_by_first_learning_pssm", "true", \%args);
$find_motifs .= &AddStringProperty("INIT_FMM_BY_FIRST_LEARNING_PSSM", $init_fmm_by_first_learning_pssm);

my $max_features_parameters_num          = &get_arg("max_features_parameters_num",1000, \%args);
$find_motifs .= &AddStringProperty("MAX_FEATURES_PARAMETERS_NUM", $max_features_parameters_num);
my $max_learning_iterations_num          = &get_arg("max_learning_iterations_num",20, \%args);
$find_motifs .= &AddStringProperty("MAX_LEARNING_ITERATIONS_NUM", $max_learning_iterations_num);
my $feature_selection_method_type          = &get_arg("feature_selection_method_type","Grafting", \%args);
$find_motifs .= &AddStringProperty("FEATURE_SELECTION_METHOD_TYPE_TOKEN", $feature_selection_method_type);


my $remove_features_under_weight_thresh          = &get_arg("remove_features_under_weight_thresh",0.0001, \%args);
$find_motifs .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH", $remove_features_under_weight_thresh);
my $structure_learning_sum_weights_penalty_coefficient          = &get_arg("structure_learning_sum_weights_penalty_coefficient",0.5, \%args);
$find_motifs .= &AddStringProperty("STRUCTURE_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT", $structure_learning_sum_weights_penalty_coefficient);
my $parameters_learning_sum_weights_penalty_coefficient          = &get_arg("parameters_learning_sum_weights_penalty_coefficient",0.5, \%args);
$find_motifs .= &AddStringProperty("PARAMETERS_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT", $parameters_learning_sum_weights_penalty_coefficient);
my $feature_selection_score_thresh          = &get_arg("feature_selection_score_thresh",0.5, \%args);
$find_motifs .= &AddStringProperty("FEATURE_SELECTION_SCORE_THRESH", $feature_selection_score_thresh);


my $remove_features_under_weight_thresh_after_each_iter          = &get_arg("remove_features_under_weight_thresh_after_each_iter","false", \%args);
$find_motifs .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH_AFTER_EACH_ITER", $remove_features_under_weight_thresh_after_each_iter);
my $remove_features_under_weight_thresh_after_full_grafting          = &get_arg("remove_features_under_weight_thresh_after_full_grafting","false", \%args);
$find_motifs .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH_AFTER_FULL_GRAFTING", $remove_features_under_weight_thresh_after_full_grafting);
my $do_parameters_learning_iteration_after_learning_structure          = &get_arg("do_parameters_learning_iteration_after_learning_structure","true", \%args);
$find_motifs .= &AddStringProperty("DO_PARAMETERS_LEARNING_ITERATION_AFTER_LEARNING_STRUCTURE", $do_parameters_learning_iteration_after_learning_structure);
my $pseudo_count_equivalent_size          = &get_arg("pseudo_count_equivalent_size", 1, \%args);
$find_motifs .= &AddStringProperty("PSEUDO_COUNT_EQUIVALENT_SIZE", $pseudo_count_equivalent_size);



# fmm features filtering params:

my $letters_at_position_feature_max_positions_num          = &get_arg("letters_at_position_feature_max_positions_num",2, \%args);
$find_motifs .= &AddStringProperty("LETTERS_AT_POSITION_FEATURE_MAX_POSITIONS_NUM", $letters_at_position_feature_max_positions_num);
my $initial_filter_count_percent_thresh          = &get_arg("initial_filter_count_percent_thresh", 0.15, \%args);
$find_motifs .= &AddStringProperty("INITIAL_FILTER_COUNT_PERCENT_THRESH", $initial_filter_count_percent_thresh);
my $use_initial_p_value_filter          = &get_arg("use_initial_p_value_filter","false", \%args);
$find_motifs .= &AddStringProperty("USE_INITIAL_P_VALUE_FILTER", $use_initial_p_value_filter);

my $initial_filter_p_value_thresh          = &get_arg("initial_filter_p_value_thresh",0.25, \%args);
$find_motifs .= &AddStringProperty("INITIAL_FILTER_P_VALUE_THRESH", $initial_filter_p_value_thresh);

my $filter_only_positive_features          = &get_arg("filter_only_positive_features","false", \%args);
$find_motifs .= &AddStringProperty("FILTER_ONLY_POSITIVE_FEATURES", $filter_only_positive_features);
my $use_only_positive_weights          = &get_arg("use_only_positive_weights","false", \%args);
$find_motifs .= &AddStringProperty("USE_ONLY_POSITIVE_WEIGHTS", $use_only_positive_weights);
my $letters_at_two_positions_chi2_filter_fdr_thresh          = &get_arg("letters_at_two_positions_chi2_filter_thresh",-1, \%args);
$find_motifs .= &AddStringProperty("LETTERS_AT_TWO_POSITIONS_CHI2_FILTER_FDR_THRESH", $letters_at_two_positions_chi2_filter_fdr_thresh);
my $letters_at_multiple_positions_binomial_filter_fdr_thresh          = &get_arg("letters_at_multiple_positions_binomial_filter_thresh", 0.2, \%args);
$find_motifs .= &AddStringProperty("LETTERS_AT_MULTIPLE_POSITIONS_BINOMIAL_FILTER_FDR_THRESH", $letters_at_multiple_positions_binomial_filter_fdr_thresh);
my $multiple_hypothesis_correction          = &get_arg("multiple_hypothesis_correction","None", \%args);
$find_motifs .= &AddStringProperty("MULTIPLE_HYPOTHESIS_CORRECTION", $multiple_hypothesis_correction);


if ( $not_quiet == 1 ) {
  if ($xml == 0) {
    print STDERR "Finding Motifs...\n";
  }
  else {
    print STDERR "Writing xml:\n";
  }
}

# run
&RunGenie($find_motifs, $xml, $run_tmp_map_file, "", $log_file, $save_xml_file);


if ( $xml == 1 ) {
  exit 0;
}
elsif ( $negative_seqs_file_to_use ne $negative_seqs_file and $save_random_negative == 0 ) {
  system("rm $negative_seqs_file_to_use");
}


# output gxw files lists:
my @fmm_gxws = ();
if ( $learn_fmm eq "true" ) {
  @fmm_gxws = `ls -1 $output_dir | grep $fmm_output_files_prefix | grep ".gxw"`;
  chomp @fmm_gxws;
}

my @pssm_gxws = ();
if ( $learn_pssm eq "true" ) {
  @pssm_gxws = `ls -1 $output_dir | grep $pssm_output_files_prefix | grep ".gxw"`;
  chomp @pssm_gxws;
}

my $num_fmms = @fmm_gxws;
my $num_pssms = @pssm_gxws;
if ( $not_quiet == 1 ) {
  print STDERR "num_fmms == $num_fmms, num_pssms == $num_pssms\n";
}

if ( $learn_fmm eq "true" and $learn_pssm eq "true" and $num_fmms != $num_pssms ) {
  die "ERROR - number of FMM and PSSM motifs not equal\n";
}


# create likelihood files:
if ( $gen_likelihood_files eq "true" ) {
  my $norc = "";
  $norc = "-norc" if ( $use_rev_comp eq "false" );

  my @fmm_pos_score_files = ();
  my @pssm_pos_score_files = ();
  my @fmm_neg_score_files = ();
  my @pssm_neg_score_files = ();

  if ( $learn_fmm eq "true" ) {
    foreach my $fmm_gxw (@fmm_gxws) {
      $fmm_gxw =~ /(.*)\.gxw/;
      my $basename = $1;
      my $pos_scores_file = "$output_dir/$basename\_pos_scores.chr";
      my $neg_scores_file = "$output_dir/$basename\_neg_scores.chr";

      if ( $not_quiet == 1 ) {
	print STDERR "fmm_motif_finder.pl: $fmm_gxw - creating positive seq's scores file $pos_scores_file\n";
      }
      open(F, ">$pos_scores_file");
      print F `gxw2stats.pl -m $output_dir/$fmm_gxw -s $positive_seqs_file -bck $background_matrix_file -best $norc`;
      close F;
      push(@fmm_pos_score_files, $pos_scores_file);

      if ( $not_quiet == 1 ) {
	print STDERR "fmm_motif_finder.pl: $fmm_gxw - creating negative seq's scores file $neg_scores_file\n";
      }
      open(F, ">$neg_scores_file");
      print F `gxw2stats.pl -m $output_dir/$fmm_gxw -s $negative_seqs_file -bck $background_matrix_file -best $norc`;
      close F;
      push(@fmm_neg_score_files, $neg_scores_file);
    }
  }
  if ( $learn_pssm eq "true" ) {
    foreach my $pssm_gxw (@pssm_gxws) {
      $pssm_gxw =~ /(.*)\.gxw/;
      my $basename = $1;
      my $pos_scores_file = "$output_dir/$basename\_pos_scores.chr";
      my $neg_scores_file = "$output_dir/$basename\_neg_scores.chr";

      if ( $not_quiet == 1 ) {
	print STDERR "fmm_motif_finder.pl: $pssm_gxw - creating positive seq's scores file $pos_scores_file\n";
      }
      open(F, ">$pos_scores_file");
      print F `gxw2stats.pl -m $output_dir/$pssm_gxw -s $positive_seqs_file -bck $background_matrix_file -best $norc`;
      close F;
      push(@pssm_pos_score_files, $pos_scores_file);

      if ( $not_quiet == 1 ) {
	print STDERR "fmm_motif_finder.pl: $pssm_gxw - creating negative seq's scores file $neg_scores_file\n";
      }
      open(F, ">$neg_scores_file");
      print F `gxw2stats.pl -m $output_dir/$pssm_gxw -s $negative_seqs_file -bck $background_matrix_file -best $norc`;
      close F;
      push(@pssm_neg_score_files, $neg_scores_file);
    }
  }

  open(F, ">$output_dir/all_motifs_stats.txt");

  print F "Motif_Index\tLog_MHG_Pval\tPos_Seqs\tPos_Hits\tNeg_Seqs\tNeg_Hits\tFMM_Pos_Neg_Log_Mean_Likelihood_Ratio\tPSSM_Pos_Neg_Log_Mean_Likelihood_Ratio";
  if ( $learn_fmm eq "true" and $learn_pssm eq "true" ) {
    print F "\tMean_FMM_PSSM_Likelihood_Ratio\tStd_FMM_PSSM_Likelihood_Ratio\n";
  }
  else {
    print F "\n";
  }

  my $pipe1 = "| cut.pl -f 5 | modify_column.pl -e | compute_column_stats.pl -skip 0 -skipc 0 -m | cut.pl -f 2 | modify_column.pl -log2";
  my $pipe2_m = "| add_column.pl -u 4,10 | cut.pl -f 13 |  modify_column.pl -e | compute_column_stats.pl -skip 0 -skipc 0 -m | cut.pl -f 2";
  my $pipe3_std = "| add_column.pl -u 4,10 | cut.pl -f 13 |  modify_column.pl -e | compute_column_stats.pl -skip 0 -skipc 0 -std | cut.pl -f 2";

  for ( my $i=0 ; $i < $num_fmms ; $i++ ) {
    my $kmm_stats = `cat $output_dir/$kmer_set_stats_file_prefix$i.txt | tail -n1`;
    chomp $kmm_stats;
    print F "$i\t$kmm_stats\t";

    my $fmm_log_mean_pos_likelihood = `cat $fmm_pos_score_files[$i] $pipe1`;
    my $fmm_log_mean_neg_likelihood = `cat $fmm_neg_score_files[$i] $pipe1`;
    my $pssm_log_mean_pos_likelihood = `cat $pssm_pos_score_files[$i] $pipe1`;
    my $pssm_log_mean_neg_likelihood = `cat $pssm_neg_score_files[$i] $pipe1`;
    chomp $fmm_log_mean_pos_likelihood;
    chomp $fmm_log_mean_neg_likelihood;
    chomp $pssm_log_mean_pos_likelihood;
    chomp $pssm_log_mean_neg_likelihood;
    my $fmm_pos_neg_log_mean_likelihood_ratio = $fmm_log_mean_pos_likelihood - $fmm_log_mean_neg_likelihood;
    my $pssm_pos_neg_log_mean_likelihood_ratio = $pssm_log_mean_pos_likelihood - $pssm_log_mean_neg_likelihood;

    print F "$fmm_pos_neg_log_mean_likelihood_ratio\t$pssm_pos_neg_log_mean_likelihood_ratio";

    if ( $learn_fmm eq "true" and $learn_pssm eq "true" ) {
      my $mean_fmm_pssm_likelihood_ratio = `cat $fmm_pos_score_files[$i] | add_column.pl -f $pssm_pos_score_files[$i] $pipe2_m`;
      chomp $mean_fmm_pssm_likelihood_ratio;
      print F "\t$mean_fmm_pssm_likelihood_ratio\t";
      print F `cat $fmm_pos_score_files[$i] | add_column.pl -f $pssm_pos_score_files[$i] $pipe3_std`;
    }
    else {
      print F "\n";
    }
  }

  close F;
}

if ( $do_keep_kmer_set_stats_files eq "false" ) {
  system("rm $output_dir/$kmer_set_stats_file_prefix*");
}


# create motif logos:
my $gen_motif_logos = &get_arg("gen_motif_logos", "true", \%args);
if ( $gen_motif_logos eq "true" ) {

  if ( $learn_fmm eq "true" ) {

    my $add_all_single_nt_features = &get_arg("add_all_single_nt_features","true", \%args);
    my $draw_only_features_over_more_than_one_position = &get_arg("draw_only_features_over_more_than_one_position","false", \%args);

    my $wm_logo_image_height = &get_arg("wm_logo_image_height","1200", \%args);
    my $wm_logo_image_width = &get_arg("wm_logo_image_width","0", \%args);
    my $wm_logo_image_char_width = &get_arg("wm_logo_image_char_width", "120", \%args);
    my $wm_logo_image_char_horizontal_spacing = &get_arg("wm_logo_image_char_horizontal_spacing", "20", \%args);
    my $wm_logo_pixle_draw_thresh = &get_arg("wm_logo_pixle_draw_thresh", "0", \%args);

    my $fmm_logo_ops = "-draw_single_position_features_at_the_top true -wm_feature_connect_draw_mode BoxAroundFeature";
    $fmm_logo_ops .= " -add_all_single_nt_features $add_all_single_nt_features";
    $fmm_logo_ops .= " -draw_only_features_over_more_than_one_position $draw_only_features_over_more_than_one_position";
    $fmm_logo_ops .= " -wm_logo_image_height $wm_logo_image_height";
    $fmm_logo_ops .= " -wm_logo_image_width $wm_logo_image_width";
    $fmm_logo_ops .= " -wm_logo_image_char_width $wm_logo_image_char_width";
    $fmm_logo_ops .= " -wm_logo_image_char_horizontal_spacing $wm_logo_image_char_horizontal_spacing";
    $fmm_logo_ops .= " -wm_logo_pixle_draw_thresh $wm_logo_pixle_draw_thresh";

    my $draw_only_k_strongest_features = &get_arg("draw_only_k_strongest_features","", \%args);
    unless ( $draw_only_k_strongest_features eq "" ) {
      $fmm_logo_ops .= " -draw_only_k_strongest_features $draw_only_k_strongest_features";
    }

    foreach my $fmm_gxw (@fmm_gxws) {
      $fmm_gxw =~ /(.*)\.gxw/;
      my $basename = $1;

      if ( $not_quiet == 1 ) {
	print STDERR "fmm_motif_finder.pl: $fmm_gxw - creating logo $basename.jpg\n";
      }
      system("gxw2fmm_logo.pl $output_dir/$fmm_gxw -o $output_dir/$basename.jpg $fmm_logo_ops");
    }
    system("rm FEATURE_GXW_2_LOGO.map WM_0_fmm_logo_weight_matrix.gxw tmp_fmm_features_logo_tab.txt");
  }
  if ( $learn_pssm eq "true" ) {
    foreach my $pssm_gxw (@pssm_gxws) {
      $pssm_gxw =~ /(.*)\.gxw/;
      my $basename = $1;

      if ( $not_quiet == 1 ) {
	print STDERR "fmm_motif_finder.pl: $pssm_gxw - creating logo $basename.png\n";
      }
      system("gxw2logo.pl $output_dir/$pssm_gxw");
      system("mv PSSM.png $output_dir/$basename.png");
    }
  }
}

# save / remove motifs' TFBS files
my $output_tfbs_files = &get_arg("output_tfbs_files", "true", \%args);
if ( $output_tfbs_files eq "false" ) {
  system("rm $output_dir/$tfbs_files_prefix*");
}

# end
if ( $not_quiet == 1 ) {
  print STDERR "fmm_motif_finder.pl: DONE.\n";
}


########## The End #################

__DATA__

fmm_motif_finder.pl


Usage:

fmm_motif_finder.pl -p <positive seqs fasta file> [other options]

Learn FMM/PSSM motifs from unaligned sequences.
Receives two fasta files: positive sequences (bound by a TF) and negative sequences (unbound).
Supported alphabet: {A,C,G,T}. if the '-input_includes_masks' option is set to 'true' then 'N' is
allowed to appear, and is regarded as a masked letter.

1. Motif Finder Params:
-----------------------

-p <fasta file>   positive sequences file. obligatory.
-n <fasta file>   negative sequences file. obligatory, unless the -rand_n option is set.
-rand_n           if no negative file is given, setting this option will generate a negative set from the positive set by randomly permuting each sequence.
-save_rand_n      in case -rand_n used, will save the generated negative set file in the output directory.
-rand_seed <int>  (default: seed is random) if a strictly positive seed is given, then it will be used for randomization (when -rand_n is used).

-b <gxw file>   background matrix file  (if not given, will be learned from the positive sequences)

-input_includes_masks <true/false> (default: true) input is allowed to contain masked letters - 'N'. if data does not include masks, set to 'false' to improve performence.

-learn_fmm <true/false> (default: true)
-learn_pssm <true/false> (default: false)

-use_rev_comp <true/false> (default: true) consider also reverse complement strands of input sequences

-min_seed <int> (default: 5) minimal k-mer length
-max_seed <int> (default: 8) maximal k-mer length
-num_motifs <int> (default: 5) maximum number of motifs to output

-seed_significance <real> (default: 0.001) seed significance p-value threshold
-seed_significance_correction <None/FDR/Bonferroni> (default: None)
-max_significant_seeds <int> (default: 200) num of top seeds to use from those that passed the significance test
-force_tfbs_on_all_positive <true/false> (default: false) find at least one TFBS hit in each positive sequence to add to the TFBSs from which a motif is learned.

-tfbs_files_prefix <str> (default: Out_motif_seqs)
-fmm_output_files_prefix <str> (default: Out_FMM)
-pssm_output_files_prefix <str> (default: Out_PSSM)
-output_dir <str> (default: `pwd`) directory where motif files will be located

-output_debug_files <true/false> (default: false)
-output_tfbs_files <true/false> (default: true) for each motif, keep the files (fasta, alignment, labels) generated by the motif finder, from which the motif model was learned.

-output_kmer_set_motif_model_files <true/false> (default: true) for each motif, output the kmer set motif model, based on which the tfbs files were generated
-output_kmer_set_stats_files <true/false> (default: true) stats are: MHG p-value, Num sequence hits in positive, Num sequence hits in negative
-kmer_set_motif_model_file_prefix <str> (default: kmer_set_)
-kmer_set_stats_file_prefix <str> (default: kmm_stats_)

-kmer_set_motif_models_pvalues_file <str>  will be generated only if file name is given

-gen_motif_logos <true/false> (default: true) generate the motif logos from the output .gxw files

-gen_likelihood_files <true/false> (default: false)

!!! Expert Only Options: !!!
-hg_dim <int> (default: 2) hyper-geometric dimensionality to use for enrichment testing
-max_edge_hamm_dist <int> (default: 1) maximum Hamming distance between k-mers that will be neighbors in initial k-mer graph
-max_kmer_to_pssm_align_gap <int> (default: 5) determines the range of possible alignment offsets when adding a new k-mer to a growing k-mer set



2. FMM Params:
--------------

2.1 structure learning parameters
---------------------------------

-init_fmm_by_first_learning_pssm <true/false> (defualt: true) Starts with learning all single position features. Recommended.

-max_features_parameters_num <positive int> (default: 1000)
-max_learning_iterations_num <positive int> (default: 20)
-remove_features_under_weight_thresh <[0,1]> (default: 0.0001) removes features with very small weights.
-remove_features_under_weight_thresh_after_each_iter <true/false> (defualt: false) removes weights with small values (value under threshold) after each iteration
-remove_features_under_weight_thresh_after_full_grafting <true/false> (defualt: false) removes weights with small values (value under threshold) at the end of the learning
-structure_learning_sum_weights_penalty_coefficient <positive real> (default: 0.5) the weight of the penalty term in the structure learning step
-parameters_learning_sum_weights_penalty_coefficient <positive real> (default: 0.5) the weight of the penalty term after the structure learning step, for a single parameter learning iteration
-feature_selection_score_thresh <positive real> (default: 0.5) threshold for the minimum feature gradient that the grafting will select
-do_parameters_learning_iteration_after_learning_structure <true/false> (defualt: true) do single parameter learning iteration after structure learning
-pseudo_count_equivalent_size <non-negative real> (default: 1) adds uniform distributed pseudo sequences


2.2 learning procedure params
-----------------------------

-use_secondary_training_procedure <false/true> (default: false)

-major_training_procedure_type <ConjugateGradientUsingOnlyGradient/ConjugateGradient/Simplex> (default: ConjugateGradientUsingOnlyGradient) the method for convex optimization in the major train
-major_training_parameter_initial_step_size <real> (default: 0.1)
-major_training_parameter_tolerance <real> (default: 0.005)
-major_training_parameter_max_train_iterations <int> (default: 1000)
-major_training_parameter_notify_iteration_completions <true/false> (default: true)

-secondary_training_procedure_type <ConjugateGradientUsingOnlyGradient/ConjugateGradient/Simplex> (default: Simplex) the method for convex optimization in the secondary train
-secondary_training_parameter_initial_step_size <real> (default: 0.1)
-secondary_training_parameter_tolerance <real> (default: 0.005)
-secondary_training_parameter_max_train_iterations <int> (default: 1000)
-secondary_training_parameter_notify_iteration_completions <true/false> (default: true)


2.3 loopy inference params
--------------------------

-feature_loopy_inference_calibrated_node_percent_tresh <[0,1]> (default: 1)
-feature_loopy_inference_calibration_tresh <[0,1]> (default: 0.001)
-feature_loopy_inference_max_iterations <int> (default: 1000)
-feature_loopy_inference_potential_type <CpdPotential> (default: CpdPotential)
-feature_loopy_inference_distance_method_type <DmNormLInf> (default: DmNormLInf)
-feature_loopy_inference_use_max_spanning_trees_reduction <true/false> (default: true)
-feature_loopy_inference_use_gbp <true/false> (default: true)
-feature_loopy_inference_use_only_exact <true/false> (default: true)
-feature_loopy_inference_success_calibrated_node_percent_tresh <[0,1]> (default: 0.95)
-feature_loopy_inference_success_calibration_tresh <[0,1]> (default: 0.02)
-feature_loopy_inference_calibration_method_type <SynchronicBP/AsynchronyRBP> (default: SynchronicBP)
-feature_loopy_inference_average_messages_in_message_update <true/false> (default: false)


2.4 feature filtering params
----------------------------

-letters_at_position_feature_max_positions_num <1,2,...> (default: 2). The maximum domain size of a sequence feature
-initial_filter_count_percent_thresh <-1 / [0,1]> (default: 0.15). The thresh of the initial percent form sequences filter (-1 for ignoring this filter)
-use_initial_p_value_filter  <true/false> (default: false). {not relevant for this version}
-initial_filter_p_value_thresh <[0,1]> (default: 0.25) {not relevant for this version}
-filter_only_positive_features <true/false> (default: false)
-use_only_positive_weights <true/false> (default: false)

-letters_at_two_positions_chi2_filter_thresh <-1 / [0,1]> (default: -1)
-letters_at_multiple_positions_binomial_filter_thresh  <-1 / [0,1]> (default: 0.2)
-multiple_hypothesis_correction <None/FDR/Bonferroni> (default: None). this control the two above tests for false positives



3. FMM Logo Params:
-------------------
-add_all_single_nt_features <true/false> (default: true)
-draw_only_k_strongest_features <int> (default: -1) (-1 means ignore)

-wm_logo_image_height <int> (defualt: 1200)
-wm_logo_image_width <int> (defualt: 0)
-wm_logo_image_char_width <int> (defualt: 120)
-wm_logo_image_char_horizontal_spacing <int> (defualt: 20)
-draw_only_features_over_more_than_one_position <true/false> (default: false)
-wm_logo_pixle_draw_thresh <int> (defualt: 0)



4. Motif Hits Scoring Params:
-----------------------------
-output_motif_hits_files <true/false> (default: false) output motif hits in the positive sequences (.chr file per motif)
-find_all_high_scoring_motif_hits <true/false> (default: false)
-hits_scoring_thresh_type <MinMotifHit/AverageMotifHit> (default: MinMotifHit)
-hit_name_prefix <str> (default: Id)
-hit_score_scaling_factor <positive real> (deafult: 1) the value of the maximal score. all hits scores will be normailzed accordingly

-fmm_motif_hits_file_prefix <str> (default: fmm_motif_hits)
-fmm_other_motif_hits_file_prefix <str> (default: fmm_motif_hits_extended)
-pssm_motif_hits_file_prefix <str> (default: pssm_motif_hits)
-pssm_other_motif_hits_file_prefix <str> (default: pssm_motif_hits_extended)



5. Run flags:
-------------
-quiet:           do not print messages to stderr
-xml:             print only the xml file
-log <str>:       Print the stdout and stderr of the program into the file <str>
-sxml <str>:      Save the xml file into <str>

-------------------------------------------------------------------------------------
