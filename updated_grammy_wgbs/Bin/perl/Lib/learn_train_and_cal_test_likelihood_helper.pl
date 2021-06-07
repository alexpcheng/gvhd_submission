#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/System/q_util.pl";
require "$ENV{PERL_HOME}/Lib/run_feature_weight_helper.pl";

#file consts
my $space = "___SPACE___";


my $MODEL_TEST_MAP_SUFFIX                 = "_MODEL_TEST_MAP_SUFFIX";
my $RUN_DIRS_SUFFIX                       = "_SYNTHETIC_FEATURES_DIR_NUM_";
my $RUN_FILE_SUFFIX                       = "_RUN_";

#file suffixs
my $MODEL_FILE_TYPE_SUFFIX                = ".gxw";
my $MATLAB_FILE_TYPE_SUFFIX               = ".m_m";
my $ESTIMATOR_FILE_TYPE_SUFFIX            = ".estimator";
my $FEATURE_STAT_FILE_TYPE_SUFFIX         = ".feature_stat";
my $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX       = ".mat_likelihood";
my $MAT_COMPARE_FILE_TYPE_SUFFIX          = ".mat_compare";
my $MAP_FILE_TYPE_SUFFIX                  = ".map";

#model files
my $UPDATED_Z_TRUE_MODEL_FILE_NAME_PREFIX               = "updated_z_true_model";
my $LEARN_FEATURE_WEIGHT_OUTPUT_FILE                    = "Out_WeightMatrixLearnedFromData";
my $UPDATED_Z_LEARN_FEATURE_WEIGHT_OUTPUT_FILE          = "Out_learned_feature_weight_model_updated_Z";
my $UN_LEARNED_MYPSSM_FILE_NAME                         = "Out_CreatePssmLikeFeatureWeightMatrix_mypssm";
my $MYPSSM_MODEL_FILE_NAME                              = "Out_WeightMatrixMyPSSMLearnedFromSyntheticData";
my $UPDATED_Z_LEARN_MYPSSM_OUTPUT_FILE                  = "Out_learned_mypssm_model_updated_Z";
my $PSSM_MODEL_FILE_NAME                                = "Out_PSSMLearnedFromData";
my $MYPSSM_INIT_FROM_PSSM_FILE_NAME                     = "Out_MYPSSMInitFromLearnedPSSM";

#feature stat file
my $LEARN_FEATURE_WEIGHT_FEATURE_STAT_OUTPUT_FILE       = "Out_WeightMatrixLearnedFromSyntheticData_FeatureStat";

#matlab files
my $LEARN_FEATURE_WEIGHT_MATLAB_OUTPUT_FILE_NAME        = "matlab_learned_feature_weight";
my $LEARN_MYPSSM_MATLAB_OUTPUT_FILE_NAME                = "matlab_learned_mypssm";

#estimator 
my $LEARN_FEATURE_WEIGHT_ESTIMATOR_OUTPUT_FILE          = "Out_WeightMatrixLearnedFromData_Estimator";
my $LEARN_MYPSSM_ESTIMATOR_OUTPUT_FILE                  = "Out_WeightMatrixMyPSSMLearnedFromData_Estimator";
my $LEARN_PSSM_ESTIMATOR_OUTPUT_FILE                    = "Out_PSSMLearnedFromData_Estimator";

#likelihood files
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_TRUE_MODEL             = "ComputeSequencesLikelihood_Train_true_model";
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_FEATURE_WEIGHT = "ComputeSequencesLikelihood_Train_learned_feature_weight";
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_MYPSSM         = "ComputeSequencesLikelihood_Train_learned_mypssm";
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_PSSM           = "ComputeSequencesLikelihood_Train_learned_pssm";
my $LIKELIHOOD_OUTPUT_FILE_TEST_TRUE_MODEL              = "ComputeSequencesLikelihood_Test_true_model";
my $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_FEATURE_WEIGHT  = "ComputeSequencesLikelihood_Test_learned_feature_weight";
my $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_MYPSSM          = "ComputeSequencesLikelihood_Test_learned_mypssm";
my $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_PSSM            = "ComputeSequencesLikelihood_Test_learned_pssm";

my $LIKELIHOOD_OUTPUT_FILE_TRAIN_PREFIX             = "ComputeSequencesLikelihood_Train_";
my $LIKELIHOOD_OUTPUT_FILE_TEST_PREFIX              = "ComputeSequencesLikelihood_Test_";
my $MODEL_OUT_FILES_SUFFIX_TRUE_MODEL               = "true_model";
my $MODEL_OUT_FILES_SUFFIX_LEARNED_FEATURE_WEIGHT   = "learned_feature_weight";
my $MODEL_OUT_FILES_SUFFIX_LEARNED_MYPSSM           = "learned_mypssm";
my $MODEL_OUT_FILES_SUFFIX_LEARNED_PSSM             = "learned_pssm";
#KL files
my $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_FEATURE_WEIGHT = "Out_CompareWeightMatrices_true_model_2_learned_feature_weight";
my $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_MYPSSM         = "Out_CompareWeightMatrices_true_model_2_learned_mypssm";
my $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_PSSM           = "Out_CompareWeightMatrices_true_model_2_learned_pssm";

#map files prefix
my $CREATE_SYNTHETIC_TEST_DATA_MAP_FILE_NAME_PREFIX     = "SYNTHETIC_CREATE_TEST_DATA_";
my $CREATE_DATA_AND_MODEL_MAP_FILE_NAME                 = "SYNTHETIC_CREATE_DATA_AND_MODEL";
my $LEARN_AND_COMPARE_MAP_FILE_NAME                     = "SYNTHETIC_LEARN_AND_COMPARE";
my $LEARN_TRAIN_AND_CAL_TEST_LIKELIHOOD                 = "LEARN_TRAIN_AND_CAL_TEST_LIKELIHOOD";
my $CAL_IND_MAP                                         = "CAL_SEQS_FEATURE_INDICATIONS";

#train 
my $ALL_DATA_NAME_PREFIX                       = "TrainDataAll";
my $ALL_OUTPUT_FILE_PREFIX_PREFIX              = "train_data_all";
my $TRAIN_DATA_NAME_PREFIX                     = "TrainData";
my $TRAIN_OUTPUT_FILE_PREFIX_PREFIX            = "train_data";
my $TRAIN_POSITIVE_DATA_NAME_PREFIX            = "TrainDataPositive";
my $TRAIN_POSITIVE_OUTPUT_FILE_PREFIX_PREFIX   = "train_data_positive";
my $TEST_DATA_NAME_PREFIX                      = "TestData";
my $TEST_OUTPUT_FILE_PREFIX_PREFIX             = "test_data";
my $TEST_POSITIVE_DATA_NAME_PREFIX             = "TestDataPositive";
my $TEST_POSITIVE_OUTPUT_FILE_PREFIX_PREFIX    = "test_data_positive";

#iterations
my $FEATURE_TRAINING_ITERATION_SCORE_OUT_FILE_NAME      = "Out_WeightFeature_TrainingIterationLog.iterations";

# consts
my $ALIGNMENT_NAME_TRAIN_POSITIVE = $TRAIN_POSITIVE_DATA_NAME_PREFIX;
my $ALIGNMENT_NAME_TEST_POSITIVE  = $TEST_POSITIVE_DATA_NAME_PREFIX;
my $ALIGNMENT_NAME_TRAIN_ALL      = $TRAIN_DATA_NAME_PREFIX;
my $ALIGNMENT_NAME_TEST_ALL       = $TEST_DATA_NAME_PREFIX;

# -------------------------------------------------------------------------

my $CV_DIR_PREFIX = "CV_";

# -------------------------------------------------------------------------

