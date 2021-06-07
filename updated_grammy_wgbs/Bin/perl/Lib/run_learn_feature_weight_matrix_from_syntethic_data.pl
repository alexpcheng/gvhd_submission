#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/System/q_util.pl";

# file consts
my $space = "___SPACE___";

my $MODEL_FILE_SUFFIX                     = "_MODEL_";
my $MODEL_TEST_SUFFIX                     = "_MODEL_TEST_SUFFIX";
my $RUN_DIRS_SUFFIX                       = "_SYNTHETIC_FEATURES_DIR_NUM_";
my $RUN_FILE_SUFFIX                       = "_RUN_";
my $MODEL_FILE_TYPE_SUFFIX                = ".gxw";
my $MATLAB_FILE_TYPE_SUFFIX               = ".m";
my $ESTIMATOR_FILE_TYPE_SUFFIX            = ".estimator";
my $FEATURE_STAT_FILE_TYPE_SUFFIX         = ".feature_stat";
my $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX       = ".mat_likelihood";
my $MAT_COMPARE_FILE_TYPE_SUFFIX          = ".mat_compare";

my $UPDATED_Z_TRUE_MODEL_FILE_NAME_PREFIX               = "updated_z_true_model";

my $LEARN_FEATURE_WEIGHT_OUTPUT_FILE                    = "Out_WeightMatrixLearnedFromSyntheticData";
my $UPDATED_Z_LEARN_FEATURE_WEIGHT_OUTPUT_FILE          = "Out_synthetic_learned_feature_weight_model_updated_Z";
my $UN_LEARNED_MYPSSM_FILE_NAME                         = "Out_CreatePssmLikeFeatureWeightMatrix_mypssm";
my $MYPSSM_MODEL_FILE_NAME                              = "Out_WeightMatrixMyPSSMLearnedFromSyntheticData";
my $UPDATED_Z_LEARN_MYPSSM_OUTPUT_FILE                  = "Out_synthetic_learned_mypssm_model_updated_Z";
my $PSSM_MODEL_FILE_NAME                                = "Out_PSSMLearnedFromSyntheticData";
my $LEARN_FEATURE_WEIGHT_ESTIMATOR_OUTPUT_FILE          = "Out_WeightMatrixLearnedFromSyntheticData_Estimator";
my $LEARN_FEATURE_WEIGHT_FEATURE_STAT_OUTPUT_FILE       = "Out_WeightMatrixLearnedFromSyntheticData_FeatureStat";
my $LEARN_FEATURE_WEIGHT_MATLAB_OUTPUT_FILE_NAME        = "matlab_learned_feature_weight";
my $LEARN_MYPSSM_ESTIMATOR_OUTPUT_FILE                  = "Out_WeightMatrixMyPSSMLearnedFromSyntheticData_Estimator";
my $LEARN_MYPSSM_MATLAB_OUTPUT_FILE_NAME                = "matlab_learned_mypssm";
my $LEARN_PSSM_ESTIMATOR_OUTPUT_FILE                    = "Out_PSSMLearnedFromSyntheticData_Estimator";
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_TRUE_MODEL             = "ComputeSequencesLikelihood_Train_true_model";
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_FEATURE_WEIGHT = "ComputeSequencesLikelihood_Train_learned_feature_weight";
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_MYPSSM         = "ComputeSequencesLikelihood_Train_learned_mypssm";
my $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_PSSM           = "ComputeSequencesLikelihood_Train_learned_pssm";
my $LIKELIHOOD_OUTPUT_FILE_TEST_TRUE_MODEL              = "ComputeSequencesLikelihood_Test_true_model";
my $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_FEATURE_WEIGHT  = "ComputeSequencesLikelihood_Test_learned_feature_weight";
my $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_MYPSSM          = "ComputeSequencesLikelihood_Test_learned_mypssm";
my $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_PSSM            = "ComputeSequencesLikelihood_Test_learned_pssm";
my $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_FEATURE_WEIGHT = "Out_CompareWeightMatrices_true_model_2_learned_feature_weight";
my $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_MYPSSM         = "Out_CompareWeightMatrices_true_model_2_learned_mypssm";
my $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_PSSM           = "Out_CompareWeightMatrices_true_model_2_learned_pssm";


my $FEATURE_FUNCTION_TYPE_TOKEN                                                = "SeqsLGradientUsingFeatureEstimation";
my $FEATURE_SELECTION_METHOD_TYPE_TOKEN                                        = "Grafting";
my $FEATURE_EXPECTATION_ESTIMATION_METHOD_TYPE_TOKEN                           = "CliqueGraph";

my $CREATE_SYNTHETIC_TEST_DATA_MAP_FILE_NAME_PREFIX     = "SYNTHETIC_CREATE_TEST_DATA_";
my $CREATE_DATA_AND_MODEL_MAP_FILE_NAME                 = "SYNTHETIC_CREATE_DATA_AND_MODEL.map";
my $LEARN_AND_COMPARE_MAP_FILE_NAME                     = "SYNTHETIC_LEARN_AND_COMPARE.map";
my $LEARN_AND_COMPARE_MAP_FILE_NAME                     = "SYNTHETIC_LEARN_AND_COMPARE";
my $MAP_FILE_TYPE_SUFFIX               = ".map";

my $TEST_DATA_NAME_PREFIX            = "SyntheticDataTest";
my $TEST_OUTPUT_FILE_PREFIX_PREFIX   = "synthetic_data_test";
my $TRAIN_DATA_NAME_PREFIX            = "SyntheticData";
my $TRAIN_OUTPUT_FILE_PREFIX_PREFIX   = "synthetic_data";
my $ALL_DATA_NAME_PREFIX            = "SyntheticDataAll";
my $ALL_OUTPUT_FILE_PREFIX_PREFIX   = "synthetic_data_all";
my $POSITIVE_DATA_NAME_PREFIX            = "SyntheticDataPositive";
my $POSITIVE_OUTPUT_FILE_PREFIX_PREFIX   = "synthetic_data_positive";


my $TEST_BACKGROUND_SAMPLE_NUM       = 10;
my $PSSM_PSEUDO_COUNTS               = 0.4;

#$NUM_OF_SEQUENCES_IN_THE_WORLD_DEFUALT = -1;
#$POSITIVE_SEQS_PRIOR_PROBABILITY_DEFUALT = -1;



if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

if ($ARGV[0] eq "--collect")
{
  my $arg_collect_param_file_path = $ARGV[1];
  my $arg_collect_out_file_path   = $ARGV[2];
  
  &CollectUsingParamFile($arg_collect_param_file_path,$arg_collect_out_file_path);
  
  exit;
}



# getting  the parameters
my $models_file              = $ARGV[0];
my $models_dir               = $ARGV[1];
my $background_matrix_file   = $ARGV[2];
my $args_file                = $ARGV[3]; # get the params from here 
my $run_dirs_prefix          = $ARGV[4];
my $test_files_dir           = $ARGV[5];
my $output_run_prarams_file  = $ARGV[6];
my $exec_strs_output_file    = $ARGV[7];
my $output_file              = $ARGV[8];


# getting the flags
my %args = &load_args(\@ARGV);
my $processes_num                               = &get_arg("p", 5, \%args);
my $max_queue_length                            = &get_arg("q", -1, \%args);
my $num_of_sec_between_q_monitoring             = &get_arg("s", 2, \%args);
my $is_delete_tmp_file                          = &get_arg("d", 1, \%args);
my $output_dir                                  = &get_arg("o", "./", \%args);
my $repeat_num                                  = &get_arg("r", 1, \%args);
my $fix_not_run_mode                            = &get_arg("f", 0, \%args);

my $max_user_processes                          = &get_arg("MaxUserP", 30, \%args);
my $min_free_processes                          = &get_arg("MinFreeProcesses", 1, \%args);

my $delete_test_files                           = &get_arg("DeleteTestFiles", 1, \%args);

my $TEST_TRUE_MODEL_SAMPLE_NUM                  = &get_arg("TestTrueModelSampleNum", 10000, \%args);

my $no_need_to_copy_test_files                  = &get_arg("NoNeedToCopyTestFiles", 0, \%args);

# learning parameters
my $init_fmm_by_first_learning_pssm             = &get_arg("init_fmm_by_first_learning_pssm", "true", \%args);
my $letters_at_multiple_positions_binomial_filter_fdr_thresh             = &get_arg("letters_at_multiple_positions_binomial_filter_fdr_thresh", "0.25", \%args);
my $max_features_parameters_num                = &get_arg("max_features_parameters_num", "1000", \%args);
my $max_learning_iterations_num                = &get_arg("max_learning_iterations_num", "20", \%args);



#my $num_of_sequences_in_the_world               = &get_arg("w", $NUM_OF_SEQUENCES_IN_THE_WORLD_DEFUALT, \%args);
#my $positive_seqs_prior_probability             = &get_arg("f", $POSITIVE_SEQS_PRIOR_PROBABILITY_DEFUALT, \%args);



print STDOUT "---------------------------------params: ----------------------------------------\n";
print STDOUT "models_file:$models_file\n";
print STDOUT "background_matrix_file:$background_matrix_file\n";
print STDOUT "args_file:$args_file\n";
print STDOUT "run_dirs_prefix:$run_dirs_prefix\n";
print STDOUT "test_files_dir:$test_files_dir\n";
print STDOUT "output_run_prarams_file:$output_run_prarams_file\n";
print STDOUT "exec_strs_output_file:$exec_strs_output_file\n";
print STDOUT "output_file:$output_file\n";
print STDOUT "---- flags: -----\n";
print STDOUT "processes_num:$processes_num\n";
print STDOUT "max_queue_length:$max_queue_length\n";
print STDOUT "output_dir:$output_dir\n";
print STDOUT "num_of_sec_between_q_monitoring:$num_of_sec_between_q_monitoring\n";
print STDOUT "is_delete_tmp_file:$is_delete_tmp_file\n";
print STDOUT "repeat_num:$repeat_num\n";
print STDOUT "fix_not_run_mode:$fix_not_run_mode\n";
print STDOUT "max_user_processes:$max_user_processes\n";
print STDOUT "min_free_processes:$min_free_processes\n";
print STDOUT "delete_test_files:$delete_test_files\n";
print STDOUT "TEST_TRUE_MODEL_SAMPLE_NUM:$TEST_TRUE_MODEL_SAMPLE_NUM\n";
print STDOUT "no_need_to_copy_test_files:$no_need_to_copy_test_files\n";
print STDOUT "init_fmm_by_first_learning_pssm:$init_fmm_by_first_learning_pssm\n";
print STDOUT "letters_at_multiple_positions_binomial_filter_fdr_thresh:$letters_at_multiple_positions_binomial_filter_fdr_thresh\n";
print STDOUT "max_features_parameters_num:$max_features_parameters_num\n";
print STDOUT "max_learning_iterations_num:$max_learning_iterations_num\n";

print STDOUT "--------------------------------------------------------------------------------\n\n";

# parameters of the runs
my ($train_true_model_sample_num_vec_ptr,$train_background_sample_num_vec_ptr,$sum_weights_penalty_coefficient_vec_ptr,$num_of_sequences_in_the_world_vec_ptr,$positive_seqs_prior_probability_vec_ptr) = &ParseArgsFile($args_file);
my @train_true_model_sample_num_vec     = @$train_true_model_sample_num_vec_ptr;
my @train_background_sample_num_vec     = @$train_background_sample_num_vec_ptr;
my @sum_weights_penalty_coefficient_vec = @$sum_weights_penalty_coefficient_vec_ptr;
my @num_of_sequences_in_the_world_vec   = @$num_of_sequences_in_the_world_vec_ptr;
my @positive_seqs_prior_probability_vec = @$positive_seqs_prior_probability_vec_ptr;

(scalar(@num_of_sequences_in_the_world_vec) == scalar(@positive_seqs_prior_probability_vec)) or die "length of num_of_sequences_in_the_world_vec and positive_seqs_prior_probability_vec not equal\n";
my $train_modes = scalar(@num_of_sequences_in_the_world_vec);


#my @train_true_model_sample_num_vec = ( 500);
#my @train_background_sample_num_vec = (4500);
#my @sum_weights_penalty_coefficient_vec = (0.1);



my ($models_files_names_vec_ptr,$models_position_nums_vec_ptr,$l_at_pos_feature_max_pos_num_vec_ptr) = &ParseModelsFile($models_dir."/".$models_file);
my @models_files_names_vec = @$models_files_names_vec_ptr;
my @models_position_nums_vec = @$models_position_nums_vec_ptr;
my @l_at_pos_feature_max_pos_num_vec = @$l_at_pos_feature_max_pos_num_vec_ptr;

print @models_files_names_vec;
print "\n";
print @models_position_nums_vec;
print "\n";
print @l_at_pos_feature_max_pos_num_vec;
print "\n";

#my @models_files_names_vec = ("synthetic_true_model_4nt_v2.gxw");
#my @models_position_nums_vec = (4);
#my @l_at_pos_feature_max_pos_num_vec = (2);

(scalar(@models_files_names_vec) == scalar(@models_position_nums_vec)) or die "error in parse of models file vecs not equual len 1";
(scalar(@models_files_names_vec) == scalar(@l_at_pos_feature_max_pos_num_vec)) or die "error in parse of models file vecs not equual len 2";
my $num_of_models = scalar(@models_files_names_vec);
print "num of models:$num_of_models\n"; 


# creating the xml generation 
my $create_synthetic_test_data_exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/create_synthetic_data_and_update_Z.map");
my $create_data_and_model_exec_str      = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/create_synthetic_data.map");
my $learn_and_compare_exec_str          = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/learn_syntethic_data_and_compare_2_true_model.map");

# run params array
my @run_dirs_vec;
my @run_models_files_vec;
my @run_models_nums_vec;
my @run_models_position_nums_vec;
my @run_models_l_at_pos_feature_max_pos_vec;
my @run_train_true_model_sample_num_vec;
my @run_train_background_sample_num_vec;
my @run_sum_weights_penalty_coefficient_vec;
my @repeat_num_vec;
my @run_num_vec;
my @run_num_of_sequences_in_the_world_vec;
my @run_positive_seqs_prior_probability_vec;

# exec strings array
my @bind_create_test_data_exec_strs_vec;
my @bind_create_data_and_model_exec_strs_vec;
my @bind_learn_and_compare_exec_strs_vec;

my @create_syntethic_test_data_exec_strs_vec;
my @copy_syntethic_test_data_exec_strs_vec;
my @create_data_and_model_exec_strs_vec;
my @learn_and_compare_exec_strs_vec;
my @delete_syntethic_test_data_exec_strs_vec;
#TODO - improve - make safer if dir exists - delete
# make test data files directory

if (!( (-e $test_files_dir) && (-d $test_files_dir) ))
{
	system("mkdir $test_files_dir");
}

if (!( (-e $output_dir) && (-d $output_dir) ))
{
	system("mkdir $output_dir");
}


my $cur_run_dir_name;

my $run_num = 0;
my $model_and_data_num = 0;