my $max_user_processes = 100;
my $min_free_processes = 2;

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub LearnTrainAndCalTestLikelihoodIntoFile
{
	my ($positive_infile_name_prefix,
		$background_file_name_prefix, $cv_groups_num,$out_file_path,
		$processes_num,$num_of_sec_between_q_monitoring,$is_delete_tmp_file,$queue_max_length,
		$background_matrix_file,$letters_at_position_feature_max_positions_num,
		$sum_weights_penalty_coefficient,$weight_matrix_positions_num,
		$num_of_sequences_in_the_world,$positive_seqs_prior_probability,
		$estimate_measure_type,
		$use_initial_p_value_filter,$filter_only_positive_features,$remove_features_under_weight_thresh,
		$use_only_positive_weights,$learn_my_pssm,$cal_weights_functions_samples,
		$reweight_positive_instances_fraction,$initial_filter_count_percent_thresh,$write_iteration_file,
		$major_training_parameter_max_train_iterations,$secondary_training_parameter_max_train_iterations,
		$use_secondary_training_procedure,$run_only_on_single_cv_num,$run_mode_int,
		$run_without_creating_CV_dirs,$use_pssm_importance_sampling, $major_training_procedure_type,
		$func_type,$selection_method,$expectation_estimation_method,
		$expectation_by_seq_rewieght,$expectation_by_seq_onlyZero,$expectation_by_seq_Importance,
		$loopy_span_tree_reduction,$loopy_use_gbp,$loopy_max_iterations,
		$loopy_calibration_tresh,$loopy_calibration_node_percent,$loopy_potential_type,
		$loopy_distance_method,$loopy_calibration_tresh_success,$loopy_calibration_node_percent_success,
		$loopy_use_only_exact,$loopy_calibration_method,$loopy_average_messages_in_message_update,
		$init_fmm_from_pssm,
		$limit_the_num_of_parameters_ratio_to_pssm, $max_learning_iterations_num,
		$structure_learning_sum_weights_penalty_coefficient,$parameters_learning_sum_weights_penalty_coefficient,
		$feature_selection_score_thresh,$remove_features_under_weight_thresh_after_each_iter,
		$remove_features_under_weight_thresh_after_full_grafting,$do_parameters_learning_iteration_after_learning_structure,
		$pssm_pseudo_counts, $pseudo_count_equivalent_size,
		$letters_at_two_positions_chi2_filter_fdr_thresh,$letters_at_multiple_positions_binomial_filter_fdr_thresh,$multiple_hypothesis_correction,
		$compute_partition_function_method,$realign_sequences,$max_realign_iterations_num,$compute_positive_sequences_likelihood_method_type,
		$forced_num_positions_without_pedding_of_aligning_pssm
		) = @_;
		

	my @tofile_array_of_col_arrays_ptrs;
	my $col_header_vec_ptr;
	my $cv_group_vec_ptr;
	
	my $tofile_train_positive_likelihood_all_feature_weight_ptr;
	my $tofile_train_positive_likelihood_seqs_num_feature_weight_ptr;
	my $tofile_train_positive_likelihood_average_feature_weight_ptr;
	 
	my $tofile_train_positive_likelihood_all_mypssm_ptr;
	my $tofile_train_positive_likelihood_seqs_num_mypssm_ptr;
	my $tofile_train_positive_likelihood_average_mypssm_ptr;
	
	my $tofile_train_positive_likelihood_all_pssm_ptr;
	my $tofile_train_positive_likelihood_seqs_num_pssm_ptr;
	my $tofile_train_positive_likelihood_average_pssm_ptr;
	
	my $tofile_test_positive_likelihood_all_feature_weight_ptr;
	my $tofile_test_positive_likelihood_seqs_num_feature_weight_ptr;
	my $tofile_test_positive_likelihood_average_feature_weight_ptr;
	
	my $tofile_test_positive_likelihood_all_mypssm_ptr;
	my $tofile_test_positive_likelihood_seqs_num_mypssm_ptr;
	my $tofile_test_positive_likelihood_average_mypssm_ptr;

	my $tofile_test_positive_likelihood_all_pssm_ptr;
	my $tofile_test_positive_likelihood_seqs_num_pssm_ptr;
	my $tofile_test_positive_likelihood_average_pssm_ptr;
		
	if ($learn_my_pssm == 1)
	{
		($col_header_vec_ptr,$cv_group_vec_ptr,
		$tofile_train_positive_likelihood_all_feature_weight_ptr,$tofile_train_positive_likelihood_seqs_num_feature_weight_ptr,$tofile_train_positive_likelihood_average_feature_weight_ptr, 
		$tofile_train_positive_likelihood_all_mypssm_ptr,$tofile_train_positive_likelihood_seqs_num_mypssm_ptr,$tofile_train_positive_likelihood_average_mypssm_ptr,
		$tofile_train_positive_likelihood_all_pssm_ptr,$tofile_train_positive_likelihood_seqs_num_pssm_ptr,$tofile_train_positive_likelihood_average_pssm_ptr,
		$tofile_test_positive_likelihood_all_feature_weight_ptr,$tofile_test_positive_likelihood_seqs_num_feature_weight_ptr,$tofile_test_positive_likelihood_average_feature_weight_ptr,
		$tofile_test_positive_likelihood_all_mypssm_ptr,$tofile_test_positive_likelihood_seqs_num_mypssm_ptr,$tofile_test_positive_likelihood_average_mypssm_ptr,
		$tofile_test_positive_likelihood_all_pssm_ptr,$tofile_test_positive_likelihood_seqs_num_pssm_ptr,$tofile_test_positive_likelihood_average_pssm_ptr) 
		= &LearnTrainAndCalTestLikelihood($positive_infile_name_prefix,
										  $background_file_name_prefix, $cv_groups_num,
										  $processes_num,$num_of_sec_between_q_monitoring,$is_delete_tmp_file,$queue_max_length,
										  $background_matrix_file,$letters_at_position_feature_max_positions_num,
										  $sum_weights_penalty_coefficient,$weight_matrix_positions_num,
										  $num_of_sequences_in_the_world,$positive_seqs_prior_probability,
										  $ALIGNMENT_NAME_TRAIN_POSITIVE,$ALIGNMENT_NAME_TEST_POSITIVE,
										  $ALIGNMENT_NAME_TRAIN_ALL,$ALIGNMENT_NAME_TEST_ALL,
										  $estimate_measure_type,
										  $use_initial_p_value_filter,$filter_only_positive_features,$remove_features_under_weight_thresh,
										  $use_only_positive_weights,$learn_my_pssm,$cal_weights_functions_samples,
										  $reweight_positive_instances_fraction,$initial_filter_count_percent_thresh,$write_iteration_file,
										  $major_training_parameter_max_train_iterations,$secondary_training_parameter_max_train_iterations,
										  $use_secondary_training_procedure,$run_only_on_single_cv_num,$run_mode_int,
										  $run_without_creating_CV_dirs,$use_pssm_importance_sampling, $major_training_procedure_type,
										$func_type,$selection_method,$expectation_estimation_method,
										$expectation_by_seq_rewieght,$expectation_by_seq_onlyZero,$expectation_by_seq_Importance,
										$loopy_span_tree_reduction,$loopy_use_gbp,$loopy_max_iterations,
										$loopy_calibration_tresh,$loopy_calibration_node_percent,$loopy_potential_type,
										$loopy_distance_method,$loopy_calibration_tresh_success,$loopy_calibration_node_percent_success,
										$loopy_use_only_exact,$loopy_calibration_method,$loopy_average_messages_in_message_update,
										$init_fmm_from_pssm,
										$limit_the_num_of_parameters_ratio_to_pssm, $max_learning_iterations_num,
										$structure_learning_sum_weights_penalty_coefficient,$parameters_learning_sum_weights_penalty_coefficient,
										$feature_selection_score_thresh,$remove_features_under_weight_thresh_after_each_iter,
										$remove_features_under_weight_thresh_after_full_grafting,$do_parameters_learning_iteration_after_learning_structure,
										$pssm_pseudo_counts, $pseudo_count_equivalent_size,
										$letters_at_two_positions_chi2_filter_fdr_thresh,$letters_at_multiple_positions_binomial_filter_fdr_thresh,$multiple_hypothesis_correction,
										$compute_partition_function_method,$realign_sequences,$max_realign_iterations_num,$compute_positive_sequences_likelihood_method_type,
										$forced_num_positions_without_pedding_of_aligning_pssm);

		if ($run_mode_int == 1)
		{
			return;
		}
										  
		push(@tofile_array_of_col_arrays_ptrs, $cv_group_vec_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_all_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_seqs_num_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_average_feature_weight_ptr);

		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_all_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_seqs_num_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_average_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_all_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_seqs_num_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_average_feature_weight_ptr);

		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_all_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_seqs_num_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_average_pssm_ptr);
		
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_all_mypssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_seqs_num_mypssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_average_mypssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_all_mypssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_seqs_num_mypssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_average_mypssm_ptr);
	}
	else
	{
		($col_header_vec_ptr,$cv_group_vec_ptr,
		$tofile_train_positive_likelihood_all_feature_weight_ptr,$tofile_train_positive_likelihood_seqs_num_feature_weight_ptr,$tofile_train_positive_likelihood_average_feature_weight_ptr, 
		#$tofile_train_positive_likelihood_all_mypssm_ptr,$tofile_train_positive_likelihood_seqs_num_mypssm_ptr,$tofile_train_positive_likelihood_average_mypssm_ptr,
		$tofile_train_positive_likelihood_all_pssm_ptr,$tofile_train_positive_likelihood_seqs_num_pssm_ptr,$tofile_train_positive_likelihood_average_pssm_ptr,
		$tofile_test_positive_likelihood_all_feature_weight_ptr,$tofile_test_positive_likelihood_seqs_num_feature_weight_ptr,$tofile_test_positive_likelihood_average_feature_weight_ptr,
		#$tofile_test_positive_likelihood_all_mypssm_ptr,$tofile_test_positive_likelihood_seqs_num_mypssm_ptr,$tofile_test_positive_likelihood_average_mypssm_ptr,
		$tofile_test_positive_likelihood_all_pssm_ptr,$tofile_test_positive_likelihood_seqs_num_pssm_ptr,$tofile_test_positive_likelihood_average_pssm_ptr) 
		= &LearnTrainAndCalTestLikelihood($positive_infile_name_prefix,
										  $background_file_name_prefix, $cv_groups_num,
										  $processes_num,$num_of_sec_between_q_monitoring,$is_delete_tmp_file,$queue_max_length,
										  $background_matrix_file,$letters_at_position_feature_max_positions_num,
										  $sum_weights_penalty_coefficient,$weight_matrix_positions_num,
										  $num_of_sequences_in_the_world,$positive_seqs_prior_probability,
										  $ALIGNMENT_NAME_TRAIN_POSITIVE,$ALIGNMENT_NAME_TEST_POSITIVE,
										  $ALIGNMENT_NAME_TRAIN_ALL,$ALIGNMENT_NAME_TEST_ALL,
										  $estimate_measure_type,
										  $use_initial_p_value_filter,$filter_only_positive_features,$remove_features_under_weight_thresh,
										  $use_only_positive_weights,$learn_my_pssm,$cal_weights_functions_samples,
										  $reweight_positive_instances_fraction,$initial_filter_count_percent_thresh,$write_iteration_file,
										  $major_training_parameter_max_train_iterations,$secondary_training_parameter_max_train_iterations,
										  $use_secondary_training_procedure,$run_only_on_single_cv_num,$run_mode_int,
										  $run_without_creating_CV_dirs,$use_pssm_importance_sampling, $major_training_procedure_type,
										  $func_type,$selection_method,$expectation_estimation_method,
										  $expectation_by_seq_rewieght,$expectation_by_seq_onlyZero,$expectation_by_seq_Importance,
										  $loopy_span_tree_reduction,$loopy_use_gbp,$loopy_max_iterations,
										  $loopy_calibration_tresh,$loopy_calibration_node_percent,$loopy_potential_type,
										  $loopy_distance_method,$loopy_calibration_tresh_success,$loopy_calibration_node_percent_success,
										$loopy_use_only_exact,$loopy_calibration_method,$loopy_average_messages_in_message_update,
										$init_fmm_from_pssm,
										$limit_the_num_of_parameters_ratio_to_pssm, $max_learning_iterations_num,
										$structure_learning_sum_weights_penalty_coefficient,$parameters_learning_sum_weights_penalty_coefficient,
										$feature_selection_score_thresh,$remove_features_under_weight_thresh_after_each_iter,
										$remove_features_under_weight_thresh_after_full_grafting,$do_parameters_learning_iteration_after_learning_structure,
										$pssm_pseudo_counts, $pseudo_count_equivalent_size,
										$letters_at_two_positions_chi2_filter_fdr_thresh,$letters_at_multiple_positions_binomial_filter_fdr_thresh,$multiple_hypothesis_correction,
										$compute_partition_function_method,$realign_sequences,$max_realign_iterations_num,$compute_positive_sequences_likelihood_method_type,
										$forced_num_positions_without_pedding_of_aligning_pssm);
										  
		if ($run_mode_int == 1)
		{
			return;
		}
		push(@tofile_array_of_col_arrays_ptrs, $cv_group_vec_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_all_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_seqs_num_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_average_feature_weight_ptr);

		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_all_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_seqs_num_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_train_positive_likelihood_average_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_all_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_seqs_num_feature_weight_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_average_feature_weight_ptr);

		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_all_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_seqs_num_pssm_ptr);
		push(@tofile_array_of_col_arrays_ptrs, $tofile_test_positive_likelihood_average_pssm_ptr);
	}
	
	&WriteTabularFileOfColumnArrays(\@tofile_array_of_col_arrays_ptrs,$col_header_vec_ptr,$out_file_path);
	# my @tofile_train_positive_likelihood_all_feature_weight = @$tofile_train_positive_likelihood_all_feature_weight_ptr;
	# my @tofile_train_positive_likelihood_seqs_num_feature_weight = @$tofile_train_positive_likelihood_seqs_num_feature_weight_ptr;
	# my @tofile_train_positive_likelihood_average_feature_weight = @$tofile_train_positive_likelihood_average_feature_weight_ptr;
	
	# my @tofile_train_positive_likelihood_all_mypssm = @$tofile_train_positive_likelihood_all_mypssm_ptr;
	# my @tofile_train_positive_likelihood_seqs_num_mypssm = @$tofile_train_positive_likelihood_seqs_num_mypssm_ptr;
	# my @tofile_train_positive_likelihood_average_mypssm = @$tofile_train_positive_likelihood_average_mypssm_ptr;
	
	# my @tofile_train_positive_likelihood_all_pssm = @$tofile_train_positive_likelihood_all_pssm_ptr;
	# my @tofile_train_positive_likelihood_seqs_num_pssm = @$tofile_train_positive_likelihood_seqs_num_pssm_ptr;
	# my @tofile_train_positive_likelihood_average_pssm = @$tofile_train_positive_likelihood_average_pssm_ptr;
	
	# my @tofile_test_positive_likelihood_all_feature_weight = @$tofile_test_positive_likelihood_all_feature_weight_ptr;
	# my @tofile_test_positive_likelihood_seqs_num_feature_weight = @$tofile_test_positive_likelihood_seqs_num_feature_weight_ptr;
	# my @tofile_test_positive_likelihood_average_feature_weight = @$tofile_test_positive_likelihood_average_feature_weight_ptr;
	
	# my @tofile_test_positive_likelihood_all_mypssm = @$tofile_test_positive_likelihood_all_mypssm_ptr;
	# my @tofile_test_positive_likelihood_seqs_num_mypssm = @$tofile_test_positive_likelihood_seqs_num_mypssm_ptr;
	# my @tofile_test_positive_likelihood_average_mypssm = @$tofile_test_positive_likelihood_average_mypssm_ptr;
	
	# my @tofile_test_positive_likelihood_all_pssm = @$tofile_test_positive_likelihood_all_pssm_ptr;
	# my @tofile_test_positive_likelihood_seqs_num_pssm = @$tofile_test_positive_likelihood_seqs_num_pssm_ptr;
	# my @tofile_test_positive_likelihood_average_pssm = @$tofile_test_positive_likelihood_average_pssm_ptr;
	
	# my @cv_group_vec = @$cv_group_vec_ptr;
	

	

}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub LearnTrainAndCalTestLikelihood
{
	my ($positive_infile_name_prefix,
		$background_file_name_prefix, $cv_groups_num,
		$processes_num,$num_of_sec_between_q_monitoring,$is_delete_tmp_file,$queue_max_length,
		$background_matrix_file,$letters_at_position_feature_max_positions_num,
		$sum_weights_penalty_coefficient,$weight_matrix_positions_num,
		$num_of_sequences_in_the_world,$positive_seqs_prior_probability,
		$alignment_name_train_positive,$alignment_name_test_positive,
		$alignment_name_train_all,$alignment_name_test_all,
		$estimate_measure_type,
		$use_initial_p_value_filter,$filter_only_positive_features,$remove_features_under_weight_thresh,
		$use_only_positive_weights,$learn_my_pssm,$cal_weights_functions_samples,
		$reweight_positive_instances_fraction,$initial_filter_count_percent_thresh,$write_iteration_file,
		$major_training_parameter_max_train_iterations,$secondary_training_parameter_max_train_iterations,
		$use_secondary_training_procedure,$run_only_on_single_cv_num,$run_mode_int,
		$run_without_creating_CV_dirs,$use_pssm_importance_sampling, $major_training_procedure_type,
		$func_type,$selection_method,$expectation_estimation_method,
		$expectation_by_seq_rewieght,$expectation_by_seq_onlyZero,$expectation_by_seq_Importance,
		$loopy_span_tree_reduction,$loopy_use_gbp,$loopy_max_iterations,
		$loopy_calibration_tresh,$loopy_calibration_node_percent,$loopy_potential_type,
		$loopy_distance_method,$loopy_calibration_tresh_success,$loopy_calibration_node_percent_success,
		$loopy_use_only_exact,$loopy_calibration_method,$loopy_average_messages_in_message_update,
		$init_fmm_from_pssm,
		$limit_the_num_of_parameters_ratio_to_pssm, $max_learning_iterations_num,
		$structure_learning_sum_weights_penalty_coefficient,$parameters_learning_sum_weights_penalty_coefficient,
		$feature_selection_score_thresh,$remove_features_under_weight_thresh_after_each_iter,
		$remove_features_under_weight_thresh_after_full_grafting,$do_parameters_learning_iteration_after_learning_structure,
		$pssm_pseudo_counts, $pseudo_count_equivalent_size,
		$letters_at_two_positions_chi2_filter_fdr_thresh,$letters_at_multiple_positions_binomial_filter_fdr_thresh,$multiple_hypothesis_correction,
		$compute_partition_function_method,$realign_sequences,$max_realign_iterations_num,$compute_positive_sequences_likelihood_method_type,
		$forced_num_positions_without_pedding_of_aligning_pssm) = @_;
	
	print STDOUT "-------------------- in LearnTrainAndCalTestLikelihood  ----------------------------------------\n";
	# exec array
	my @bind_learn_train_and_cal_test_likelihood_exec_strs;
	my @run_learn_train_and_cal_test_likelihood_exec_strs;
	
	for (my $i = 0; $i < $cv_groups_num ; ++$i)
	{
		if (($run_mode_int == 0) || ($run_mode_int == 2 && $run_only_on_single_cv_num == $i) )
		{
			my $cur_run_dir_name = $CV_DIR_PREFIX . $i;
			
			my $cur_map_file_path = "$cur_run_dir_name/$LEARN_TRAIN_AND_CAL_TEST_LIKELIHOOD$MAP_FILE_TYPE_SUFFIX";
			
			if (-e $cur_map_file_path)
			{
				`rm $cur_map_file_path`;
			}
			
			my $cur_map_bind_exec_str = &CreateLearnTrainAndCalTestLikelihoodMapBindExecStr(
											$positive_infile_name_prefix,
											$background_file_name_prefix, $cv_groups_num,
											$processes_num,$num_of_sec_between_q_monitoring,$is_delete_tmp_file,$queue_max_length,
											$background_matrix_file,$letters_at_position_feature_max_positions_num,
											$sum_weights_penalty_coefficient,$weight_matrix_positions_num,
											$num_of_sequences_in_the_world,$positive_seqs_prior_probability,
											$alignment_name_train_positive,$alignment_name_test_positive,
											$alignment_name_train_all,$alignment_name_test_all,
											$estimate_measure_type,
											$use_initial_p_value_filter,$filter_only_positive_features,$remove_features_under_weight_thresh,
											$use_only_positive_weights,$learn_my_pssm,$cal_weights_functions_samples,
											$reweight_positive_instances_fraction,$initial_filter_count_percent_thresh,$write_iteration_file,
											$major_training_parameter_max_train_iterations,$secondary_training_parameter_max_train_iterations,
											$use_secondary_training_procedure, $cur_run_dir_name,$use_pssm_importance_sampling, $major_training_procedure_type,
											$func_type,$selection_method,$expectation_estimation_method,
											$expectation_by_seq_rewieght,$expectation_by_seq_onlyZero,$expectation_by_seq_Importance,
											$loopy_span_tree_reduction,$loopy_use_gbp,$loopy_max_iterations,
											$loopy_calibration_tresh,$loopy_calibration_node_percent,$loopy_potential_type,
											$loopy_distance_method,$loopy_calibration_tresh_success,$loopy_calibration_node_percent_success,
											$loopy_use_only_exact,$loopy_calibration_method,$loopy_average_messages_in_message_update,
											$init_fmm_from_pssm,
											$limit_the_num_of_parameters_ratio_to_pssm, $max_learning_iterations_num,
											$structure_learning_sum_weights_penalty_coefficient,$parameters_learning_sum_weights_penalty_coefficient,
											$feature_selection_score_thresh,$remove_features_under_weight_thresh_after_each_iter,
											$remove_features_under_weight_thresh_after_full_grafting,$do_parameters_learning_iteration_after_learning_structure,
											$pssm_pseudo_counts, $pseudo_count_equivalent_size,
											$letters_at_two_positions_chi2_filter_fdr_thresh,$letters_at_multiple_positions_binomial_filter_fdr_thresh,$multiple_hypothesis_correction,
											$compute_partition_function_method,$realign_sequences,$max_realign_iterations_num,$compute_positive_sequences_likelihood_method_type,
											$forced_num_positions_without_pedding_of_aligning_pssm);
			
			print "$cur_map_bind_exec_str\n";
			
			my $cur_run_learn_exec_str  = &CreateLearnTrainAndCalTestLikelihoodRunExecStr("cd $cur_run_dir_name;" , "cd ..;");
			
			print "$cur_run_learn_exec_str\n";
			
			$bind_learn_train_and_cal_test_likelihood_exec_strs[$i] = $cur_map_bind_exec_str;
			$run_learn_train_and_cal_test_likelihood_exec_strs[$i] = $cur_run_learn_exec_str;
		}
	}
	
	my @create_cv_exec_vec;
	if (($run_mode_int == 0 || $run_mode_int == 1 || $run_mode_int == 2) && (!$run_without_creating_CV_dirs) )
	{
		my $background_file_cmd = "";
		if ($background_file_name_prefix ne "NON")
		{
			#print "\n *************DEBUG: $background_file_name_prefix*************\n";
			$background_file_cmd = "-b $background_file_name_prefix";
		}
		my $create_cv_exec ="make_labeled_cross_validation_sets.pl $positive_infile_name_prefix $alignment_name_train_positive $alignment_name_test_positive $alignment_name_train_all $alignment_name_test_all -g $cv_groups_num $background_file_cmd -od $CV_DIR_PREFIX";
		print "DEBUG: $create_cv_exec\n";
		print "create_cv_exec:$create_cv_exec\n";
		$create_cv_exec_vec[0] = $create_cv_exec;
		
		print STDOUT "-------------------- run_parallel_q_processes: create_cv_exec_vec ----------------------------------------\n";
		&run_parallel_q_processes(\@create_cv_exec_vec, 1, $num_of_sec_between_q_monitoring, $is_delete_tmp_file,$queue_max_length,$max_user_processes,$min_free_processes);
		print STDOUT "-------------- end run_parallel_q_processes: create_cv_exec_vec ------------------------------------\n\n";
	}
	
	if ($run_mode_int == 1)
	{
		return;
	}
	
	
	if (($run_mode_int == 0) || ($run_mode_int == 2) )
	{
		print STDOUT "-------------------- run_parallel_q_processes: bind_learn_train_and_cal_test_likelihood_exec_strs ----------------------------------------\n";
		&run_parallel_q_processes(\@bind_learn_train_and_cal_test_likelihood_exec_strs, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file,$queue_max_length,$max_user_processes,$min_free_processes);
		print STDOUT "-------------- end run_parallel_q_processes: bind_learn_train_and_cal_test_likelihood_exec_strs ------------------------------------\n\n";

		print STDOUT "-------------------- run_parallel_q_processes: run_learn_train_and_cal_test_likelihood_exec_strs ----------------------------------------\n";
		&run_parallel_q_processes(\@run_learn_train_and_cal_test_likelihood_exec_strs, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file,$queue_max_length,$max_user_processes,$min_free_processes);
		print STDOUT "-------------- end run_parallel_q_processes: run_learn_train_and_cal_test_likelihood_exec_strs ------------------------------------\n\n";
	}

	print STDOUT "--------------------   starting to collect res   ----------------------------------------\n";
# collecting the results
	my @train_positive_likelihood_all_feature_weight;
	my @train_positive_likelihood_seqs_num_feature_weight;
	my @train_positive_likelihood_average_feature_weight;
	
	my @train_positive_likelihood_all_mypssm;
	my @train_positive_likelihood_seqs_num_mypssm;
	my @train_positive_likelihood_average_mypssm;
	
	my @train_positive_likelihood_all_pssm;
	my @train_positive_likelihood_seqs_num_pssm;
	my @train_positive_likelihood_average_pssm;
	
	my @test_positive_likelihood_all_feature_weight;
	my @test_positive_likelihood_seqs_num_feature_weight;
	my @test_positive_likelihood_average_feature_weight;
	
	my @test_positive_likelihood_all_mypssm;
	my @test_positive_likelihood_seqs_num_mypssm;
	my @test_positive_likelihood_average_mypssm;
	
	my @test_positive_likelihood_all_pssm;
	my @test_positive_likelihood_seqs_num_pssm;
	my @test_positive_likelihood_average_pssm;
	
	my @cv_group_vec;
	my @col_header_vec;
	
	push(@col_header_vec, "cv_group");
	
	push(@col_header_vec, "train_positive_likelihood_all_feature_weight");
	push(@col_header_vec, "train_positive_likelihood_seqs_num_feature_weight");
	push(@col_header_vec, "train_positive_likelihood_average_feature_weight");
	
	push(@col_header_vec, "train_positive_likelihood_all_pssm");
	push(@col_header_vec, "train_positive_likelihood_seqs_num_pssm");
	push(@col_header_vec, "train_positive_likelihood_average_pssm");
	
	push(@col_header_vec, "test_positive_likelihood_all_feature_weight");
	push(@col_header_vec, "test_positive_likelihood_seqs_num_feature_weight");
	push(@col_header_vec, "test_positive_likelihood_average_feature_weight");
	
	push(@col_header_vec, "test_positive_likelihood_all_pssm");
	push(@col_header_vec, "test_positive_likelihood_seqs_num_pssm");
	push(@col_header_vec, "test_positive_likelihood_average_pssm");
	
	if ($learn_my_pssm == 1)
	{
		 push(@col_header_vec, "train_positive_likelihood_all_mypssm");
		 push(@col_header_vec, "train_positive_likelihood_seqs_num_mypssm");
		 push(@col_header_vec, "train_positive_likelihood_average_mypssm");
		
		 push(@col_header_vec, "test_positive_likelihood_all_mypssm");
		 push(@col_header_vec, "test_positive_likelihood_seqs_num_mypssm");
		 push(@col_header_vec, "test_positive_likelihood_average_mypssm");
	}
	
	my $cur_positive_likelihood_all;
	my $cur_positive_likelihood_seqs;
	my $cur_positive_likelihood_average;
	for (my $i = 0; $i < $cv_groups_num ; ++$i)
	{
		if (($run_mode_int == 0) || ($run_mode_int == 3) || ($run_mode_int == 2 && $run_only_on_single_cv_num == $i) )
		{
			my $cur_likelihood_vec_ptr;

			if ($learn_my_pssm == 1)
			{
				$cur_likelihood_vec_ptr =  &CollectLikelihoodOfFewModels($CV_DIR_PREFIX . $i,
																		$MODEL_OUT_FILES_SUFFIX_LEARNED_FEATURE_WEIGHT,
																		$MODEL_OUT_FILES_SUFFIX_LEARNED_PSSM,
																		$MODEL_OUT_FILES_SUFFIX_LEARNED_MYPSSM);
			}
			else
			{
				$cur_likelihood_vec_ptr =  &CollectLikelihoodOfFewModels($CV_DIR_PREFIX . $i,
																		$MODEL_OUT_FILES_SUFFIX_LEARNED_FEATURE_WEIGHT,
																		$MODEL_OUT_FILES_SUFFIX_LEARNED_PSSM);
			}
			my @cur_likelihood_vec = @$cur_likelihood_vec_ptr;
			
			if ($learn_my_pssm == 1)
			{
				push(@train_positive_likelihood_all_feature_weight,$cur_likelihood_vec[3]);
				push(@train_positive_likelihood_seqs_num_feature_weight,$cur_likelihood_vec[4]);
				push(@train_positive_likelihood_average_feature_weight,$cur_likelihood_vec[5]);
				
				
				push(@train_positive_likelihood_all_pssm,$cur_likelihood_vec[15]);
				push(@train_positive_likelihood_seqs_num_pssm,$cur_likelihood_vec[16]);
				push(@train_positive_likelihood_average_pssm,$cur_likelihood_vec[17]);
				
				push(@test_positive_likelihood_all_feature_weight,$cur_likelihood_vec[9]);
				push(@test_positive_likelihood_seqs_num_feature_weight,$cur_likelihood_vec[10]);
				push(@test_positive_likelihood_average_feature_weight,$cur_likelihood_vec[11]);
				
				push(@test_positive_likelihood_all_pssm,$cur_likelihood_vec[21]);
				push(@test_positive_likelihood_seqs_num_pssm,$cur_likelihood_vec[22]);
				push(@test_positive_likelihood_average_pssm,$cur_likelihood_vec[23]);
				
				push(@train_positive_likelihood_all_mypssm,$cur_likelihood_vec[27]);
				push(@train_positive_likelihood_seqs_num_mypssm,$cur_likelihood_vec[28]);
				push(@train_positive_likelihood_average_mypssm,$cur_likelihood_vec[29]);
				

				push(@test_positive_likelihood_all_mypssm,$cur_likelihood_vec[33]);
				push(@test_positive_likelihood_seqs_num_mypssm,$cur_likelihood_vec[34]);
				push(@test_positive_likelihood_average_mypssm,$cur_likelihood_vec[35]);
				
			}
			else
			{
				push(@train_positive_likelihood_all_feature_weight,$cur_likelihood_vec[3]);
				push(@train_positive_likelihood_seqs_num_feature_weight,$cur_likelihood_vec[4]);
				push(@train_positive_likelihood_average_feature_weight,$cur_likelihood_vec[5]);
				
				push(@train_positive_likelihood_all_pssm,$cur_likelihood_vec[15]);
				push(@train_positive_likelihood_seqs_num_pssm,$cur_likelihood_vec[16]);
				push(@train_positive_likelihood_average_pssm,$cur_likelihood_vec[17]);
				
				push(@test_positive_likelihood_all_feature_weight,$cur_likelihood_vec[9]);
				push(@test_positive_likelihood_seqs_num_feature_weight,$cur_likelihood_vec[10]);
				push(@test_positive_likelihood_average_feature_weight,$cur_likelihood_vec[11]);
				
				
				push(@test_positive_likelihood_all_pssm,$cur_likelihood_vec[21]);
				push(@test_positive_likelihood_seqs_num_pssm,$cur_likelihood_vec[22]);
				push(@test_positive_likelihood_average_pssm,$cur_likelihood_vec[23]);
			}
			

			
			push(@cv_group_vec,$i);
		}
	}
	
	if ($learn_my_pssm == 1)
	{
		return (\@col_header_vec,\@cv_group_vec,
				\@train_positive_likelihood_all_feature_weight,
				\@train_positive_likelihood_seqs_num_feature_weight,
				\@train_positive_likelihood_average_feature_weight,
				\@train_positive_likelihood_all_mypssm,
				\@train_positive_likelihood_seqs_num_mypssm,
				\@train_positive_likelihood_average_mypssm,
				\@train_positive_likelihood_all_pssm,
				\@train_positive_likelihood_seqs_num_pssm,
				\@train_positive_likelihood_average_pssm,
				\@test_positive_likelihood_all_feature_weight,
				\@test_positive_likelihood_seqs_num_feature_weight,
				\@test_positive_likelihood_average_feature_weight,
				\@test_positive_likelihood_all_mypssm,
				\@test_positive_likelihood_seqs_num_mypssm,
				\@test_positive_likelihood_average_mypssm,
				\@test_positive_likelihood_all_pssm,
				\@test_positive_likelihood_seqs_num_pssm,
				\@test_positive_likelihood_average_pssm);
	}
	else
	{
		return (\@col_header_vec,\@cv_group_vec,
				\@train_positive_likelihood_all_feature_weight,
				\@train_positive_likelihood_seqs_num_feature_weight,
				\@train_positive_likelihood_average_feature_weight,
				# \@train_positive_likelihood_all_mypssm,
				# \@train_positive_likelihood_seqs_num_mypssm,
				# \@train_positive_likelihood_average_mypssm,
				\@train_positive_likelihood_all_pssm,
				\@train_positive_likelihood_seqs_num_pssm,
				\@train_positive_likelihood_average_pssm,
				\@test_positive_likelihood_all_feature_weight,
				\@test_positive_likelihood_seqs_num_feature_weight,
				\@test_positive_likelihood_average_feature_weight,
				# \@test_positive_likelihood_all_mypssm,
				# \@test_positive_likelihood_seqs_num_mypssm,
				# \@test_positive_likelihood_average_mypssm,
				\@test_positive_likelihood_all_pssm,
				\@test_positive_likelihood_seqs_num_pssm,
				\@test_positive_likelihood_average_pssm);
	}
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub  CreateLearnTrainAndCalTestLikelihoodRunExecStr
{
	my ($prefix_cmd_str, $suffix_cmd_str) = @_;
	
	return $prefix_cmd_str . " $ENV{GENIE_EXE} $LEARN_TRAIN_AND_CAL_TEST_LIKELIHOOD$MAP_FILE_TYPE_SUFFIX; " . $suffix_cmd_str;
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub  CreateLearnTrainAndCalTestLikelihoodMapBindExecStr
{
	my ($positive_infile_name_prefix,
		$background_file_name_prefix, $cv_groups_num,
		$processes_num,$num_of_sec_between_q_monitoring,$is_delete_tmp_file,$queue_max_length,
		$background_matrix_file,$letters_at_position_feature_max_positions_num,
		$sum_weights_penalty_coefficient,$weight_matrix_positions_num,
		$num_of_sequences_in_the_world,$positive_seqs_prior_probability,
		$alignment_name_train_positive,$alignment_name_test_positive,
		$alignment_name_train_all,$alignment_name_test_all,
		$estimate_measure_type,
		$use_initial_p_value_filter,$filter_only_positive_features,$remove_features_under_weight_thresh,
		$use_only_positive_weights,$learn_my_pssm,$cal_weights_functions_samples,
		$reweight_positive_instances_fraction,$initial_filter_count_percent_thresh,$write_iteration_file,
		$major_training_parameter_max_train_iterations,$secondary_training_parameter_max_train_iterations,
		$use_secondary_training_procedure, $ret_map_file_dir,$use_pssm_importance_sampling, $major_training_procedure_type,
		$func_type,$selection_method,$expectation_estimation_method,
		$expectation_by_seq_rewieght,$expectation_by_seq_onlyZero,$expectation_by_seq_Importance,
		$loopy_span_tree_reduction,$loopy_use_gbp,$loopy_max_iterations,
		$loopy_calibration_tresh,$loopy_calibration_node_percent,$loopy_potential_type,
		$loopy_distance_method,$loopy_calibration_tresh_success,$loopy_calibration_node_percent_success,
		$loopy_use_only_exact,$loopy_calibration_method,$loopy_average_messages_in_message_update,
		$init_fmm_from_pssm,
		$limit_the_num_of_parameters_ratio_to_pssm, $max_learning_iterations_num,
		$structure_learning_sum_weights_penalty_coefficient,$parameters_learning_sum_weights_penalty_coefficient,
		$feature_selection_score_thresh,$remove_features_under_weight_thresh_after_each_iter,
		$remove_features_under_weight_thresh_after_full_grafting,$do_parameters_learning_iteration_after_learning_structure,
		$pssm_pseudo_counts, $pseudo_count_equivalent_size,
		$letters_at_two_positions_chi2_filter_fdr_thresh,$letters_at_multiple_positions_binomial_filter_fdr_thresh,$multiple_hypothesis_correction,
		$compute_partition_function_method,$realign_sequences,$max_realign_iterations_num,$compute_positive_sequences_likelihood_method_type,
		$forced_num_positions_without_pedding_of_aligning_pssm) = @_;

	
	# parameters (file namse)  for xml bind
	my $learn_feature_weight_output_file = $LEARN_FEATURE_WEIGHT_OUTPUT_FILE . $MODEL_FILE_TYPE_SUFFIX;
	my $updated_z_learn_feature_weight_output_file = $UPDATED_Z_LEARN_FEATURE_WEIGHT_OUTPUT_FILE . $MODEL_FILE_TYPE_SUFFIX;
	my $un_learned_mypssm_file_name = $UN_LEARNED_MYPSSM_FILE_NAME . $MODEL_FILE_TYPE_SUFFIX;
	my $updated_z_learn_mypssm_output_file = $UPDATED_Z_LEARN_MYPSSM_OUTPUT_FILE . $MODEL_FILE_TYPE_SUFFIX;
	my $mypssm_model_file_name = $MYPSSM_MODEL_FILE_NAME . $MODEL_FILE_TYPE_SUFFIX;
	my $pssm_model_file_name = $PSSM_MODEL_FILE_NAME . $MODEL_FILE_TYPE_SUFFIX;
	my $mypssm_init_from_pssm_file_name = $MYPSSM_INIT_FROM_PSSM_FILE_NAME . $MODEL_FILE_TYPE_SUFFIX;

	my $learn_feature_weight_feature_stat_output_file = $LEARN_FEATURE_WEIGHT_FEATURE_STAT_OUTPUT_FILE . $FEATURE_STAT_FILE_TYPE_SUFFIX;

	my $learn_feature_weight_matlab_output_file_name = $LEARN_FEATURE_WEIGHT_MATLAB_OUTPUT_FILE_NAME . $MATLAB_FILE_TYPE_SUFFIX;
	my $learn_mypssm_matlab_output_file_name = $LEARN_MYPSSM_MATLAB_OUTPUT_FILE_NAME . $MATLAB_FILE_TYPE_SUFFIX;

	my $learn_feature_weight_estimator_output_file = $LEARN_FEATURE_WEIGHT_ESTIMATOR_OUTPUT_FILE . $ESTIMATOR_FILE_TYPE_SUFFIX;
	my $learn_mypssm_estimator_output_file = $LEARN_MYPSSM_ESTIMATOR_OUTPUT_FILE . $ESTIMATOR_FILE_TYPE_SUFFIX;
	my $learn_pssm_estimator_output_file = $LEARN_PSSM_ESTIMATOR_OUTPUT_FILE . $ESTIMATOR_FILE_TYPE_SUFFIX;

	my $likelihood_output_file_train_learned_feature_weight = $LIKELIHOOD_OUTPUT_FILE_TRAIN_PREFIX . $MODEL_OUT_FILES_SUFFIX_LEARNED_FEATURE_WEIGHT . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
	my $likelihood_output_file_train_learned_mypssm = $LIKELIHOOD_OUTPUT_FILE_TRAIN_PREFIX . $MODEL_OUT_FILES_SUFFIX_LEARNED_MYPSSM . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
	my $likelihood_output_file_train_learned_pssm = $LIKELIHOOD_OUTPUT_FILE_TRAIN_PREFIX . $MODEL_OUT_FILES_SUFFIX_LEARNED_PSSM . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
	my $likelihood_output_file_test_learned_feature_weight = $LIKELIHOOD_OUTPUT_FILE_TEST_PREFIX  . $MODEL_OUT_FILES_SUFFIX_LEARNED_FEATURE_WEIGHT . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
	my $likelihood_output_file_test_learned_mypssm = $LIKELIHOOD_OUTPUT_FILE_TEST_PREFIX . $MODEL_OUT_FILES_SUFFIX_LEARNED_MYPSSM . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
	my $likelihood_output_file_test_learned_pssm = $LIKELIHOOD_OUTPUT_FILE_TEST_PREFIX . $MODEL_OUT_FILES_SUFFIX_LEARNED_PSSM . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;

	my $max_features_parameters_num = -1;
	if ($limit_the_num_of_parameters_ratio_to_pssm > 0)
	{
		$max_features_parameters_num = $weight_matrix_positions_num * 3 * $limit_the_num_of_parameters_ratio_to_pssm; # TODO 3 for ACGT = DNA  * 3
	}
	
	# creating the bind str
	
	my $learn_and_compare_exec_str;
	if ($use_pssm_importance_sampling == 1)
	{
		$learn_and_compare_exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/learn_train_data_and_cal_train_and_test_likelihood_sampled_fromPssm.map");
	}
	else
	{
		$learn_and_compare_exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/learn_train_data_and_cal_train_and_test_likelihood.map");
	}


	if ($learn_my_pssm == 1)
	{
		$learn_and_compare_exec_str .= &AddStringProperty("LEARN_ALSO_MY_PSSM", $learn_my_pssm);
	}
	
	
	$learn_and_compare_exec_str .= &AddStringProperty("INIT_FMM_FROM_PSSM", $init_fmm_from_pssm);
	

	$learn_and_compare_exec_str .= &AddStringProperty("BACKGROUND_MATRIX_FILE", $background_matrix_file);
	$learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_OUTPUT_FILE", $learn_feature_weight_output_file);
	$learn_and_compare_exec_str .= &AddStringProperty("UPDATED_Z_LEARN_FEATURE_WEIGHT_OUTPUT_FILE", $updated_z_learn_feature_weight_output_file);
	$learn_and_compare_exec_str .= &AddStringProperty("UN_LEARNED_MYPSSM_FILE_NAME", $un_learned_mypssm_file_name);
	$learn_and_compare_exec_str .= &AddStringProperty("UPDATED_Z_LEARN_MYPSSM_OUTPUT_FILE", $updated_z_learn_mypssm_output_file);
	$learn_and_compare_exec_str .= &AddStringProperty("MYPSSM_MODEL_FILE_NAME", $mypssm_model_file_name);
	$learn_and_compare_exec_str .= &AddStringProperty("PSSM_MODEL_FILE_NAME", $pssm_model_file_name);
	$learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_ESTIMATOR_OUTPUT_FILE", $learn_feature_weight_estimator_output_file);
	$learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_FEATURE_STAT_OUTPUT_FILE", $learn_feature_weight_feature_stat_output_file);
	$learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_MATLAB_OUTPUT_FILE_NAME", $learn_feature_weight_matlab_output_file_name);
	$learn_and_compare_exec_str .= &AddStringProperty("LETTERS_AT_POSITION_FEATURE_MAX_POSITIONS_NUM", $letters_at_position_feature_max_positions_num);
	$learn_and_compare_exec_str .= &AddStringProperty("SUM_WEIGHTS_PENALTY_COEFFICIENT", $sum_weights_penalty_coefficient);
	$learn_and_compare_exec_str .= &AddStringProperty("WEIGHT_MATRIX_POSITIONS_NUM", $weight_matrix_positions_num);
	$learn_and_compare_exec_str .= &AddStringProperty("NUM_OF_SEQUENCES_IN_THE_WORLD", $num_of_sequences_in_the_world);
	$learn_and_compare_exec_str .= &AddStringProperty("POSITIVE_SEQS_PRIOR_PROBABILITY", $positive_seqs_prior_probability);
	$learn_and_compare_exec_str .= &AddStringProperty("LEARN_MYPSSM_ESTIMATOR_OUTPUT_FILE", $learn_mypssm_estimator_output_file);
	$learn_and_compare_exec_str .= &AddStringProperty("LEARN_MYPSSM_MATLAB_OUTPUT_FILE_NAME", $learn_mypssm_matlab_output_file_name);
	$learn_and_compare_exec_str .= &AddStringProperty("LEARN_PSSM_ESTIMATOR_OUTPUT_FILE", $learn_pssm_estimator_output_file);
	$learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_FEATURE_WEIGHT", $likelihood_output_file_train_learned_feature_weight);
	$learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_MYPSSM", $likelihood_output_file_train_learned_mypssm);
	$learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_PSSM", $likelihood_output_file_train_learned_pssm);
	$learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_FEATURE_WEIGHT", $likelihood_output_file_test_learned_feature_weight);
	$learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_MYPSSM", $likelihood_output_file_test_learned_mypssm);
	$learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_PSSM", $likelihood_output_file_test_learned_pssm);
	$learn_and_compare_exec_str .= &AddStringProperty("MAX_FEATURES_PARAMETERS_NUM", $max_features_parameters_num);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_ESTIMATE_MEASURE_TYPE", $estimate_measure_type);
	
	$learn_and_compare_exec_str .= &AddStringProperty("USE_INITIAL_P_VALUE_FILTER", $use_initial_p_value_filter);
	$learn_and_compare_exec_str .= &AddStringProperty("FILTER_ONLY_POSITIVE_FEATURES", $filter_only_positive_features);
	$learn_and_compare_exec_str .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH", $remove_features_under_weight_thresh);
	
	$learn_and_compare_exec_str .= &AddStringProperty("USE_ONLY_POSITIVE_WEIGHTS", $use_only_positive_weights);
	$learn_and_compare_exec_str .= &AddStringProperty("CAL_WEIGHTS_FUNCTIONS_SAMPLES", $cal_weights_functions_samples);
	$learn_and_compare_exec_str .= &AddStringProperty("REWEIGHT_POSITIVE_INSTANCES_FRACTION", $reweight_positive_instances_fraction);
	$learn_and_compare_exec_str .= &AddStringProperty("INITIAL_FILTER_COUNT_PERCENT_THRESH", $initial_filter_count_percent_thresh);
	
	$learn_and_compare_exec_str .= &AddStringProperty("MAJOR_TRAINING_PROCEDURE_TYPE", $major_training_procedure_type);
	
	if ($write_iteration_file ==1)
	{
		$learn_and_compare_exec_str .= &AddStringProperty("TRAINING_ITERATION_SCORE_FEATURE_OUT_FILE_NAME", $FEATURE_TRAINING_ITERATION_SCORE_OUT_FILE_NAME);
	}
	
	$learn_and_compare_exec_str .= &AddStringProperty("MAJOR_TRAINING_PARAMETER_MAX_TRAIN_ITERATIONS", $major_training_parameter_max_train_iterations);
	$learn_and_compare_exec_str .= &AddStringProperty("SECONDARY_TRAINING_PARAMETER_MAX_TRAIN_ITERATIONS", $secondary_training_parameter_max_train_iterations);
	$learn_and_compare_exec_str .= &AddStringProperty("USE_SECONDARY_TRAINING_PROCEDURE", $use_secondary_training_procedure);
	

	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_FUNCTION_TYPE_TOKEN", $func_type);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_SELECTION_METHOD_TYPE_TOKEN", $selection_method);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_EXPECTATION_ESTIMATION_METHOD_TYPE_TOKEN", $expectation_estimation_method);
	$learn_and_compare_exec_str .= &AddStringProperty("USE_REWEIGHT_COEFF_IN_FEATURE_EXP_TOKEN", $expectation_by_seq_rewieght);
	$learn_and_compare_exec_str .= &AddStringProperty("USE_ONLY_ZERO_LABELS_IN_FEATURE_EXP_TOKEN", $expectation_by_seq_onlyZero);
	$learn_and_compare_exec_str .= &AddStringProperty("USE_IMPORTANCE_SAMPLING_SCALING_IN_FEATURE_EXP_TOKEN", $expectation_by_seq_Importance);

	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_MAX_SPANNING_TREES_REDUCTION_TOKEN", $loopy_span_tree_reduction);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_GBP_TOKEN", $loopy_use_gbp);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_ONLY_EXACT", $loopy_use_only_exact);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_MAX_ITERATIONS_TOKEN", $loopy_max_iterations);

	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_TRESH_TOKEN", $loopy_calibration_tresh);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $loopy_calibration_node_percent);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_POTENTIAL_TYPE_TOKEN", $loopy_potential_type);

	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_DISTANCE_METHOD_TYPE_TOKEN", $loopy_distance_method);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATION_TRESH_TOKEN", $loopy_calibration_tresh_success);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $loopy_calibration_node_percent_success);

	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_METHOD_TYPE", $loopy_calibration_method);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_AVERAGE_MESSAGES_IN_MESSAGE_UPDATE", $loopy_average_messages_in_message_update);

	$learn_and_compare_exec_str .= &AddStringProperty("MYPSSM_INIT_FROM_PSSM_FILE_NAME", $mypssm_init_from_pssm_file_name);

	$learn_and_compare_exec_str .= &AddStringProperty("MAX_LEARNING_ITERATIONS_NUM", $max_learning_iterations_num);
	$learn_and_compare_exec_str .= &AddStringProperty("STRUCTURE_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT", $structure_learning_sum_weights_penalty_coefficient);
	$learn_and_compare_exec_str .= &AddStringProperty("PARAMETERS_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT", $parameters_learning_sum_weights_penalty_coefficient);
	$learn_and_compare_exec_str .= &AddStringProperty("FEATURE_SELECTION_SCORE_THRESH", $feature_selection_score_thresh);
	$learn_and_compare_exec_str .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH_AFTER_EACH_ITER", $remove_features_under_weight_thresh_after_each_iter);
	$learn_and_compare_exec_str .= &AddStringProperty("REMOVE_FEATURES_UNDER_WEIGHT_THRESH_AFTER_FULL_GRAFTING", $remove_features_under_weight_thresh_after_full_grafting);
	$learn_and_compare_exec_str .= &AddStringProperty("DO_PARAMETERS_LEARNING_ITERATION_AFTER_LEARNING_STRUCTURE", $do_parameters_learning_iteration_after_learning_structure);

	$learn_and_compare_exec_str .= &AddStringProperty("PSSM_PSEUDO_COUNTS", $pssm_pseudo_counts);
	$learn_and_compare_exec_str .= &AddStringProperty("PSEUDO_COUNT_EQUIVALENT_SIZE", $pseudo_count_equivalent_size);

	$learn_and_compare_exec_str .= &AddStringProperty("LETTERS_AT_TWO_POSITIONS_CHI2_FILTER_FDR_THRESH", $letters_at_two_positions_chi2_filter_fdr_thresh);
	$learn_and_compare_exec_str .= &AddStringProperty("LETTERS_AT_MULTIPLE_POSITIONS_BINOMIAL_FILTER_FDR_THRESH", $letters_at_multiple_positions_binomial_filter_fdr_thresh);
	$learn_and_compare_exec_str .= &AddStringProperty("MULTIPLE_HYPOTHESIS_CORRECTION", $multiple_hypothesis_correction);

	$learn_and_compare_exec_str .= &AddStringProperty("COMPUTE_PARTITION_FUNCTION_METHOD", $compute_partition_function_method);

	$learn_and_compare_exec_str .= &AddStringProperty("REALIGN_SEQUENCES", $realign_sequences);
	$learn_and_compare_exec_str .= &AddStringProperty("MAX_REALIGN_ITERATIONS_NUM", $max_realign_iterations_num);

	$learn_and_compare_exec_str .= &AddStringProperty("MAX_REALIGN_ITERATIONS_NUM", $max_realign_iterations_num);
	$learn_and_compare_exec_str .= &AddStringProperty("COMPUTE_POSITIVE_SEQUENCES_LIKELIHOOD_METHOD_TYPE", $compute_positive_sequences_likelihood_method_type);