for (my $m = 0; $m < $num_of_models ; ++$m)   
{
	print STDOUT "%%%%%%%%%%%%%%%%%%%%%%%%%% started model $m (run:$run_num) %%%%%%%%%%%%%%%%%%%%%%%%%%\n";


	my $cur_true_model_matrix_file = $models_files_names_vec[$m];
	my $cur_models_position_nums   = $models_position_nums_vec[$m];
	my $cur_l_at_pos_feature_max_pos_num   = $l_at_pos_feature_max_pos_num_vec[$m];
	
	print STDOUT "cur_true_model_matrix_file:$cur_true_model_matrix_file\n";
	print STDOUT "cur_models_position_nums:$cur_models_position_nums\n";
	print STDOUT "cur_l_at_pos_feature_max_pos_num:$cur_l_at_pos_feature_max_pos_num\n";

	# file names
	my $cur_updated_z_true_model_file_name = $UPDATED_Z_TRUE_MODEL_FILE_NAME_PREFIX . $MODEL_FILE_SUFFIX  . "$m" . $MODEL_FILE_TYPE_SUFFIX;
	
	
	my $cur_create_synthetic_test_data_exec_str = $create_synthetic_test_data_exec_str;
	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("BACKGROUND_MATRIX_FILE",$background_matrix_file);
	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("TRUE_MODEL_MATRIX_FILE",$cur_true_model_matrix_file);
	
	my $cur_test_output_file_prefix = $TEST_OUTPUT_FILE_PREFIX_PREFIX . $MODEL_TEST_SUFFIX ."$m";
	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("OUTPUT_FILE_PREFIX",$cur_test_output_file_prefix);
	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("DATA_NAME_PREFIX",$TEST_DATA_NAME_PREFIX);
	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("EXHAUSTIVE_MODEL_SAMPLING_NUM_OF_SAMPLES_FROM_BACKGROUND",$TEST_BACKGROUND_SAMPLE_NUM);

	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("EXHAUSTIVE_MODEL_SAMPLING_NUM_OF_SAMPLES_FROM_TRUE_MODEL",$TEST_TRUE_MODEL_SAMPLE_NUM);
	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("UPDATED_Z_TRUE_MODEL_FILE_NAME",$cur_updated_z_true_model_file_name);

	$cur_create_synthetic_test_data_exec_str .= &AddStringProperty("ALLSEQS_DATA_NAME_PREFIX","SyntheticDataTestAll");
	 


	$create_syntethic_test_data_exec_strs_vec[$m] = "cd $test_files_dir; $ENV{GENIE_EXE} $CREATE_SYNTHETIC_TEST_DATA_MAP_FILE_NAME_PREFIX$m.map; cd .."; 




	$bind_create_test_data_exec_strs_vec[$m] = "$cur_create_synthetic_test_data_exec_str | sed 's/$space/ /g' > $test_files_dir/$CREATE_SYNTHETIC_TEST_DATA_MAP_FILE_NAME_PREFIX$m.map";

	system("cp  $models_dir/$background_matrix_file $test_files_dir/$background_matrix_file;");
	system("cp  $models_dir/$cur_true_model_matrix_file $test_files_dir/$cur_true_model_matrix_file;");
	
	foreach (my $r = 0; $r < $repeat_num ; ++$r)
	{
		foreach my $train_true_model_sample_num (@train_true_model_sample_num_vec)
		{
		   foreach my $train_background_sample_num (@train_background_sample_num_vec)
		   {
				print STDOUT "^^^^^^^^^^^^^^^^^^^^^^^^ started new run - model:$m, model_and_data_num:$model_and_data_num, run:$run_num ^^^^^^^^^^^^^^^^^^^^^^^^\n";

				$cur_run_dir_name = $run_dirs_prefix . $RUN_DIRS_SUFFIX . $model_and_data_num;
				
				print STDOUT "cur_run_dir_name:$cur_run_dir_name\n";
				
				# generate: create_data_and_model_exec_str

				my $cur_create_data_and_model_exec_str = $create_data_and_model_exec_str;
				
				$cur_create_data_and_model_exec_str .= &AddStringProperty("BACKGROUND_MATRIX_FILE",$background_matrix_file);
				$cur_create_data_and_model_exec_str .= &AddStringProperty("TRUE_MODEL_MATRIX_FILE",$cur_updated_z_true_model_file_name);
				$cur_create_data_and_model_exec_str .= &AddStringProperty("EXHAUSTIVE_MODEL_SAMPLING_NUM_OF_SAMPLES_FROM_BACKGROUND",$train_background_sample_num);
				$cur_create_data_and_model_exec_str .= &AddStringProperty("EXHAUSTIVE_MODEL_SAMPLING_NUM_OF_SAMPLES_FROM_TRUE_MODEL",$train_true_model_sample_num);
				$cur_create_data_and_model_exec_str .= &AddStringProperty("DATA_NAME_PREFIX",$TRAIN_DATA_NAME_PREFIX);

				$cur_create_data_and_model_exec_str .= &AddStringProperty("OUTPUT_FILE_PREFIX",$TRAIN_OUTPUT_FILE_PREFIX_PREFIX);


				$cur_create_data_and_model_exec_str .= &AddStringProperty("ALLSEQS_OUTPUT_FILES_PREFIX",$ALL_OUTPUT_FILE_PREFIX_PREFIX);

				$cur_create_data_and_model_exec_str .= &AddStringProperty("ALLSEQS_DATA_NAME_PREFIX",$ALL_DATA_NAME_PREFIX);

				$cur_create_data_and_model_exec_str .= &AddStringProperty("POSITIVE_OUTPUT_FILES_PREFIX",$POSITIVE_OUTPUT_FILE_PREFIX_PREFIX );

				$cur_create_data_and_model_exec_str .= &AddStringProperty("POSITIVE_DATA_NAME_PREFIX",$POSITIVE_DATA_NAME_PREFIX);
				
				


				$bind_create_data_and_model_exec_strs_vec[$model_and_data_num] =  "$cur_create_data_and_model_exec_str | sed 's/$space/ /g' > $cur_run_dir_name/$CREATE_DATA_AND_MODEL_MAP_FILE_NAME";
				
				print "$cur_create_data_and_model_exec_str\n\n";
				
				
				
				$copy_syntethic_test_data_exec_strs_vec[$model_and_data_num] = "";
				$copy_syntethic_test_data_exec_strs_vec[$model_and_data_num] .= "cp ./$test_files_dir/$cur_test_output_file_prefix.fa ./$cur_run_dir_name/$TEST_OUTPUT_FILE_PREFIX_PREFIX.fa; ";
				$copy_syntethic_test_data_exec_strs_vec[$model_and_data_num] .= "cp ./$test_files_dir/$cur_test_output_file_prefix.alignment ./$cur_run_dir_name/$TEST_OUTPUT_FILE_PREFIX_PREFIX.alignment; ";
				$copy_syntethic_test_data_exec_strs_vec[$model_and_data_num] .= "cp ./$test_files_dir/$cur_test_output_file_prefix.labels ./$cur_run_dir_name/$TEST_OUTPUT_FILE_PREFIX_PREFIX.labels; ";
                                $copy_syntethic_test_data_exec_strs_vec[$model_and_data_num] .= "cp ./$test_files_dir/$cur_updated_z_true_model_file_name ./$cur_run_dir_name/$cur_updated_z_true_model_file_name; ";


				
				$delete_syntethic_test_data_exec_strs_vec[$model_and_data_num] = "";
				$delete_syntethic_test_data_exec_strs_vec[$model_and_data_num] .= "rm ./$cur_run_dir_name/$TEST_OUTPUT_FILE_PREFIX_PREFIX.fa; ";
				$delete_syntethic_test_data_exec_strs_vec[$model_and_data_num] .= "rm ./$cur_run_dir_name/$TEST_OUTPUT_FILE_PREFIX_PREFIX.alignment; ";
				$delete_syntethic_test_data_exec_strs_vec[$model_and_data_num] .= "rm ./$cur_run_dir_name/$TEST_OUTPUT_FILE_PREFIX_PREFIX.labels; ";
				
				$create_data_and_model_exec_strs_vec[$model_and_data_num] = "cd $cur_run_dir_name; $ENV{GENIE_EXE} $CREATE_DATA_AND_MODEL_MAP_FILE_NAME; cd ..;";
				#TODO - improve - make safer if dir exists - delete
				if (!( (-e $cur_run_dir_name) && (-d $cur_run_dir_name) ))
				{
					system("mkdir $cur_run_dir_name");
				}

				
				system("cp  $models_dir/$background_matrix_file $cur_run_dir_name/$background_matrix_file;");
				#system("cp  $models_dir/$cur_true_model_matrix_file $cur_run_dir_name/$cur_true_model_matrix_file;");
				
				
				for (my $t = 0; $t < $train_modes ; ++$t)
				{
					my $num_of_sequences_in_the_world   = $num_of_sequences_in_the_world_vec[$t];
					my $positive_seqs_prior_probability = $positive_seqs_prior_probability_vec[$t];
					
					foreach my $sum_weights_penalty_coefficient (@sum_weights_penalty_coefficient_vec)
					{
						# out file names
						my $cur_learn_feature_weight_output_file                      =$LEARN_FEATURE_WEIGHT_OUTPUT_FILE . $RUN_FILE_SUFFIX . "$run_num" . $MODEL_FILE_TYPE_SUFFIX;
						my $cur_updated_z_learn_feature_weight_output_file            =$UPDATED_Z_LEARN_FEATURE_WEIGHT_OUTPUT_FILE . $RUN_FILE_SUFFIX . "$run_num" . $MODEL_FILE_TYPE_SUFFIX;
						my $cur_un_learned_mypssm_file_name                           =$UN_LEARNED_MYPSSM_FILE_NAME . $RUN_FILE_SUFFIX . "$run_num" . $MODEL_FILE_TYPE_SUFFIX;
						my $cur_mypssm_model_file_name                                =$MYPSSM_MODEL_FILE_NAME . $RUN_FILE_SUFFIX . "$run_num" . $MODEL_FILE_TYPE_SUFFIX;
						my $cur_updated_z_learn_mypssm_output_file                    =$UPDATED_Z_LEARN_MYPSSM_OUTPUT_FILE . $RUN_FILE_SUFFIX . "$run_num" . $MODEL_FILE_TYPE_SUFFIX;
						my $cur_pssm_model_file_name                                  =$PSSM_MODEL_FILE_NAME . $RUN_FILE_SUFFIX . "$run_num" . $MODEL_FILE_TYPE_SUFFIX;
						my $cur_learn_feature_weight_estimator_output_file            =$LEARN_FEATURE_WEIGHT_ESTIMATOR_OUTPUT_FILE . $RUN_FILE_SUFFIX . "$run_num" . $ESTIMATOR_FILE_TYPE_SUFFIX;
						my $cur_learn_feature_weight_feature_stat_output_file         =$LEARN_FEATURE_WEIGHT_FEATURE_STAT_OUTPUT_FILE . $RUN_FILE_SUFFIX . "$run_num" . $FEATURE_STAT_FILE_TYPE_SUFFIX;
						my $cur_learn_feature_weight_matlab_output_file_name          =$LEARN_FEATURE_WEIGHT_MATLAB_OUTPUT_FILE_NAME . $RUN_FILE_SUFFIX . "$run_num" . $MATLAB_FILE_TYPE_SUFFIX;
						my $cur_learn_mypssm_estimator_output_file                    =$LEARN_MYPSSM_ESTIMATOR_OUTPUT_FILE . $RUN_FILE_SUFFIX . "$run_num" . $ESTIMATOR_FILE_TYPE_SUFFIX;
						my $cur_learn_mypssm_matlab_output_file_name                  =$LEARN_MYPSSM_MATLAB_OUTPUT_FILE_NAME . $RUN_FILE_SUFFIX . "$run_num" . $MATLAB_FILE_TYPE_SUFFIX;
						my $cur_learn_pssm_estimator_output_file                      =$LEARN_PSSM_ESTIMATOR_OUTPUT_FILE . $RUN_FILE_SUFFIX . "$run_num" . $ESTIMATOR_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_train_true_model               =$LIKELIHOOD_OUTPUT_FILE_TRAIN_TRUE_MODEL . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_train_learned_feature_weight   =$LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_FEATURE_WEIGHT . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_train_learned_mypssm           =$LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_MYPSSM . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_train_learned_pssm             =$LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_PSSM . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_test_true_model                =$LIKELIHOOD_OUTPUT_FILE_TEST_TRUE_MODEL . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_test_learned_feature_weight    =$LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_FEATURE_WEIGHT . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_test_learned_mypssm            =$LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_MYPSSM . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_likelihood_output_file_test_learned_pssm              =$LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_PSSM . $RUN_FILE_SUFFIX . "$run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
						my $cur_compare_matrices_output_file_learned_feature_weight   =$COMPARE_MATRICES_OUTPUT_FILE_LEARNED_FEATURE_WEIGHT . $RUN_FILE_SUFFIX . "$run_num" . $MAT_COMPARE_FILE_TYPE_SUFFIX;
						my $cur_compare_matrices_output_file_learned_mypssm           =$COMPARE_MATRICES_OUTPUT_FILE_LEARNED_MYPSSM . $RUN_FILE_SUFFIX . "$run_num" . $MAT_COMPARE_FILE_TYPE_SUFFIX;
						my $cur_compare_matrices_output_file_learned_pssm             =$COMPARE_MATRICES_OUTPUT_FILE_LEARNED_PSSM . $RUN_FILE_SUFFIX . "$run_num" . $MAT_COMPARE_FILE_TYPE_SUFFIX;

						print STDOUT "DEBUG: in binding to xml cur_likelihood_output_file_train_true_model:$cur_likelihood_output_file_train_true_model\n";
						# generate: create_data_and_model_exec_str
						my $cur_learn_and_compare_exec_str = $learn_and_compare_exec_str;

						$cur_learn_and_compare_exec_str .= &AddStringProperty("PSSM_PSEUDO_COUNTS",$PSSM_PSEUDO_COUNTS);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("BACKGROUND_MATRIX_FILE",$background_matrix_file); 
						$cur_learn_and_compare_exec_str .= &AddStringProperty("UPDATED_Z_TRUE_MODEL_FILE_NAME",$cur_updated_z_true_model_file_name); 

						$cur_learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_OUTPUT_FILE",$cur_learn_feature_weight_output_file); 
						$cur_learn_and_compare_exec_str .= &AddStringProperty("UPDATED_Z_LEARN_FEATURE_WEIGHT_OUTPUT_FILE",$cur_updated_z_learn_feature_weight_output_file); 
						$cur_learn_and_compare_exec_str .= &AddStringProperty("UN_LEARNED_MYPSSM_FILE_NAME",$cur_un_learned_mypssm_file_name); 
						$cur_learn_and_compare_exec_str .= &AddStringProperty("MYPSSM_MODEL_FILE_NAME",$cur_mypssm_model_file_name); 
						$cur_learn_and_compare_exec_str .= &AddStringProperty("UPDATED_Z_LEARN_MYPSSM_OUTPUT_FILE",$cur_updated_z_learn_mypssm_output_file); 
						$cur_learn_and_compare_exec_str .= &AddStringProperty("PSSM_MODEL_FILE_NAME",$cur_pssm_model_file_name); 
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_ESTIMATOR_OUTPUT_FILE",$cur_learn_feature_weight_estimator_output_file);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_FEATURE_STAT_OUTPUT_FILE",$cur_learn_feature_weight_feature_stat_output_file);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LEARN_FEATURE_WEIGHT_MATLAB_OUTPUT_FILE_NAME",$cur_learn_feature_weight_matlab_output_file_name);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("LETTERS_AT_POSITION_FEATURE_MAX_POSITIONS_NUM",$cur_l_at_pos_feature_max_pos_num);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("SUM_WEIGHTS_PENALTY_COEFFICIENT",$sum_weights_penalty_coefficient);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("WEIGHT_MATRIX_POSITIONS_NUM",$cur_models_position_nums);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("LEARN_MYPSSM_ESTIMATOR_OUTPUT_FILE",$cur_learn_mypssm_estimator_output_file);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LEARN_MYPSSM_MATLAB_OUTPUT_FILE_NAME",$cur_learn_mypssm_matlab_output_file_name);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("LEARN_PSSM_ESTIMATOR_OUTPUT_FILE",$cur_learn_pssm_estimator_output_file);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TRAIN_TRUE_MODEL",$cur_likelihood_output_file_train_true_model);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_FEATURE_WEIGHT",$cur_likelihood_output_file_train_learned_feature_weight);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_MYPSSM",$cur_likelihood_output_file_train_learned_mypssm);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_PSSM",$cur_likelihood_output_file_train_learned_pssm);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TEST_TRUE_MODEL",$cur_likelihood_output_file_test_true_model);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_FEATURE_WEIGHT",$cur_likelihood_output_file_test_learned_feature_weight);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_MYPSSM",$cur_likelihood_output_file_test_learned_mypssm);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_PSSM",$cur_likelihood_output_file_test_learned_pssm);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("COMPARE_MATRICES_OUTPUT_FILE_LEARNED_FEATURE_WEIGHT",$cur_compare_matrices_output_file_learned_feature_weight);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("COMPARE_MATRICES_OUTPUT_FILE_LEARNED_MYPSSM",$cur_compare_matrices_output_file_learned_mypssm);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("COMPARE_MATRICES_OUTPUT_FILE_LEARNED_PSSM",$cur_compare_matrices_output_file_learned_pssm);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("NUM_OF_SEQUENCES_IN_THE_WORLD",$num_of_sequences_in_the_world);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("POSITIVE_SEQS_PRIOR_PROBABILITY",$positive_seqs_prior_probability);
						
						
						$cur_learn_and_compare_exec_str .= &AddStringProperty("FEATURE_FUNCTION_TYPE_TOKEN",$FEATURE_FUNCTION_TYPE_TOKEN);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("FEATURE_SELECTION_METHOD_TYPE_TOKEN",$FEATURE_SELECTION_METHOD_TYPE_TOKEN);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("FEATURE_EXPECTATION_ESTIMATION_METHOD_TYPE_TOKEN",$FEATURE_EXPECTATION_ESTIMATION_METHOD_TYPE_TOKEN);

						$cur_learn_and_compare_exec_str .= &AddStringProperty("STRUCTURE_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT",$sum_weights_penalty_coefficient);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("PARAMETERS_LEARNING_SUM_WEIGHTS_PENALTY_COEFFICIENT",$sum_weights_penalty_coefficient);

					
						$cur_learn_and_compare_exec_str .= &AddStringProperty("INIT_FMM_BY_FIRST_LEARNING_PSSM",$init_fmm_by_first_learning_pssm);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("LETTERS_AT_MULTIPLE_POSITIONS_BINOMIAL_FILTER_FDR_THRESH",$letters_at_multiple_positions_binomial_filter_fdr_thresh);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("MAX_FEATURES_PARAMETERS_NUM",$max_features_parameters_num);
						$cur_learn_and_compare_exec_str .= &AddStringProperty("MAX_LEARNING_ITERATIONS_NUM",$max_learning_iterations_num);


						
						# updating the run parameters vec
						$run_dirs_vec[$run_num]                            = $cur_run_dir_name;
						$run_models_files_vec[$run_num]                    = $cur_true_model_matrix_file;
						$run_models_nums_vec[$run_num]                     = $m;
						$run_models_position_nums_vec[$run_num]            = $cur_models_position_nums;
						$run_models_l_at_pos_feature_max_pos_vec[$run_num] = $cur_l_at_pos_feature_max_pos_num;
						$run_train_true_model_sample_num_vec[$run_num]     = $train_true_model_sample_num;
						$run_train_background_sample_num_vec[$run_num]     = $train_background_sample_num;
						$run_sum_weights_penalty_coefficient_vec[$run_num] = $sum_weights_penalty_coefficient;
						$repeat_num_vec[$run_num]                          = $r;
						$run_num_vec[$run_num]                             = $run_num;
						$run_num_of_sequences_in_the_world_vec[$run_num]   = $num_of_sequences_in_the_world;
						$run_positive_seqs_prior_probability_vec[$run_num] = $positive_seqs_prior_probability;

						$bind_learn_and_compare_exec_strs_vec[$run_num] = "$cur_learn_and_compare_exec_str | sed 's/$space/ /g' > $cur_run_dir_name/$LEARN_AND_COMPARE_MAP_FILE_NAME$run_num$MAP_FILE_TYPE_SUFFIX ";

						$learn_and_compare_exec_strs_vec[$run_num] = "cd $cur_run_dir_name; $ENV{GENIE_EXE} $LEARN_AND_COMPARE_MAP_FILE_NAME$run_num$MAP_FILE_TYPE_SUFFIX; cd ..;";
						
						
						++$run_num;
					}
				}
				
				++$model_and_data_num;
		   }
		}
	}
}