#DEBUG

	$learn_and_compare_exec_str .= &AddStringProperty("FORCED_NUM_POSITIONS_WITHOUT_PEDDING_OF_ALIGNING_PSSM", $forced_num_positions_without_pedding_of_aligning_pssm);

	my $ret_exec_str = "$learn_and_compare_exec_str | sed 's/$space/ /g' > $ret_map_file_dir/$LEARN_TRAIN_AND_CAL_TEST_LIKELIHOOD$MAP_FILE_TYPE_SUFFIX ";
	
	return $ret_exec_str;
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub CollectLikelihoodOfFewModels
{
	my ($dir_name, @models_out_file_suffixs) = @_;
	
	my $cur_likelihood_all;
	my $cur_likelihood_seqs_num;
	my $cur_likelihood_average;
	
	my $cur_positive_likelihood_all;
	my $cur_positive_likelihood_seqs_num;
	my $cur_positive_likelihood_average;
	my @ret_vec;
	
	foreach my $cur_model_out_file_suffix (@models_out_file_suffixs)
	{
		my $cur_out_likelihood_train = $dir_name . "/" . $LIKELIHOOD_OUTPUT_FILE_TRAIN_PREFIX . $cur_model_out_file_suffix . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		my $cur_out_likelihood_test  = $dir_name . "/" . $LIKELIHOOD_OUTPUT_FILE_TEST_PREFIX  . $cur_model_out_file_suffix . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		
		#($cur_positive_likelihood_all,$cur_positive_likelihood_seqs,$cur_positive_likelihood_average) = &
		
		($cur_likelihood_all,$cur_likelihood_seqs_num,$cur_likelihood_average,
		 $cur_positive_likelihood_all,$cur_positive_likelihood_seqs_num,$cur_positive_likelihood_average) 
		 = &CollectLikelihoodResultsFromFile($cur_out_likelihood_train);
		 
		 push(@ret_vec, $cur_likelihood_all);
		 push(@ret_vec, $cur_likelihood_seqs_num);
		 push(@ret_vec, $cur_likelihood_average);
		 push(@ret_vec, $cur_positive_likelihood_all);
		 push(@ret_vec, $cur_positive_likelihood_seqs_num);
		 push(@ret_vec, $cur_positive_likelihood_average);

		 ($cur_likelihood_all,$cur_likelihood_seqs_num,$cur_likelihood_average,
		 $cur_positive_likelihood_all,$cur_positive_likelihood_seqs_num,$cur_positive_likelihood_average) 
		 = &CollectLikelihoodResultsFromFile($cur_out_likelihood_test);
		 
		 push(@ret_vec, $cur_likelihood_all);
		 push(@ret_vec, $cur_likelihood_seqs_num);
		 push(@ret_vec, $cur_likelihood_average);
		 push(@ret_vec, $cur_positive_likelihood_all);
		 push(@ret_vec, $cur_positive_likelihood_seqs_num);
		 push(@ret_vec, $cur_positive_likelihood_average);
	}
	
	return \@ret_vec;
}


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub RunCalIndications
{
	my ($ind_dirs_file,$ind_CV_dir_num_for_model,$ind_out_file_name,$ind_input_files_prefix,$ind_processes_num) = @_;

	my $ind_dirs_vec_ptr;
	my $ind_appearences_vec_ptr;
	my $ind_weight_matrix_positions_num_vec_ptr;
	
	my ($ind_dirs_vec_ptr,$ind_appearences_vec_ptr,$ind_weight_matrix_positions_num_vec_ptr) = &ParseDirsFile($ind_dirs_file);

	my @ind_dirs_vec = @$ind_dirs_vec_ptr;
	my @ind_appearences_vec = @$ind_appearences_vec_ptr;
	my @ind_weight_matrix_positions_num_vec = @$ind_weight_matrix_positions_num_vec_ptr;
	
	my $ind_dirs_num = scalar(@ind_dirs_vec);

	
	my $updated_z_learn_feature_weight_output_file = "CV_". $ind_CV_dir_num_for_model . "/" . $UPDATED_Z_LEARN_FEATURE_WEIGHT_OUTPUT_FILE . $MODEL_FILE_TYPE_SUFFIX;
	
	
	my $ind_bind_exec_str =  &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/run_compute_sequences_features_indications.map");
	$ind_bind_exec_str .= &AddStringProperty("MATRIX_FILE", $updated_z_learn_feature_weight_output_file);
	$ind_bind_exec_str .= &AddStringProperty("DATA_FILE_SEQ", "$ind_input_files_prefix.fa");
	$ind_bind_exec_str .= &AddStringProperty("DATA_FILE_ALIGNMENT","$ind_input_files_prefix.alignment");
	$ind_bind_exec_str .= &AddStringProperty("DATA_FILE_LABELS", "$ind_input_files_prefix.labels");
	$ind_bind_exec_str .= &AddStringProperty("SEQUENCES_FETURES_INDICATIONS_OUT_FILE", $ind_out_file_name);

	my $CAL_IND_MAP_FILENAME = "$CAL_IND_MAP$MAP_FILE_TYPE_SUFFIX";

	my @ind_bind_exec_vec;
	my @ind_run_exec_vec;
	
	for (my $cur_dir_num = 0; $cur_dir_num < $ind_dirs_num; ++$cur_dir_num)
	{
		my $cur_ind_dir = $ind_dirs_vec[$cur_dir_num];
		my $cur_ind_appearences = $ind_appearences_vec[$cur_dir_num];
		my $cur_ind_weight_matrix_positions_num= $ind_weight_matrix_positions_num_vec[$cur_dir_num];
		
		my $cur_ind_exec_str = "$ind_bind_exec_str | sed 's/$space/ /g' > $cur_ind_dir/$CAL_IND_MAP_FILENAME\n;";
		
		push(@ind_bind_exec_vec,$cur_ind_exec_str);
		my $cur_ind_run_exec_vec = "cd $cur_ind_dir; $ENV{GENIE_EXE} $CAL_IND_MAP_FILENAME; cd ..;\n";
		push(@ind_run_exec_vec,$cur_ind_run_exec_vec);
	}
	
		print STDOUT "-------------------- run_parallel_q_processes: ind_bind_exec_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@ind_bind_exec_vec, $ind_processes_num, 2, 0,-1,$max_user_processes,$min_free_processes);
	print STDOUT "-------------- end run_parallel_q_processes: ind_bind_exec_vec ------------------------------------\n\n";

	print STDOUT "-------------------- run_parallel_q_processes: ind_run_exec_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@ind_run_exec_vec, $ind_processes_num, 2, 0,-1,$max_user_processes,$min_free_processes);
	print STDOUT "-------------- end run_parallel_q_processes: ind_run_exec_vec ------------------------------------\n\n";

	
}