# write exec strings 
print STDOUT "----------------------- start write exec strings  -------------------------------------------------------------------------\n";

my @exec_strs_array_of_arrays;
my @exec_strs_arrays_names;

push(@exec_strs_array_of_arrays, \@bind_create_test_data_exec_strs_vec);
push(@exec_strs_arrays_names, "bind_create_test_data_exec_strs_vec");

push(@exec_strs_array_of_arrays, \@create_syntethic_test_data_exec_strs_vec);
push(@exec_strs_arrays_names, "create_syntethic_test_data_exec_strs_vec");

push(@exec_strs_array_of_arrays, \@copy_syntethic_test_data_exec_strs_vec);
push(@exec_strs_arrays_names, "copy_syntethic_test_data_exec_strs_vec");

push(@exec_strs_array_of_arrays, \@bind_create_data_and_model_exec_strs_vec);
push(@exec_strs_arrays_names, "bind_create_data_and_model_exec_strs_vec");

push(@exec_strs_array_of_arrays, \@bind_learn_and_compare_exec_strs_vec);
push(@exec_strs_arrays_names, "bind_learn_and_compare_exec_strs_vec");

push(@exec_strs_array_of_arrays, \@create_data_and_model_exec_strs_vec);
push(@exec_strs_arrays_names, "create_data_and_model_exec_strs_vec");

push(@exec_strs_array_of_arrays, \@learn_and_compare_exec_strs_vec);
push(@exec_strs_arrays_names, "learn_and_compare_exec_strs_vec");

push(@exec_strs_array_of_arrays, \@delete_syntethic_test_data_exec_strs_vec);
push(@exec_strs_arrays_names, "delete_syntethic_test_data_exec_strs_vec");

my $exec_strs_output_file_path = $output_dir."/" .$exec_strs_output_file;
&WriteExecStrs(\@exec_strs_array_of_arrays,\@exec_strs_arrays_names,$exec_strs_output_file_path);

print STDOUT "----------------------- end write exec strings  -------------------------------------------------------------------------\n";

# write run parameters
print STDOUT "--------------------- start write run parameters -------------------------------------------------------------------------\n";

my @output_array_of_col_arrays;
my @output_col_arrays_names;

push(@output_array_of_col_arrays, \@run_num_vec);
push(@output_col_arrays_names, "run_num");

push(@output_array_of_col_arrays, \@run_dirs_vec);
push(@output_col_arrays_names, "dirs");

push(@output_array_of_col_arrays, \@run_models_files_vec);
push(@output_col_arrays_names, "models_files");

push(@output_array_of_col_arrays, \@run_models_nums_vec);
push(@output_col_arrays_names, "models_nums");

push(@output_array_of_col_arrays, \@repeat_num_vec);
push(@output_col_arrays_names, "repeat_num");

push(@output_array_of_col_arrays, \@run_models_position_nums_vec);
push(@output_col_arrays_names, "models_position_nums");

push(@output_array_of_col_arrays, \@run_models_l_at_pos_feature_max_pos_vec);
push(@output_col_arrays_names, "models_l_at_pos_feature_max_pos");

push(@output_array_of_col_arrays, \@run_train_true_model_sample_num_vec);
push(@output_col_arrays_names, "train_true_model_sample_num");

push(@output_array_of_col_arrays, \@run_train_background_sample_num_vec);
push(@output_col_arrays_names, "train_background_sample_num");

push(@output_array_of_col_arrays, \@run_sum_weights_penalty_coefficient_vec);
push(@output_col_arrays_names, "sum_weights_penalty_coefficient");

push(@output_array_of_col_arrays, \@run_num_of_sequences_in_the_world_vec);
push(@output_col_arrays_names, "num_of_sequences_in_the_world");

push(@output_array_of_col_arrays, \@run_positive_seqs_prior_probability_vec);
push(@output_col_arrays_names, "positive_seqs_prior_probability");

my $output_run_prarams_file_path = $output_dir."/" .$output_run_prarams_file;
&WriteTabularFileOfColumnArrays(\@output_array_of_col_arrays,\@output_col_arrays_names,$output_run_prarams_file_path);

print STDOUT "----------------------- end write run parameters -------------------------------------------------------------------------\n";

if ($fix_not_run_mode != 1)
{
	# bind generate test data files
	print STDOUT "-------------------- run_parallel_q_processes: bind_create_test_data_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@bind_create_test_data_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "-------------- end run_parallel_q_processes: bind_create_test_data_exec_strs_vec ------------------------------------\n\n";

	# generate test data files
	print STDOUT "--------------- run_parallel_q_processes: create_syntethic_test_data_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@create_syntethic_test_data_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "------------- end run_parallel_q_processes: create_syntethic_test_data_exec_strs_vec ------------------------------------\n\n";
}
else
{
	print STDOUT "------------ RUN IN FIX MODE - skipped bind_create_test_data_exec_strs_vec       ---------\n\n";
	print STDOUT "------------ RUN IN FIX MODE - skipped create_syntethic_test_data_exec_strs_vec  ---------\n\n";
}
	
	
if ($no_need_to_copy_test_files != 1)
{
	#copy test data files to run dirs
	print STDOUT "----------------- run_parallel_q_processes: copy_syntethic_test_data_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@copy_syntethic_test_data_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "--------------- end run_parallel_q_processes: copy_syntethic_test_data_exec_strs_vec ------------------------------------\n\n";
}

if ($fix_not_run_mode != 1)
{
	# bind generate train data files
	print STDOUT "--------------- run_parallel_q_processes: bind_create_data_and_model_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@bind_create_data_and_model_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "------------- end run_parallel_q_processes: bind_create_data_and_model_exec_strs_vec ------------------------------------\n\n";
	
	# bind learn and compare
	print STDOUT "------------------- run_parallel_q_processes: bind_learn_and_compare_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@bind_learn_and_compare_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "----------------- end run_parallel_q_processes: bind_learn_and_compare_exec_strs_vec ------------------------------------\n\n";

	# generate train data files
	print STDOUT "-------------------- run_parallel_q_processes: create_data_and_model_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@create_data_and_model_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "------------------ end run_parallel_q_processes: create_data_and_model_exec_strs_vec ------------------------------------\n\n";
}
else
{
	print STDOUT "------------ RUN IN FIX MODE - skipped bind_create_data_and_model_exec_strs_vec  --------------\n\n";
	print STDOUT "------------ RUN IN FIX MODE - skipped bind_learn_and_compare_exec_strs_vec      --------------\n\n";
	print STDOUT "------------ RUN IN FIX MODE - skipped create_data_and_model_exec_strs_vec       --------------\n\n";
}

if ($fix_not_run_mode != 1)
{
	# learn and compare
	print STDOUT "------------------------ run_parallel_q_processes: learn_and_compare_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@learn_and_compare_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "---------------------- end run_parallel_q_processes: learn_and_compare_exec_strs_vec ------------------------------------\n\n";
}
else
{
	print STDOUT "------------ RUN IN FIX MODE - start collecting data which was not run  --------------\n\n";
	my $rerun_indecis_ptr =  &CollectWhichWereNotLearned(\@run_num_vec,\@run_dirs_vec);
	print STDOUT "------------ RUN IN FIX MODE - start collecting data which was not run  --------------\n\n";
	my @rerun_indecis = @$rerun_indecis_ptr;
	my $num_of_reruns = scalar(@rerun_indecis);
	print STDOUT "Need To Fix: $num_of_reruns runs\n";
	my $rerun_learn_and_compare_exec_strs_vec_ptr = GetSubVec(\@learn_and_compare_exec_strs_vec,\@rerun_indecis);
	my @rerun_learn_and_compare_exec_strs_vec = @$rerun_learn_and_compare_exec_strs_vec_ptr;
	my $length_of_reruns_vec = scalar(@rerun_learn_and_compare_exec_strs_vec);
	print STDOUT "ReRun vec Size: $length_of_reruns_vec runs\n";
	print STDOUT "------------ RUN IN FIX MODE - start run rerun_learn_and_compare_exec_strs_vec --------------\n\n";
	&run_parallel_q_processes(\@rerun_learn_and_compare_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "------------ RUN IN FIX MODE - end run rerun_learn_and_compare_exec_strs_vec --------------\n\n";
	
}

#delete test files from run dirs delete_test_files
if ($delete_test_files != 0)
{
	print STDOUT "--------------- run_parallel_q_processes: delete_syntethic_test_data_exec_strs_vec ----------------------------------------\n";
	&run_parallel_q_processes(\@delete_syntethic_test_data_exec_strs_vec, $processes_num, $num_of_sec_between_q_monitoring, $is_delete_tmp_file, $max_queue_length,$max_user_processes,$min_free_processes);
	print STDOUT "---------------------- end run_parallel_q_processes: learn_and_compare_exec_strs_vec ------------------------------------\n\n";
}
else
{
	print STDOUT "--------------- NOT DELETING TEST FILES FROM RUNNING DIRS -------------------------------------------------------------\n";
}

# collect data
print STDOUT "--------------------------- start collect data  -------------------------------------------------------------------------\n";

my ($run_results_array_of_arrays_ptrs_ptr, $run_results_headers_ptr) = &CollectResults(\@run_num_vec,\@run_dirs_vec);
my @run_results_array_of_arrays_ptrs = @$run_results_array_of_arrays_ptrs_ptr;
my @run_results_headers = @$run_results_headers_ptr;
print STDOUT "------------------------------- end collect data  -------------------------------------------------------------------------\n";


# write output
print STDOUT "------------------------------ start write output -------------------------------------------------------------------------\n";

push(@output_array_of_col_arrays, @run_results_array_of_arrays_ptrs);
push(@output_col_arrays_names, @run_results_headers);

my $output_file_path = $output_dir."/" .$output_file;
print "DEBUG: writing output to: $output_file_path\n";
&WriteTabularFileOfColumnArrays(\@output_array_of_col_arrays,\@output_col_arrays_names,$output_file_path);
#&WriteTabularFileOfColumnArrays(\@run_results_array_of_arrays_ptrs,\@run_results_headers,$output_file_path);
print STDOUT "------------------------------- end write output  -------------------------------------------------------------------------\n";


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub GetSubVec
{
	my ($subvec_org_vec_ptr,$subvec_indecis_ptr) = @_;
	
	my @subvec_org_vec = @$subvec_org_vec_ptr;
	my @subvec_indecis = @$subvec_indecis_ptr;
	
	my $num_of_sub_indecis = scalar(@subvec_indecis);
	
	my @ret_vec;
	
	foreach my $index (@subvec_indecis)
	{
		push(@ret_vec, $subvec_org_vec[$index]);
	}
	
	return \@ret_vec;
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub CollectLikelihoodResultsFromFile
{
	my ($likelihood_file_path) = @_;
	
	print "DEBUG: CollectLikelihoodResultsFromFile from:$likelihood_file_path\n";
	my $likelihood_all;
	my $likelihood_seqs_num;
	my $likelihood_average;
	my $positive_likelihood_all;
	my $positive_likelihood_seqs_num;
	my $positive_likelihood_average;
	
	open(INLIKELIHOODFILE, $likelihood_file_path) or die "CollectLikelihoodResultsFromFile could not open out file: $likelihood_file_path\n";
	my $line = <INLIKELIHOODFILE>;
	#my $line = $_;
	print "line:$line\n";
	chomp($line);
	print "line:$line\n";
	my $line_start;
	my $line_end;
	($line_start, $line_end) = split(/:/, $line,2);
	print "line_start:$line_start\n";
	print "line_end:$line_end\n";
	($likelihood_all,$likelihood_seqs_num,$likelihood_average) = split(/\|/, $line_end,3);
	print "likelihood_all:$likelihood_all\n";
	print "likelihood_seqs_num:$likelihood_seqs_num\n";
	print "likelihood_average:$likelihood_average\n";
	$line = <INLIKELIHOODFILE>;
	chomp($line);
	my $line_start;
	my $line_end;
	($line_start, $line_end) = split(/:/, $line,2);
	print "line_start:$line_start\n";
	print "line_end:$line_end\n";
	($positive_likelihood_all,$positive_likelihood_seqs_num,$positive_likelihood_average) = split(/\|/, $line_end,3);
	print "positive_likelihood_all:$positive_likelihood_all\n";
	print "positive_likelihood_seqs_num:$positive_likelihood_seqs_num\n";
	print "positive_likelihood_average:$positive_likelihood_average\n";
	close(INLIKELIHOODFILE);
	print "DEBUG: CollectLikelihoodResultsFromFile return:$likelihood_all,$likelihood_seqs_num,$likelihood_average,$positive_likelihood_all,$positive_likelihood_seqs_num,$positive_likelihood_average\n";
	return ($likelihood_all,$likelihood_seqs_num,$likelihood_average,$positive_likelihood_all,$positive_likelihood_seqs_num,$positive_likelihood_average);
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub CollectKLDistanceResultsFromFile
{
	my ($KL_distance_file_path) = @_;
	
	print "DEBUG: CollectKLDistanceResultsFromFile from:$KL_distance_file_path\n";

	open(INKLFILE, $KL_distance_file_path) or die "CollectKLDistanceResultsFromFile could not open out file: $KL_distance_file_path\n";
	my $line = <INKLFILE>;
	chomp($line);
	my $line_start;
	my $KL_distance;
	($line_start, $KL_distance) = split(/:/, $line,2);
	close(INKLFILE);
	print "DEBUG: CollectKLDistanceResultsFromFile return:$KL_distance\n";
	return $KL_distance;
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub PushValuesToVecs
{
	print "DEBUG: PushValuesToVecs\n";
	my ($push_to_vecs_vecs_ptrs_ptr, $push_to_vecs_values_ptr) = @_;
	
	my @push_to_vecs_vecs_ptrs = @$push_to_vecs_vecs_ptrs_ptr;
	my @push_to_vecs_values    = @$push_to_vecs_values_ptr;
	
	if (scalar(@push_to_vecs_vecs_ptrs) !=  scalar(@push_to_vecs_values))
	{
		print STDERR "length of push_to_vecs_vecs_ptrs and push_to_vecs_values not equal!\n";
	}
	
	my $push_to_vecs_vecs_num = scalar(@push_to_vecs_vecs_ptrs);
	if ($push_to_vecs_vecs_num > scalar(@push_to_vecs_values))
	{
		$push_to_vecs_vecs_num = scalar(@push_to_vecs_values);
	}
	print "DEBUG: PushValuesToVecs push_to_vecs_vecs_num: $push_to_vecs_vecs_num\n";
	
	my $push_to_vecs_cur_vec_ptr;
	my @push_to_vecs_cur_vec;
	my $push_to_vecs_cur_value;
	for (my $v=0; $v < $push_to_vecs_vecs_num; ++$v)
	{
		$push_to_vecs_cur_vec_ptr = @push_to_vecs_vecs_ptrs[$v];
		@push_to_vecs_cur_vec = @$push_to_vecs_cur_vec_ptr;
		$push_to_vecs_cur_value = @push_to_vecs_values[$v];
		
		print "DEBUG: PushValuesToVecs pushing $push_to_vecs_cur_value, to vec num: $v\n";
		
		push(@push_to_vecs_cur_vec,$push_to_vecs_cur_value);
	}
}


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub CollectWhichWereNotLearned
{
	my ($notlearned_run_num_vec_ptr,$notlearned_run_dirs_vec_ptr) = @_;
	
	my @notlearned_run_num_vec  = @$notlearned_run_num_vec_ptr;
	my @notlearned_run_dirs_vec = @$notlearned_run_dirs_vec_ptr;
	
	print "DEBUG: CollectWhichWereNotLearned notlearned_run_num_vec:@notlearned_run_num_vec\n";
	print "DEBUG: CollectWhichWereNotLearned notlearned_run_dirs_vec:@notlearned_run_dirs_vec\n";
	
	if (scalar(@notlearned_run_num_vec) != scalar(@notlearned_run_dirs_vec))
	{
		print STDERR "length of notlearned_run_num_vec and notlearned_run_dirs_vec not equal!\n";
	}
	
	my $notlearned_run_num = scalar(@notlearned_run_num_vec);
	print "DEBUG: CollectResults notlearned_run_num:$notlearned_run_num\n";
	if ($notlearned_run_num > scalar(@notlearned_run_dirs_vec))
	{
		$notlearned_run_num = scalar(@notlearned_run_dirs_vec);
	}
	print "DEBUG: CollectWhichWereNotLearned notlearned_run_num:$notlearned_run_num\n";
	
	my @notlearned_ret_indecis_vec;
	for (my $r = 0; $r < $notlearned_run_num; ++$r)
	{
		my $cur_notlearned_run_num = $notlearned_run_num_vec[$r];
		my $cur_notlearned_run_dir = $notlearned_run_dirs_vec[$r];
		
		print STDOUT "CollectWhichWereNotLearned cur_notlearned_run_num:$cur_notlearned_run_num\n";
		print STDOUT "CollectWhichWereNotLearned cur_notlearned_run_dir:$cur_notlearned_run_dir\n";


		# check for pssm KL distance which is the output of the last step
		my $TMP_notlearned_cur_file_path=$cur_notlearned_run_dir . "/" . $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_PSSM . $RUN_FILE_SUFFIX . "$cur_notlearned_run_num" . $MAT_COMPARE_FILE_TYPE_SUFFIX;
		print STDOUT "CollectWhichWereNotLearned TMP_notlearned_cur_file_path:$TMP_notlearned_cur_file_path\n";
		
		if (!(-e $TMP_notlearned_cur_file_path))
		{
			print STDOUT "CollectWhichWereNotLearned : found NOT-RUN: $cur_notlearned_run_num (in dir: $cur_notlearned_run_dir)\n";
			push(@notlearned_ret_indecis_vec, $cur_notlearned_run_num);
		}
	}
	
	return \@notlearned_ret_indecis_vec;
}


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub CollectResults
{
	my ($collect_run_num_vec_ptr, $collect_run_dirs_vec_ptr) = @_;
	my @collect_run_num_vec = @$collect_run_num_vec_ptr;
	my @collect_run_dirs_vec = @$collect_run_dirs_vec_ptr;
	
	print "DEBUG: CollectResults collect_run_num_vec:@collect_run_num_vec\n";
	print "DEBUG: CollectResults collect_run_dirs_vec:@collect_run_dirs_vec\n";
	
	if (scalar(@collect_run_num_vec) !=  scalar(@collect_run_dirs_vec))
	{
		print STDERR "length of collect_run_num_vec and collect_run_dirs_vec_ptr not equal!\n";
	}
	
	my $collect_run_num = scalar(@collect_run_num_vec);
	print "DEBUG: CollectResults collect_run_num:$collect_run_num\n";
	if ($collect_run_num > scalar(@collect_run_dirs_vec))
	{
		$collect_run_num = scalar(@collect_run_dirs_vec);
	}
	print "DEBUG: CollectResults collect_run_num:$collect_run_num\n";
	
	
	my @train_likelihood_all_true_model;
	my @train_likelihood_seqs_num_true_model;
	my @train_likelihood_average_true_model;
	my @train_positive_likelihood_all_true_model;
	my @train_positive_likelihood_seqs_num_true_model;
	my @train_positive_likelihood_average_true_model;

	my @train_likelihood_all_feature_weight;
	my @train_likelihood_seqs_num_feature_weight;
	my @train_likelihood_average_feature_weight;
	my @train_positive_likelihood_all_feature_weight;
	my @train_positive_likelihood_seqs_num_feature_weight;
	my @train_positive_likelihood_average_feature_weight;

	my @train_likelihood_all_mypssm;
	my @train_likelihood_seqs_num_mypssm;
	my @train_likelihood_average_mypssm;
	my @train_positive_likelihood_all_mypssm;
	my @train_positive_likelihood_seqs_num_mypssm;
	my @train_positive_likelihood_average_mypssm;

	my @train_likelihood_all_pssm;
	my @train_likelihood_seqs_num_pssm;
	my @train_likelihood_average_pssm;
	my @train_positive_likelihood_all_pssm;
	my @train_positive_likelihood_seqs_num_pssm;
	my @train_positive_likelihood_average_pssm;

	my @test_likelihood_all_true_model;
	my @test_likelihood_seqs_num_true_model;
	my @test_likelihood_average_true_model;
	my @test_positive_likelihood_all_true_model;
	my @test_positive_likelihood_seqs_num_true_model;
	my @test_positive_likelihood_average_true_model;

	my @test_likelihood_all_feature_weight;
	my @test_likelihood_seqs_num_feature_weight;
	my @test_likelihood_average_feature_weight;
	my @test_positive_likelihood_all_feature_weight;
	my @test_positive_likelihood_seqs_num_feature_weight;
	my @test_positive_likelihood_average_feature_weight;

	my @test_likelihood_all_mypssm;
	my @test_likelihood_seqs_num_mypssm;
	my @test_likelihood_average_mypssm;
	my @test_positive_likelihood_all_mypssm;
	my @test_positive_likelihood_seqs_num_mypssm;
	my @test_positive_likelihood_average_mypssm;

	my @test_likelihood_all_pssm;
	my @test_likelihood_seqs_num_pssm;
	my @test_likelihood_average_pssm;
	my @test_positive_likelihood_all_pssm;
	my @test_positive_likelihood_seqs_num_pssm;
	my @test_positive_likelihood_average_pssm;

	my @KL_distance_feature_weight;
	my @KL_distance_mypssm;
	my @KL_distance_pssm;




	my $cur_collect_run_dir;
	my $cur_collect_run_num;
	
	my $TMP_likelihood_all;
	my $TMP_likelihood_seqs_num;
	my $TMP_likelihood_average;
	my $TMP_positive_likelihood_all;
	my $TMP_positive_likelihood_seqs_num;
	my $TMP_positive_likelihood_average;
	my $TMP_cur_file_path;
	
	my $TMP_cur_KL_distance;



	for (my $r = 0; $r < $collect_run_num; ++$r)
	{
		$cur_collect_run_num = $collect_run_num_vec[$r];
		$cur_collect_run_dir = $collect_run_dirs_vec[$r];
		
		print STDOUT "CollectResults cur_collect_run_num:$cur_collect_run_num\n";
		print STDOUT "CollectResults cur_collect_run_dir:$cur_collect_run_dir\n";

		my $TMP_arrays_ptrs_ptr;
		my $TMP_values_ptr;
		
		my @TMP_arrays_ptrs_vec;
		my @TMP_values_vec;
		# train likelihood
		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TRAIN_TRUE_MODEL . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@train_likelihood_all_true_model,$TMP_likelihood_all);
		push (@train_likelihood_seqs_num_true_model,$TMP_likelihood_seqs_num);
		push (@train_likelihood_average_true_model ,$TMP_likelihood_average);
		push (@train_positive_likelihood_all_true_model ,$TMP_positive_likelihood_all);
		push (@train_positive_likelihood_seqs_num_true_model ,$TMP_positive_likelihood_seqs_num);
		push (@train_positive_likelihood_average_true_model ,$TMP_positive_likelihood_average);
				
		
		# @TMP_arrays_ptrs_vec = (\@train_likelihood_all_true_model,\@train_likelihood_seqs_num_true_model,\@train_likelihood_average_true_model,\@train_positive_likelihood_all_true_model,\@train_positive_likelihood_seqs_num_true_model,\@train_positive_likelihood_average_true_model);
		# $TMP_arrays_ptrs_ptr = \@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = \@TMP_values_vec;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@train_likelihood_all_true_model,\@train_likelihood_seqs_num_true_model,\@train_likelihood_average_true_model,\@train_positive_likelihood_all_true_model,\@train_positive_likelihood_seqs_num_true_model,\@train_positive_likelihood_average_true_model),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_FEATURE_WEIGHT . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@train_likelihood_all_feature_weight ,$TMP_likelihood_all);
		push (@train_likelihood_seqs_num_feature_weight ,$TMP_likelihood_seqs_num);
		push (@train_likelihood_average_feature_weight ,$TMP_likelihood_average);
		push (@train_positive_likelihood_all_feature_weight ,$TMP_positive_likelihood_all);
		push (@train_positive_likelihood_seqs_num_feature_weight ,$TMP_positive_likelihood_seqs_num);
		push (@train_positive_likelihood_average_feature_weight ,$TMP_positive_likelihood_average);
		

		# @TMP_arrays_ptrs_vec = (\@train_likelihood_all_feature_weight,\@train_likelihood_seqs_num_feature_weight,\@train_likelihood_average_feature_weight,\@train_positive_likelihood_all_feature_weight,\@train_positive_likelihood_seqs_num_feature_weight,\@train_positive_likelihood_average_feature_weight);
		# $TMP_arrays_ptrs_ptr = \@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = \@TMP_values_vec;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@train_likelihood_all_feature_weight,\@train_likelihood_seqs_num_feature_weight,\@train_likelihood_average_feature_weight,\@train_positive_likelihood_all_feature_weight,\@train_positive_likelihood_seqs_num_feature_weight,\@train_positive_likelihood_average_feature_weight),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_MYPSSM . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@train_likelihood_all_mypssm ,$TMP_likelihood_all);
		push (@train_likelihood_seqs_num_mypssm ,$TMP_likelihood_seqs_num);
		push (@train_likelihood_average_mypssm ,$TMP_likelihood_average);
		push (@train_positive_likelihood_all_mypssm ,$TMP_positive_likelihood_all);
		push (@train_positive_likelihood_seqs_num_mypssm ,$TMP_positive_likelihood_seqs_num);
		push (@train_positive_likelihood_average_mypssm ,$TMP_positive_likelihood_average);
		
		# @TMP_arrays_ptrs_vec = (\@train_likelihood_all_mypssm,\@train_likelihood_seqs_num_mypssm,\@train_likelihood_average_mypssm,\@train_positive_likelihood_all_mypssm,\@train_positive_likelihood_seqs_num_mypssm,\@train_positive_likelihood_average_mypssm);
		# $TMP_arrays_ptrs_ptr = \@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = $@;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@train_likelihood_all_mypssm,\@train_likelihood_seqs_num_mypssm,\@train_likelihood_average_mypssm,\@train_positive_likelihood_all_mypssm,\@train_positive_likelihood_seqs_num_mypssm,\@train_positive_likelihood_average_mypssm),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TRAIN_LEARNED_PSSM . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@train_likelihood_all_pssm ,$TMP_likelihood_all);
		push (@train_likelihood_seqs_num_pssm ,$TMP_likelihood_seqs_num);
		push (@train_likelihood_average_pssm ,$TMP_likelihood_average);
		push (@train_positive_likelihood_all_pssm ,$TMP_positive_likelihood_all);
		push (@train_positive_likelihood_seqs_num_pssm ,$TMP_positive_likelihood_seqs_num);
		push (@train_positive_likelihood_average_pssm ,$TMP_positive_likelihood_average);
		
		# @TMP_arrays_ptrs_vec = (\@train_likelihood_all_pssm,\@train_likelihood_seqs_num_pssm,\@train_likelihood_average_pssm,\@train_positive_likelihood_all_pssm,\@train_positive_likelihood_seqs_num_pssm,\@train_positive_likelihood_average_pssm);
		# $TMP_arrays_ptrs_ptr =\@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = \@TMP_values_vec;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@train_likelihood_all_pssm,\@train_likelihood_seqs_num_pssm,\@train_likelihood_average_pssm,\@train_positive_likelihood_all_pssm,\@train_positive_likelihood_seqs_num_pssm,\@train_positive_likelihood_average_pssm),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		# test likelihood

		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TEST_TRUE_MODEL . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@test_likelihood_all_true_model ,$TMP_likelihood_all);
		push (@test_likelihood_seqs_num_true_model ,$TMP_likelihood_seqs_num);
		push (@test_likelihood_average_true_model ,$TMP_likelihood_average);
		push (@test_positive_likelihood_all_true_model ,$TMP_positive_likelihood_all);
		push (@test_positive_likelihood_seqs_num_true_model ,$TMP_positive_likelihood_seqs_num);
		push (@test_positive_likelihood_average_true_model ,$TMP_positive_likelihood_average);
		
		# @TMP_arrays_ptrs_vec = (\@test_likelihood_all_true_model,\@test_likelihood_seqs_num_true_model,\@test_likelihood_average_true_model,\@test_positive_likelihood_all_true_model,\@test_positive_likelihood_seqs_num_true_model,\@test_positive_likelihood_average_true_model);
		# $TMP_arrays_ptrs_ptr =\@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = \@TMP_values_vec;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@test_likelihood_all_true_model,\@test_likelihood_seqs_num_true_model,\@test_likelihood_average_true_model,\@test_positive_likelihood_all_true_model,\@test_positive_likelihood_seqs_num_true_model,\@test_positive_likelihood_average_true_model),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_FEATURE_WEIGHT . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@test_likelihood_all_feature_weight ,$TMP_likelihood_all);
		push (@test_likelihood_seqs_num_feature_weight ,$TMP_likelihood_seqs_num);
		push (@test_likelihood_average_feature_weight ,$TMP_likelihood_average);
		push (@test_positive_likelihood_all_feature_weight ,$TMP_positive_likelihood_all);
		push (@test_positive_likelihood_seqs_num_feature_weight ,$TMP_positive_likelihood_seqs_num);
		push (@test_positive_likelihood_average_feature_weight ,$TMP_positive_likelihood_average);
		
		# @TMP_arrays_ptrs_vec = (\@test_likelihood_all_feature_weight,\@test_likelihood_seqs_num_feature_weight,\@test_likelihood_average_feature_weight,\@test_positive_likelihood_all_feature_weight,\@test_positive_likelihood_seqs_num_feature_weight,\@test_positive_likelihood_average_feature_weight);
		# $TMP_arrays_ptrs_ptr =\@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = \@TMP_values_vec;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@test_likelihood_all_feature_weight,\@test_likelihood_seqs_num_feature_weight,\@test_likelihood_average_feature_weight,\@test_positive_likelihood_all_feature_weight,\@test_positive_likelihood_seqs_num_feature_weight,\@test_positive_likelihood_average_feature_weight),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_MYPSSM . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@test_likelihood_all_mypssm ,$TMP_likelihood_all);
		push (@test_likelihood_seqs_num_mypssm ,$TMP_likelihood_seqs_num);
		push (@test_likelihood_average_mypssm ,$TMP_likelihood_average);
		push (@test_positive_likelihood_all_mypssm ,$TMP_positive_likelihood_all);
		push (@test_positive_likelihood_seqs_num_mypssm ,$TMP_positive_likelihood_seqs_num);
		push (@test_positive_likelihood_average_mypssm ,$TMP_positive_likelihood_average);
		
		# @TMP_arrays_ptrs_vec = (\@train_likelihood_all_mypssm,\@train_likelihood_seqs_num_mypssm,\@train_likelihood_average_mypssm,\@train_positive_likelihood_all_mypssm,\@train_positive_likelihood_seqs_num_mypssm,\@train_positive_likelihood_average_mypssm); 
		# $TMP_arrays_ptrs_ptr =\@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = \@TMP_values_vec;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@train_likelihood_all_mypssm,\@train_likelihood_seqs_num_mypssm,\@train_likelihood_average_mypssm,\@train_positive_likelihood_all_mypssm,\@train_positive_likelihood_seqs_num_mypssm,\@train_positive_likelihood_average_mypssm),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		$TMP_cur_file_path=$cur_collect_run_dir . "/" . $LIKELIHOOD_OUTPUT_FILE_TEST_LEARNED_PSSM . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_LIKELIHOOD_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average) = &CollectLikelihoodResultsFromFile($TMP_cur_file_path);
		push (@test_likelihood_all_pssm ,$TMP_likelihood_all);
		push (@test_likelihood_seqs_num_pssm ,$TMP_likelihood_seqs_num);
		push (@test_likelihood_average_pssm ,$TMP_likelihood_average);
		push (@test_positive_likelihood_all_pssm ,$TMP_positive_likelihood_all);
		push (@test_positive_likelihood_seqs_num_pssm ,$TMP_positive_likelihood_seqs_num);
		push (@test_positive_likelihood_average_pssm ,$TMP_positive_likelihood_average);
		
		# @TMP_arrays_ptrs_vec = (\@train_likelihood_all_pssm,\@train_likelihood_seqs_num_pssm,\@train_likelihood_average_pssm,\@train_positive_likelihood_all_pssm,\@train_positive_likelihood_seqs_num_pssm,\@train_positive_likelihood_average_pssm);
		# $TMP_arrays_ptrs_ptr =\@TMP_arrays_ptrs_vec; 
		# @TMP_values_vec      = ($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average);
		# $TMP_values_ptr      = \@TMP_values_vec;
		# print STDOUT "CollectResults : calling PushValuesToVecs\n";
		# &PushValuesToVecs($TMP_arrays_ptrs_ptr,$TMP_values_ptr);
		#&PushValuesToVecs(\(\@train_likelihood_all_pssm,\@train_likelihood_seqs_num_pssm,\@train_likelihood_average_pssm,\@train_positive_likelihood_all_pssm,\@train_positive_likelihood_seqs_num_pssm,\@train_positive_likelihood_average_pssm),\($TMP_likelihood_all,$TMP_likelihood_seqs_num,$TMP_likelihood_average,$TMP_positive_likelihood_all,$TMP_positive_likelihood_seqs_num,$TMP_positive_likelihood_average));

		my $TMP_cur_file_path=$cur_collect_run_dir . "/" . $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_FEATURE_WEIGHT . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_COMPARE_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		$TMP_cur_KL_distance=&CollectKLDistanceResultsFromFile($TMP_cur_file_path);
		push(@KL_distance_feature_weight,$TMP_cur_KL_distance);
		my $TMP_cur_file_path=$cur_collect_run_dir . "/" . $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_MYPSSM . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_COMPARE_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		$TMP_cur_KL_distance=&CollectKLDistanceResultsFromFile($TMP_cur_file_path);
		push(@KL_distance_mypssm,$TMP_cur_KL_distance);
		my $TMP_cur_file_path=$cur_collect_run_dir . "/" . $COMPARE_MATRICES_OUTPUT_FILE_LEARNED_PSSM . $RUN_FILE_SUFFIX . "$cur_collect_run_num" . $MAT_COMPARE_FILE_TYPE_SUFFIX;
		print STDOUT "CollectResults TMP_cur_file_path:$TMP_cur_file_path\n";
		$TMP_cur_KL_distance=&CollectKLDistanceResultsFromFile($TMP_cur_file_path);
		push(@KL_distance_pssm,$TMP_cur_KL_distance);

	}

	my @collect_res_array_of_arrays_ptrs;
	my @collect_res_headers;

	# psushing into res vec
	

	################
	## train liklihhod
	################
	# train true model
	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_all_true_model);
	push(@collect_res_headers, "train_likelihood_all_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_seqs_num_true_model);
	push(@collect_res_headers, "train_likelihood_seqs_num_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_average_true_model);
	push(@collect_res_headers, "train_likelihood_average_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_all_true_model);
	push(@collect_res_headers, "train_positive_likelihood_all_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_seqs_num_true_model);
	push(@collect_res_headers, "train_positive_likelihood_seqs_num_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_average_true_model);
	push(@collect_res_headers, "train_positive_likelihood_average_true_model");
	# train feature weight
	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_all_feature_weight);
	push(@collect_res_headers, "train_likelihood_all_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_seqs_num_feature_weight);
	push(@collect_res_headers, "train_likelihood_seqs_num_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_average_feature_weight);
	push(@collect_res_headers, "train_likelihood_average_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_all_feature_weight);
	push(@collect_res_headers, "train_positive_likelihood_all_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_seqs_num_feature_weight);
	push(@collect_res_headers, "train_positive_likelihood_seqs_num_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_average_feature_weight);
	push(@collect_res_headers, "train_positive_likelihood_average_feature_weight");

	# train mypssm
	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_all_mypssm);
	push(@collect_res_headers, "train_likelihood_all_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_seqs_num_mypssm);
	push(@collect_res_headers, "train_likelihood_seqs_num_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_average_mypssm);
	push(@collect_res_headers, "train_likelihood_average_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_all_mypssm);
	push(@collect_res_headers, "train_positive_likelihood_all_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_seqs_num_mypssm);
	push(@collect_res_headers, "train_positive_likelihood_seqs_num_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_average_mypssm);
	push(@collect_res_headers, "train_positive_likelihood_average_mypssm");

	# train pssm
	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_all_pssm);
	push(@collect_res_headers, "train_likelihood_all_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_seqs_num_pssm);
	push(@collect_res_headers, "train_likelihood_seqs_num_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_likelihood_average_pssm);
	push(@collect_res_headers, "train_likelihood_average_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_all_pssm);
	push(@collect_res_headers, "train_positive_likelihood_all_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_seqs_num_pssm);
	push(@collect_res_headers, "train_positive_likelihood_seqs_num_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@train_positive_likelihood_average_pssm);
	push(@collect_res_headers, "train_positive_likelihood_average_pssm");

	################
	## test liklihhod
	################

	# test true model
	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_all_true_model);
	push(@collect_res_headers, "test_likelihood_all_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_seqs_num_true_model);
	push(@collect_res_headers, "test_likelihood_seqs_num_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_average_true_model);
	push(@collect_res_headers, "test_likelihood_average_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_all_true_model);
	push(@collect_res_headers, "test_positive_likelihood_all_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_seqs_num_true_model);
	push(@collect_res_headers, "test_positive_likelihood_seqs_num_true_model");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_average_true_model);
	push(@collect_res_headers, "test_positive_likelihood_average_true_model");
	# test feature weight
	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_all_feature_weight);
	push(@collect_res_headers, "test_likelihood_all_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_seqs_num_feature_weight);
	push(@collect_res_headers, "test_likelihood_seqs_num_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_average_feature_weight);
	push(@collect_res_headers, "test_likelihood_average_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_all_feature_weight);
	push(@collect_res_headers, "test_positive_likelihood_all_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_seqs_num_feature_weight);
	push(@collect_res_headers, "test_positive_likelihood_seqs_num_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_average_feature_weight);
	push(@collect_res_headers, "test_positive_likelihood_average_feature_weight");

	# test mypssm
	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_all_mypssm);
	push(@collect_res_headers, "test_likelihood_all_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_seqs_num_mypssm);
	push(@collect_res_headers, "test_likelihood_seqs_num_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_average_mypssm);
	push(@collect_res_headers, "test_likelihood_average_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_all_mypssm);
	push(@collect_res_headers, "test_positive_likelihood_all_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_seqs_num_mypssm);
	push(@collect_res_headers, "test_positive_likelihood_seqs_num_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_average_mypssm);
	push(@collect_res_headers, "test_positive_likelihood_average_mypssm");

	# test pssm
	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_all_pssm);
	push(@collect_res_headers, "test_likelihood_all_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_seqs_num_pssm);
	push(@collect_res_headers, "test_likelihood_seqs_num_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_likelihood_average_pssm);
	push(@collect_res_headers, "test_likelihood_average_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_all_pssm);
	push(@collect_res_headers, "test_positive_likelihood_all_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_seqs_num_pssm);
	push(@collect_res_headers, "test_positive_likelihood_seqs_num_pssm");

	push(@collect_res_array_of_arrays_ptrs, \@test_positive_likelihood_average_pssm);
	push(@collect_res_headers, "test_positive_likelihood_average_pssm");

	################
	## KL distance
	################

	push(@collect_res_array_of_arrays_ptrs, \@KL_distance_feature_weight);
	push(@collect_res_headers, "KL_distance_feature_weight");

	push(@collect_res_array_of_arrays_ptrs, \@KL_distance_mypssm);
	push(@collect_res_headers, "KL_distance_mypssm");

	push(@collect_res_array_of_arrays_ptrs, \@KL_distance_pssm);
	push(@collect_res_headers, "KL_distance_pssm");

	
	#print "Debug length of  collect_res_array_of_arrays_ptrs: @collect_res_array_of_arrays_ptrs";
	#print "Debug length of  collect_res_headers: @collect_res_headers";
	
return (\@collect_res_array_of_arrays_ptrs,\@collect_res_headers);
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub WriteTabularFileOfColumnArrays
{
	my $TAB = "\t";
	
	my ($array_of_col_arrays_ptrs_ptr, $array_of_col_headers_ptr, $write_tabular_output_file_path) = @_;
	
	
	my @array_of_col_arrays_ptrs = @$array_of_col_arrays_ptrs_ptr;
	my @array_of_col_headers = @$array_of_col_headers_ptr;
	
	if (scalar(@array_of_col_arrays_ptrs) !=  scalar(@array_of_col_headers))
	{
		print STDERR "length of array_of_col_arrays_ptrs and array_of_col_headers not equal!\n";
	}
	
	my $cols_num = scalar(@array_of_col_arrays_ptrs);
	if ($cols_num > scalar(@array_of_col_headers))
	{
		$cols_num = scalar(@array_of_col_headers);
	}
	
	open(WRITE_TABULAR_OUT_FILE, ">$write_tabular_output_file_path") or die "WriteTabularFileOfColumnArrays could not open out file: $write_tabular_output_file_path\n";
	
	my @cur_col_array;
	my $cur_col_header;
	my $cur_element;
	
	for (my $i = 0; $i < $cols_num; ++$i)
	{
		$cur_col_header = $array_of_col_headers[$i];
		
		print WRITE_TABULAR_OUT_FILE  "$cur_col_header$TAB"; 
	}
	print WRITE_TABULAR_OUT_FILE "\n";
	
	my $TMP_cur_col_array_ptr = $array_of_col_arrays_ptrs[0];
	@cur_col_array = @$TMP_cur_col_array_ptr ;
	my $rows_num = scalar(@cur_col_array);
	
	for (my $r = 0; $r < $rows_num; ++$r)
	{
		for (my $c = 0; $c < $cols_num; ++$c)
		{
			my $TMP_cur_col_array_ptr = $array_of_col_arrays_ptrs[$c];
			@cur_col_array = @$TMP_cur_col_array_ptr;
			$cur_element = $cur_col_array[$r];
			
			print WRITE_TABULAR_OUT_FILE "$cur_element$TAB"; 
		}
		print WRITE_TABULAR_OUT_FILE "\n";
	}
	close(WRITE_TABULAR_OUT_FILE);
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub WriteExecStrs
{
	my ($array_of_arrays_ptrs_ptr, $array_of_headers_ptr, $write_exec_strs_output_file_path) = @_;
	
	
	my @array_of_arrays_ptrs = @$array_of_arrays_ptrs_ptr;
	my @array_of_headers = @$array_of_headers_ptr;
	
	if (scalar(@array_of_arrays_ptrs) !=  scalar(@array_of_headers))
	{
		print STDERR "length of array_of_arrays_ptrs and array_of_headers not equal!\n";
	}
	
	my $arrays_len = scalar(@array_of_arrays_ptrs);
	if ($arrays_len > scalar(@array_of_headers))
	{
		$arrays_len = scalar(@array_of_headers);
	}
	
	open(WRITE_EXEC_STRS_OUT_FILE, ">$write_exec_strs_output_file_path") or die "WriteExecStrs could not open out file: $write_exec_strs_output_file_path\n";
	
	my @cur_array;
	my $cur_header;
	
	for (my $i = 0; $i < $arrays_len; ++$i)
	{
		my $TMP_cur_array_ptr = $array_of_arrays_ptrs[$i];
		@cur_array = @$TMP_cur_array_ptr;
		$cur_header = $array_of_headers[$i];
		
		print WRITE_EXEC_STRS_OUT_FILE "$cur_header\n";
		
		foreach my $cur_exec_line (@cur_array)
		{
			print WRITE_EXEC_STRS_OUT_FILE "$cur_exec_line \n\n";
		}
		print WRITE_EXEC_STRS_OUT_FILE "\n\n";
	}
	close(WRITE_EXEC_STRS_OUT_FILE);
	
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
# sub ReadExecStrs
# {
	# my ($read_exec_strs_output_file_path) = @_;
	
	# my @read_exec_array_of_arrays_ptrs;
	# my @read_exec_array_of_headers;
	
	# my @read_exec_create_syntethic_test_data_exec_strs_vec;
	# my @read_exec_copy_syntethic_test_data_exec_strs_vec;
	# my @read_exec_create_data_and_model_exec_strs_vec;
	# my @read_exec_learn_and_compare_exec_strs_vec;
	# my @read_exec_delete_syntethic_test_data_exec_strs_vec;
	
	# open(READ_EXEC_STRS_OUT_FILE, $read_exec_strs_output_file_path) or die "ReadExecStrs could not open out file: $read_exec_strs_output_file_path\n";
	

	# my $empty_line;
	# my $line = <READ_EXEC_STRS_OUT_FILE>;
	# chomp($line);
	# if ($line ne "create_syntethic_test_data_exec_strs_vec")
	# {
		# die "ReadExecStrs: line ($line) ne to create_syntethic_test_data_exec_strs_vec";
	# }
	
	
	
	
	# close(READ_EXEC_STRS_OUT_FILE);
	
	# push(@read_exec_array_of_arrays_ptrs, \@read_exec_create_syntethic_test_data_exec_strs_vec);
	# push(@read_exec_array_of_headers, "create_syntethic_test_data_exec_strs_vec");

	# push(@read_exec_array_of_arrays_ptrs, \@read_exec_copy_syntethic_test_data_exec_strs_vec);
	# push(@read_exec_array_of_headers, "copy_syntethic_test_data_exec_strs_vec");

	# push(@read_exec_array_of_arrays_ptrs, \@read_exec_create_data_and_model_exec_strs_vec);
	# push(@read_exec_array_of_headers, "create_data_and_model_exec_strs_vec");

	# push(@read_exec_array_of_arrays_ptrs, \@read_exec_learn_and_compare_exec_strs_vec);
	# push(@read_exec_array_of_headers, "learn_and_compare_exec_strs_vec");

	# push(@read_exec_array_of_arrays_ptrs, \@read_exec_delete_syntethic_test_data_exec_strs_vec);
	# push(@read_exec_array_of_headers, "delete_syntethic_test_data_exec_strs_vec");
	
	# return (\@read_exec_array_of_arrays_ptrs,\@read_exec_array_of_headers);
# }


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub ParseModelsFile
{
	my ($in_models_file) = @_;
	my @models_files_names;
	my @models_position_nums;
	my @l_at_pos_feature_max_pos_num;
	
	open(IN_FILE, "<$in_models_file") or die "ParseModelsFile could not open out file: $in_models_file\n";
	
	my $line_num = 0;
	while (<IN_FILE>)
	{
	    chomp;
	    my $line = $_;
	
	    ($models_files_names[$line_num], $models_position_nums[$line_num], $l_at_pos_feature_max_pos_num[$line_num]) = split(/\t/, $_, 3);
	
	    ++$line_num;
	}
	close(IN_FILE);
	
	return (\@models_files_names,\@models_position_nums,\@l_at_pos_feature_max_pos_num)
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub ParseArgsFile
{
	my ($in_args_file) = @_;
	my @in_train_true_model_sample_num;
	my @in_train_background_sample_num;
	my @in_sum_weights_penalty_coefficient;
	my @in_num_of_sequences_in_the_world;
	my @in_positive_seqs_prior_probability;
	my @cur_line_arr;
	my $cur_line_header;
	
	my $TRAIN_TRUE_MODEL_SAMPLE_NUM_HEADER     = "TRAIN_TRUE_MODEL_SAMPLE_NUM";
	my $TRAIN_BACKGROUND_SAMPLE_NUM_HEADER     = "TRAIN_BACKGROUND_SAMPLE_NUM";
	my $SUM_WEIGHTS_PENALTY_COEFFICIENT_HEADER = "SUM_WEIGHTS_PENALTY_COEFFICIENT";
	my $NUM_OF_SEQUENCES_IN_THE_WORLD_HEADER   = "NUM_OF_SEQUENCES_IN_THE_WORLD";
	my $POSITIVE_SEQS_PRIOR_PROBABILITY_HEADER = "POSITIVE_SEQS_PRIOR_PROBABILITY";
	
		open(IN_FILE, "<$in_args_file") or die "ParseArgsFile could not open out file: $in_args_file\n";
	
	while (<IN_FILE>)
	{
	    chomp;
	    my $line = $_;
	
	    ($cur_line_header, @cur_line_arr) = split(/\t/, $_);
	
		print "$cur_line_header\n";
		print "@cur_line_arr\n";
		
		if ($cur_line_header eq $TRAIN_TRUE_MODEL_SAMPLE_NUM_HEADER)
		{
			@in_train_true_model_sample_num = @cur_line_arr;
			print "found the $TRAIN_TRUE_MODEL_SAMPLE_NUM_HEADER line: @in_train_true_model_sample_num\n";
		}
		
		if ($cur_line_header eq $TRAIN_BACKGROUND_SAMPLE_NUM_HEADER)
		{
			@in_train_background_sample_num = @cur_line_arr;
			print "found the $TRAIN_BACKGROUND_SAMPLE_NUM_HEADER line: @in_train_background_sample_num\n";
		}
		
		if ($cur_line_header eq $SUM_WEIGHTS_PENALTY_COEFFICIENT_HEADER)
		{
			@in_sum_weights_penalty_coefficient = @cur_line_arr;
			print "found the $SUM_WEIGHTS_PENALTY_COEFFICIENT_HEADER line: @in_sum_weights_penalty_coefficient\n";
		}
		
		if ($cur_line_header eq $NUM_OF_SEQUENCES_IN_THE_WORLD_HEADER)
		{
			@in_num_of_sequences_in_the_world = @cur_line_arr;
			print "found the $NUM_OF_SEQUENCES_IN_THE_WORLD_HEADER line: @in_num_of_sequences_in_the_world\n";
		}
		
		if ($cur_line_header eq $POSITIVE_SEQS_PRIOR_PROBABILITY_HEADER)
		{
			@in_positive_seqs_prior_probability = @cur_line_arr;
			print "found the $POSITIVE_SEQS_PRIOR_PROBABILITY_HEADER line: @in_positive_seqs_prior_probability\n";
		}
	}
	close(IN_FILE);
	
	return (\@in_train_true_model_sample_num,\@in_train_background_sample_num,\@in_sum_weights_penalty_coefficient,\@in_num_of_sequences_in_the_world,\@in_positive_seqs_prior_probability);
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub CollectUsingParamFile
{

	my ($collect_param_file_path,$collect_out_file_path) = @_;
	
	print STDOUT "--------------------------------- start read run params file  -------------------------------------------------------------------------\n";

	open(RUN_PARAMS_IN_FILE, "<$collect_param_file_path") or die "CollectUsingParamFile could not open out file: $collect_param_file_path\n";
	
	
	my @collect_run_num_vec;
	my @collect_run_dirs_vec;
	my @collect_run_models_files_vec;
	my @collect_run_models_nums_vec;
	my @collect_repeat_num_vec;
	my @collect_run_models_position_nums_vec;
	my @collect_run_models_l_at_pos_feature_max_pos_vec;
	my @collect_run_train_true_model_sample_num_vec;
	my @collect_run_train_background_sample_num_vec;
	my @collect_run_sum_weights_penalty_coefficient_vec;
	
	my @collect_cur_param_line_arr;
	
	my $line_count = 1;
	
	my $line = <RUN_PARAMS_IN_FILE>;
	while (<RUN_PARAMS_IN_FILE>)
	{
	    chomp;
	    $line = $_;
	
		print STDOUT "CollectUsingParamFile read line: $line\n";
		
	    (@collect_cur_param_line_arr) = split(/\t/, $line);
		
		print STDOUT "CollectUsingParamFile line array: @collect_cur_param_line_arr\n";
		
		print STDOUT "CollectUsingParamFile push 0: $collect_cur_param_line_arr[0]\n";
		push (@collect_run_num_vec,$collect_cur_param_line_arr[0]);
		print STDOUT "CollectUsingParamFile push 1: $collect_cur_param_line_arr[1]\n";
		push (@collect_run_dirs_vec,$collect_cur_param_line_arr[1]);
		push (@collect_run_models_files_vec,$collect_cur_param_line_arr[2]);
		push (@collect_run_models_nums_vec,$collect_cur_param_line_arr[3]);
		push (@collect_repeat_num_vec,$collect_cur_param_line_arr[4]);
		push (@collect_run_models_position_nums_vec,$collect_cur_param_line_arr[5]);
		push (@collect_run_models_l_at_pos_feature_max_pos_vec,$collect_cur_param_line_arr[6]);
		push (@collect_run_train_true_model_sample_num_vec,$collect_cur_param_line_arr[7]);
		push (@collect_run_train_background_sample_num_vec,$collect_cur_param_line_arr[8]);
		push (@collect_run_sum_weights_penalty_coefficient_vec,$collect_cur_param_line_arr[9]);
	}
	close(RUN_PARAMS_IN_FILE);
	
	my @collect_output_array_of_col_arrays;
	my @collect_output_col_arrays_names;

	push(@collect_output_array_of_col_arrays, \@collect_run_num_vec);
	push(@collect_output_col_arrays_names, "run_num");

	push(@collect_output_array_of_col_arrays, \@collect_run_dirs_vec);
	push(@collect_output_col_arrays_names, "dirs");

	push(@collect_output_array_of_col_arrays, \@collect_run_models_files_vec);
	push(@collect_output_col_arrays_names, "models_files");

	push(@collect_output_array_of_col_arrays, \@collect_run_models_nums_vec);
	push(@collect_output_col_arrays_names, "models_nums");

	push(@collect_output_array_of_col_arrays, \@collect_repeat_num_vec);
	push(@collect_output_col_arrays_names, "repeat_num");

	push(@collect_output_array_of_col_arrays, \@collect_run_models_position_nums_vec);
	push(@collect_output_col_arrays_names, "models_position_nums");

	push(@collect_output_array_of_col_arrays, \@collect_run_models_l_at_pos_feature_max_pos_vec);
	push(@collect_output_col_arrays_names, "models_l_at_pos_feature_max_pos");

	push(@collect_output_array_of_col_arrays, \@collect_run_train_true_model_sample_num_vec);
	push(@collect_output_col_arrays_names, "train_true_model_sample_num");

	push(@collect_output_array_of_col_arrays, \@collect_run_train_background_sample_num_vec);
	push(@collect_output_col_arrays_names, "train_background_sample_num");

	push(@collect_output_array_of_col_arrays, \@collect_run_sum_weights_penalty_coefficient_vec);
	push(@collect_output_col_arrays_names, "sum_weights_penalty_coefficient");
	print STDOUT "-------------- end read run params file  -------------------------------------------------------------------------\n";
	
        print STDOUT "-------------------- start collect data  -------------------------------------------------------------------------\n";
	my ($collect_run_results_array_of_arrays_ptrs_ptr, $collect_run_results_headers_ptr) = &CollectResults(\@collect_run_num_vec,\@collect_run_dirs_vec);
	my @collect_run_results_array_of_arrays_ptrs = @$collect_run_results_array_of_arrays_ptrs_ptr;
	my @collect_run_results_headers = @$collect_run_results_headers_ptr;
	print STDOUT "---------------------- end collect data  -------------------------------------------------------------------------\n";

	print STDOUT "----------- start write output (collect) -------------------------------------------------------------------------\n";

	push(@collect_output_array_of_col_arrays, @collect_run_results_array_of_arrays_ptrs);
	push(@collect_output_col_arrays_names, @collect_run_results_headers);

	print "DEBUG: writing output to: $collect_out_file_path\n";
	&WriteTabularFileOfColumnArrays(\@collect_output_array_of_col_arrays,\@collect_output_col_arrays_names,$collect_out_file_path);
	#&WriteTabularFileOfColumnArrays(\@collect_run_results_array_of_arrays_ptrs,\@collect_run_results_headers,$collect_out_file_path);
	print STDOUT "-------------- end write output (collect) -------------------------------------------------------------------------\n";

}


	# -w <#num_of_sequences_in_the_world> num of sequences in the partition function world (-1 for size of train set)
	# -f <positive_seqs_prior_probability> positive seqs prior probability for reweight (-1 for no rewight)

__DATA__

Usage: run_learn_feature_weight_matrix_from_syntethic_data.pl <models file> <models dir> <background matrix file> 
                                                              <args_file> <run dirs prefix> <test files dir>
                                                              <output run prarams file > <exec_strs_output_file> <output file>

	-p <#process to use> number of processes to use in the run
	-q <#max_queue_length> number of maximum jobs in queu allowed when sending a job. default is -1 (doesn't care for queue length)
	-s <#num of sec between q monitoring>
	-d <1/0> is to delete run cout cerr tmp file 
	-o <output dir>
	-r <#repeat num> num of repeats on all the run (with the same test data)
	-f <fix_not_run_mode 0/1> defualt is zero. if 1 - will calculate only the learning part of models that were not calculated before 
	                          in a run that uses EXACTLLY the same parameters.
							  out files including param and exec will be rewriten.
	-MaxUserP <#> max number of user processes, default 40
	-MinFreeProcesses <#> min number of free processes, defualt 3
	-DeleteTestFiles <1/0> does to delete test files from running dires (usually for debug) default 1
	-TestTrueModelSampleNum <#> Test True Model Sample Num default 10000
	-NoNeedToCopyTestFiles <0/1> defualt is 0 , used if the files weren't deleted and you run a fix mode in order to save time


