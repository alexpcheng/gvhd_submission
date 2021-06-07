#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/learn_train_and_cal_test_likelihood_helper.pl";
require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


#getting the flags
my %args = &load_args(\@ARGV);

my $cv_groups_num                     = $ARGV[2];

my $collect_likelihood                   = &get_arg("collect_likelihood", 0, \%args);
my $cv_num                               = &get_arg("cv_num", 5, \%args);
my $collect_set                               = &get_arg("cv_num", 5, \%args);

-collect_set <train/test> defualt test

-motif_list_file <file_name> defualt all_tf.txt

-cv_num <#> defualt is 5


elsif ($ARGV[0] eq "--Indications")
{
  my $dirs_file              = $ARGV[1];
  my $CV_dir_num_for_model   = $ARGV[2];
  my $out_file_name          = $ARGV[3];
  my $input_files_prefix     = $ARGV[4];
  my $processes_num          = $ARGV[5];
  &RunCalIndications($dirs_file,$CV_dir_num_for_model,$out_file_name,$input_files_prefix,$processes_num);
  exit;
}
elsif ($ARGV[0] eq "--collect")
{
  my $dirs_file               = $ARGV[1];
  my $run_out_file_name       = $ARGV[2];
  my $common_out_file_path    = $ARGV[3];
  my $not_run_out_file_path   = $ARGV[4];
  
  &ConcatOutFiles($dirs_file,$run_out_file_name,$common_out_file_path, $not_run_out_file_path);
  exit;
}
elsif ($ARGV[0] eq "--collectFeatureStat")
{
  my $dirs_file               = $ARGV[1];
  my $run_out_file_name       = $ARGV[2];
  my $common_out_file_path    = $ARGV[3];
  my $num_of_cv_groups   = $ARGV[4];
  
  &ConcatFeaturesStatOutFiles($dirs_file,$run_out_file_name,$common_out_file_path, $num_of_cv_groups);
  exit;
}

# getting  the parameters
my $dirs_file                         = $ARGV[0];
my $run_out_file_name                 = $ARGV[1];
my $cv_groups_num                     = $ARGV[2];
my $background_matrix_file            = $ARGV[3];
my $train_positive_file_name_prefix   = $ARGV[4];


#my $weight_matrix_positions_num                     = &get_arg("", 1, \%args);

# getting the flags
my %args = &load_args(\@ARGV);
my $processes_num                                     = &get_arg("p", $cv_groups_num, \%args);
if ($processes_num <= 0)
  {
    $processes_num  =10;
  }
my $num_of_sec_between_q_monitoring                   = &get_arg("s", 2, \%args);
my $background_file_name_prefix                       = &get_arg("b", "background", \%args);
my $is_delete_tmp_file                                = &get_arg("d", 1, \%args);
my $letters_at_position_feature_max_positions_num     = &get_arg("l", 2, \%args);
my $sum_weights_penalty_coefficient                   = &get_arg("c", 0.00001, \%args);
my $num_of_sequences_in_the_world                     = &get_arg("w", 50000, \%args);
my $positive_seqs_prior_probability                   = &get_arg("f", -1, \%args);
my $queue_max_length                                  = &get_arg("q",-1, \%args);
my $estimate_measure_type                             = &get_arg("e","Default", \%args);
my $use_initial_p_value_filter                        = &get_arg("if","false", \%args);
my $filter_only_positive_features                     = &get_arg("ipf","false", \%args);
my $remove_features_under_weight_thresh               = &get_arg("r",0.000001, \%args);
my $use_only_positive_weights                         = &get_arg("UseOnlyPositiveWeights","false", \%args);
my $learn_my_pssm                                     = &get_arg("mypssm",0, \%args);
my $cal_weights_functions_samples                     = &get_arg("math","false", \%args);
my $reweight_positive_instances_fraction              = &get_arg("reweight","false", \%args);
my $initial_filter_count_percent_thresh               = &get_arg("percentFilterThresh",0, \%args);
my $write_iteration_file                              = &get_arg("writeIterationFile",0, \%args);
my $major_training_parameter_max_train_iterations     = &get_arg("majorIter",1000, \%args);
my $secondary_training_parameter_max_train_iterations = &get_arg("secondaryIter",1000, \%args);
my $use_pssm_importance_sampling                      = &get_arg("pssmImportanceSampling",0, \%args);

my $use_secondary_training_procedure                  = &get_arg("useSecondaryTrain","true", \%args);     
my $run_only_on_single_cv_num                         = &get_arg("onlyCVNum",0, \%args);

my $run_without_creating_CV_dirs                      = &get_arg("dontCreateCVDirs",0, \%args);
my $run_mode                                          = &get_arg("runMode","FullRun", \%args);

my $major_training_procedure_type                      = &get_arg("majorTrainingProcedureType","ConjugateGradient", \%args);

# clique graph approximation parameters
my $func_type                                         = &get_arg("FunctionType","SeqsLGradientUsingFeatureEstimation", \%args);
my $selection_method                                  = &get_arg("FeatureSelection","Grafting", \%args);
my $expectation_estimation_method                     = &get_arg("ExpectationEstimation","CliqueGraph", \%args);
my $expectation_by_seq_rewieght                       = &get_arg("EBySeqReweight","false", \%args);
my $expectation_by_seq_onlyZero                       = &get_arg("EBySeqOnlyZero","true", \%args);
my $expectation_by_seq_Importance                     = &get_arg("EBySeqImportance","true", \%args);

my $loopy_span_tree_reduction                         = &get_arg("LoopySpanTreeReduction","true", \%args);
my $loopy_use_gbp                                     = &get_arg("LoopyUseGBP","true", \%args);
my $loopy_use_only_exact                              = &get_arg("LoopyUseOnlyExact","false", \%args);
my $loopy_max_iterations                              = &get_arg("LoopyMaxIter","1000", \%args);
my $loopy_calibration_tresh                           = &get_arg("LoopyCalibrationT","0.0001", \%args);
my $loopy_calibration_node_percent                    = &get_arg("LoopyCalibrationNodeP","1", \%args);
my $loopy_potential_type                              = &get_arg("LoopyPotential","CpdPotential", \%args);
my $loopy_distance_method                             = &get_arg("LoopyDistance" ,"DmNormLInf", \%args);
my $loopy_calibration_tresh_success                   = &get_arg("LoopyCalibrationTSuccess","0.02", \%args);
my $loopy_calibration_node_percent_success            = &get_arg("LoopyCalibrationNodePSuccess","0.95", \%args);

my $loopy_calibration_method                          = &get_arg("LoopyCalibrationMethod","SynchronicBP", \%args);
my $loopy_average_messages_in_message_update          = &get_arg("LoopyCalibrationAverageMessagesInMessageUpdate","false", \%args);

my $init_fmm_from_pssm                                = &get_arg("init_fmm_from_pssm","0", \%args);

my $limit_the_num_of_parameters_ratio_to_pssm                  = &get_arg("limit_the_num_of_parameters_ratio_to_pssm","3", \%args);
my $max_learning_iterations_num                                = &get_arg("max_learning_iterations_num","100", \%args);

my $structure_learning_sum_weights_penalty_coefficient         = &get_arg("structure_learning_sum_weights_penalty_coefficient","0.1", \%args);
my $parameters_learning_sum_weights_penalty_coefficient        = &get_arg("parameters_learning_sum_weights_penalty_coefficient","0.1", \%args);

my $feature_selection_score_thresh                             = &get_arg("feature_selection_score_thresh","0", \%args);

my $remove_features_under_weight_thresh_after_each_iter        = &get_arg("remove_features_under_weight_thresh_after_each_iter","false", \%args);
my $remove_features_under_weight_thresh_after_full_grafting    = &get_arg("remove_features_under_weight_thresh_after_full_grafting","false", \%args);
my $do_parameters_learning_iteration_after_learning_structure  = &get_arg("do_parameters_learning_iteration_after_learning_structure","false", \%args);

my $pssm_pseudo_counts                                        = &get_arg("pssm_pseudo_counts","0.4", \%args);
my $pseudo_count_equivalent_size                              = &get_arg("pseudo_count_equivalent_size","5", \%args);

my $letters_at_two_positions_chi2_filter_fdr_thresh           = &get_arg("l_at_two_pos_chi2_filter_fdr_thresh","-1", \%args);
my $letters_at_multiple_positions_binomial_filter_fdr_thresh  = &get_arg("l_at_multiple_pos_binomial_filter_fdr","-1", \%args);
my $multiple_hypothesis_correction                            = &get_arg("multiple_hypothesis_correction","FDR", \%args);

my $compute_partition_function_method                         = &get_arg("compute_partition_function_method","ComputeZFuncUsingCliqueGraph", \%args);

my $realign_sequences                                         = &get_arg("realign_sequences","false", \%args);
my $max_realign_iterations_num                                = &get_arg("max_realign_iterations_num","0", \%args);

my $compute_positive_sequences_likelihood_method_type         = &get_arg("compute_positive_sequences_likelihood_method_type","SumOverSequencePositions", \%args);

my $forced_num_positions_without_pedding_of_aligning_pssm     = &get_arg("forced_num_positions_without_pedding_of_aligning_pssm",0, \%args);

my $run_mode_int = 0;
if ($run_mode eq "FullRun")
{
	$run_mode_int = 0;
}
elsif ($run_mode eq "OnlyCreateCV")
{
	$run_mode_int = 1;
}
elsif ($run_mode eq "OnlyRunOnSingleCV")
{
	$run_mode_int = 2;
}
elsif ($run_mode eq "OnlyCollectRes") 
{
	$run_mode_int = 3;
}
else
{
	die "Run mode unrecognized run mode:$run_mode \n";
}



print STDOUT "---------------------------------params: ----------------------------------------\n";
print STDOUT "dirs_file:$dirs_file\n";
print STDOUT "run_out_file_name:$run_out_file_name\n";
print STDOUT "cv_groups_num:$cv_groups_num\n";
print STDOUT "background_matrix_file:$background_matrix_file\n";
print STDOUT "train_positive_file_name_prefix:$train_positive_file_name_prefix\n";
print STDOUT "---- flags: -----\n";
print STDOUT "processes_num:$processes_num\n";
print STDOUT "num_of_sec_between_q_monitoring:$num_of_sec_between_q_monitoring\n";
print STDOUT "is_delete_tmp_file:$is_delete_tmp_file\n";
print STDOUT "background_file_name_prefix:$background_file_name_prefix\n";
print STDOUT "letters_at_position_feature_max_positions_num:$letters_at_position_feature_max_positions_num\n";
print STDOUT "sum_weights_penalty_coefficient:$sum_weights_penalty_coefficient\n";
print STDOUT "num_of_sequences_in_the_world:$num_of_sequences_in_the_world\n";
print STDOUT "positive_seqs_prior_probability:$positive_seqs_prior_probability\n";
print STDOUT "queue_max_length:$queue_max_length\n";
print STDOUT "estimate_measure_type:$estimate_measure_type\n";
print STDOUT "use_initial_p_value_filter:$use_initial_p_value_filter\n";
print STDOUT "filter_only_positive_features:$filter_only_positive_features\n";
print STDOUT "remove_features_under_weight_thresh:$remove_features_under_weight_thresh\n";
print STDOUT "use_only_positive_weights:$use_only_positive_weights\n";
print STDOUT "learn_my_pssm:$learn_my_pssm\n";
print STDOUT "cal_weights_functions_samples:$cal_weights_functions_samples\n";
print STDOUT "reweight_positive_instances_fraction:$reweight_positive_instances_fraction\n";
print STDOUT "initial_filter_count_percent_thresh:$initial_filter_count_percent_thresh\n";
print STDOUT "write_iteration_file:$write_iteration_file\n";
print STDOUT "major_training_parameter_max_train_iterations:$major_training_parameter_max_train_iterations\n";
print STDOUT "secondary_training_parameter_max_train_iterations:$secondary_training_parameter_max_train_iterations\n";
print STDOUT "use_secondary_training_procedure:$use_secondary_training_procedure\n";
print STDOUT "run_only_on_single_cv_num:$run_only_on_single_cv_num\n";
print STDOUT "run_mode:$run_mode\n";
print STDOUT "run_mode_int:$run_mode_int\n";
print STDOUT "run_without_creating_CV_dirs:$run_without_creating_CV_dirs\n";
print STDOUT "use_pssm_importance_sampling:$use_pssm_importance_sampling\n";

print STDOUT "func_type:$func_type\n";
print STDOUT "selection_method:$selection_method\n";
print STDOUT "expectation_estimation_method:$expectation_estimation_method\n";
print STDOUT "expectation_by_seq_rewieght:$expectation_by_seq_rewieght\n";
print STDOUT "expectation_by_seq_onlyZero:$expectation_by_seq_onlyZero\n";
print STDOUT "expectation_by_seq_Importance:$expectation_by_seq_Importance\n";

print STDOUT "loopy_span_tree_reduction:$loopy_span_tree_reduction\n";
print STDOUT "loopy_use_gbp:$loopy_use_gbp\n";
print STDOUT "loopy_use_only_exact:$loopy_use_only_exact\n";

print STDOUT "loopy_max_iterations:$loopy_max_iterations\n";
print STDOUT "loopy_calibration_tresh:$loopy_calibration_tresh\n";
print STDOUT "loopy_calibration_node_percent:$loopy_calibration_node_percent\n";
print STDOUT "loopy_potential_type:$loopy_potential_type\n";
print STDOUT "loopy_distance_method:$loopy_distance_method\n";
print STDOUT "loopy_calibration_tresh_success:$loopy_calibration_tresh_success\n";
print STDOUT "loopy_calibration_node_percent_success:$loopy_calibration_node_percent_success\n";

print STDOUT "loopy_calibration_method:$loopy_calibration_method\n";
print STDOUT "loopy_average_messages_in_message_update:$loopy_average_messages_in_message_update\n";
print STDOUT "init_fmm_from_pssm:$init_fmm_from_pssm\n";

print STDOUT "limit_the_num_of_parameters_ratio_to_pssm:$limit_the_num_of_parameters_ratio_to_pssm\n";
print STDOUT "max_learning_iterations_num:$max_learning_iterations_num\n";

print STDOUT "structure_learning_sum_weights_penalty_coefficient:$structure_learning_sum_weights_penalty_coefficient\n";
print STDOUT "parameters_learning_sum_weights_penalty_coefficient:$parameters_learning_sum_weights_penalty_coefficient\n";

print STDOUT "remove_features_under_weight_thresh_after_each_iter:$remove_features_under_weight_thresh_after_each_iter\n";
print STDOUT "remove_features_under_weight_thresh_after_full_grafting:$remove_features_under_weight_thresh_after_full_grafting\n";
print STDOUT "do_parameters_learning_iteration_after_learning_structure:$do_parameters_learning_iteration_after_learning_structure\n";

print STDOUT "pssm_pseudo_counts:$pssm_pseudo_counts\n";
print STDOUT "pseudo_count_equivalent_size:$pseudo_count_equivalent_size\n";

print STDOUT "letters_at_two_positions_chi2_filter_fdr_thresh:$letters_at_two_positions_chi2_filter_fdr_thresh\n";
print STDOUT "letters_at_multiple_positions_binomial_filter_fdr_thresh:$letters_at_multiple_positions_binomial_filter_fdr_thresh\n";

print STDOUT "multiple_hypothesis_correction:$multiple_hypothesis_correction\n";

print STDOUT "compute_partition_function_method:$compute_partition_function_method\n";

print STDOUT "realign_sequences:$realign_sequences\n";
print STDOUT "max_realign_iterations_num:$max_realign_iterations_num\n";

print STDOUT "compute_positive_sequences_likelihood_method_type:$compute_positive_sequences_likelihood_method_type\n";

print STDOUT "forced_num_positions_without_pedding_of_aligning_pssm:$forced_num_positions_without_pedding_of_aligning_pssm\n";



print STDOUT "--------------------------------------------------------------------------------\n\n";

my @dirs_vec;
my @appearences_vec;
my @weight_matrix_positions_num_vec;
my ($dirs_vec_ptr,$appearences_vec_ptr,$weight_matrix_positions_num_vec_ptr) = &ParseDirsFile($dirs_file);
@dirs_vec = @$dirs_vec_ptr;
@appearences_vec = @$appearences_vec_ptr;
@weight_matrix_positions_num_vec = @$weight_matrix_positions_num_vec_ptr;

my $dirs_num = scalar(@dirs_vec);

print "DEBUG dirs_num=$dirs_num\n";
print "DEBUG dirs_vec=@dirs_vec\n";

for (my $cur_dir_num = 0; $cur_dir_num < $dirs_num; ++$cur_dir_num)
{
	my $cur_dir = $dirs_vec[$cur_dir_num];
	my $cur_appearences = $appearences_vec[$cur_dir_num];
	my $cur_weight_matrix_positions_num = $weight_matrix_positions_num_vec[$cur_dir_num];
	print "########################################## start new dir ($cur_dir_num ): $cur_dir  ###############################################\n";
	print "DEBUG: cur_dir_num = $cur_dir_num, cur_dir = $cur_dir, cur_appearences = $cur_appearences, cur_weight_matrix_positions_num = $cur_weight_matrix_positions_num\n";
	chdir($cur_dir);
	print "cur dir:";
	system("pwd");
	
	my $cur_cv_groups_num = $cv_groups_num;
	if ($cv_groups_num <= 0)
	{
		print "run in leave one out mode ";
		$cur_cv_groups_num = `fasta2stab.pl all.fa | wc -l`;
		chomp($cur_cv_groups_num );
		
		if ($cur_cv_groups_num > 100)
		{
			$cur_cv_groups_num = 100;
		}
		print " with $cur_cv_groups_num groups";
	}
	
	print "
		train_positive_file_name_prefix = $train_positive_file_name_prefix,
		background_file_name_prefix = $background_file_name_prefix, cv_groups_num = $cv_groups_num,run_out_file_name = $run_out_file_name,
		processes_num = $processes_num,num_of_sec_between_q_monitoring = $num_of_sec_between_q_monitoring,is_delete_tmp_file = $is_delete_tmp_file,queue_max_length = $queue_max_length,
		background_matrix_file = $background_matrix_file,letters_at_position_feature_max_positions_num = $letters_at_position_feature_max_positions_num,
		sum_weights_penalty_coefficient = $sum_weights_penalty_coefficient,cur_weight_matrix_positions_num = $cur_weight_matrix_positions_num,
		num_of_sequences_in_the_world = $num_of_sequences_in_the_world,positive_seqs_prior_probability = $positive_seqs_prior_probability\n\n";
		
		my $cur_forced_num_positions_without_pedding_of_aligning_pssm = 0;
		
		if ($forced_num_positions_without_pedding_of_aligning_pssm > 0)
		{
			$cur_forced_num_positions_without_pedding_of_aligning_pssm=$cur_weight_matrix_positions_num-$forced_num_positions_without_pedding_of_aligning_pssm;
		}
		
		
	&LearnTrainAndCalTestLikelihoodIntoFile(
		$train_positive_file_name_prefix,
		$background_file_name_prefix, $cur_cv_groups_num,$run_out_file_name,
		$processes_num,$num_of_sec_between_q_monitoring,$is_delete_tmp_file,$queue_max_length,
		$background_matrix_file,$letters_at_position_feature_max_positions_num,
		$sum_weights_penalty_coefficient,$cur_weight_matrix_positions_num,
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
		$cur_forced_num_positions_without_pedding_of_aligning_pssm
		);
		#$out_file_without_background_name_prefix,$out_file_with_background_name_prefix,
	chdir("..");
	print "cur dir:";
	system("pwd");
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub ParseDirsFile
{

	my ($dirs_file_path) = @_;
	
	print STDOUT "--------------------------------- start read dirs_file_path  -------------------------------------------------------------------------\n";

	my @parsefile_dirs_vec;
	my @parsefile_appearences_vec;
	my @parsefile_weight_matrix_positions_num_vec;

	open(IN_DIRS_FILE, "<$dirs_file_path") or die "ParseDirsFile could not open in file: $dirs_file_path\n";

	my @dir_names_line_arr;
	#my $line = <IN_DIRS_FILE>;
	
	my $line;
	while (<IN_DIRS_FILE>)
	{
	    chomp;
	    $line = $_;
	
		print STDOUT "CollectUsingParamFile read line: $line\n";
		
		(@dir_names_line_arr) = split(/\t/, $line);
		
		print STDOUT "ParseDirsFile line array: @dir_names_line_arr\n";
		
		chomp($dir_names_line_arr[2]);
		
		push (@parsefile_dirs_vec,$dir_names_line_arr[0]);
		push (@parsefile_appearences_vec,$dir_names_line_arr[1]);
		push (@parsefile_weight_matrix_positions_num_vec,$dir_names_line_arr[2]);
	}
	close(IN_DIRS_FILE);
	
	print STDOUT "--------------------------------- end  read dirs_file_path  -------------------------------------------------------------------------\n";

	return (\@parsefile_dirs_vec,\@parsefile_appearences_vec,\@parsefile_weight_matrix_positions_num_vec);
}


# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub ConcatOutFiles
{
	my ($concat_dirs_file,$concat_run_out_file_name,$concat_common_out_file_path, $not_run_out_file_path) = @_;

	my $concat_dirs_vec_ptr;
	my $concat_appearences_vec_ptr;
	my $concat_weight_matrix_positions_num_vec_ptr;
	
	my ($concat_dirs_vec_ptr,$concat_appearences_vec_ptr,$concat_weight_matrix_positions_num_vec_ptr) = &ParseDirsFile($concat_dirs_file);

	my @concat_dirs_vec = @$concat_dirs_vec_ptr;
	my @concat_appearences_vec = @$concat_appearences_vec_ptr;
	my @concat_weight_matrix_positions_num_vec = @$concat_weight_matrix_positions_num_vec_ptr;
	
	my $concat_dirs_num = scalar(@concat_dirs_vec);

	open(COMMON_OUT_FILE, ">$concat_common_out_file_path") or die "ConcatOutFiles could not open out file: $concat_common_out_file_path\n";
	
	open(NOT_RUN_OUT_FILE, ">$not_run_out_file_path") or die "ConcatOutFiles could not open out file: $not_run_out_file_path\n";
	

	
	
	my $first_dir = 1;
	
	my $collected_dir_num = 0;
	
	for (my $cur_dir_num = 0; $cur_dir_num < $concat_dirs_num; ++$cur_dir_num)
	{
		my $cur_concat_dirs = $concat_dirs_vec[$cur_dir_num];
		my $cur_concat_appearences = $concat_appearences_vec[$cur_dir_num];
		my $cur_concat_weight_matrix_positions_num= $concat_weight_matrix_positions_num_vec[$cur_dir_num];
		my $cur_run_out_path = $cur_concat_dirs . "/" . $concat_run_out_file_name;
		
		 if (!(-e $cur_run_out_path))
		 {
			 print STDOUT "File Does not exist: $cur_run_out_path\n";
			 print NOT_RUN_OUT_FILE $cur_concat_dirs . "\t" . $cur_concat_appearences . "\t" . $cur_concat_weight_matrix_positions_num . "\n";
		}
		else
		{
			++$collected_dir_num;

			print STDOUT "collect dir num: $cur_dir_num , name: $cur_concat_dirs\n";
			open(CUR_INLFILE, $cur_run_out_path) or die "ConcatOutFiles could not open in file: $cur_run_out_path\n";

			my $line = <CUR_INLFILE>;
			
			if ($first_dir == 1)
			{
				$line = "Length" ."\t" . $line;
				$line = "Appearences" ."\t" . $line;
				$line = "Matrix" ."\t" . $line;
				$line = "Dir_num" . "\t" . $line;
				
				
				$first_dir = 0;
				print COMMON_OUT_FILE $line;
			}
			
			while ( ($line = <CUR_INLFILE>) )
			{
				#chomp($line);
				chomp($cur_concat_weight_matrix_positions_num);
				chomp($cur_concat_weight_matrix_positions_num);
				$line = "$cur_concat_weight_matrix_positions_num" ."\t" . $line;
				$line = "$cur_concat_appearences" ."\t" . $line;
				$line = "$cur_concat_dirs" ."\t" . $line;
				$line = "$cur_dir_num" . "\t" . $line . "\n";
				
				print COMMON_OUT_FILE $line;
			}
			
			close(CUR_INLFILE);
			print STDOUT "done collect dir: $cur_concat_dirs\n";
		}
		
	}
	close(COMMON_OUT_FILE);
	close(NOT_RUN_OUT_FILE);
	
	print "\nCollected $collected_dir_num dirs (out of $concat_dirs_num)\n\n";
}

# -------------------------------------------------------------------------
#
# ------------------------------------------------------------------------
sub ConcatFeaturesStatOutFiles
{
	my ($concat_dirs_file,$concat_run_out_file_name,$concat_common_out_file_path, $num_of_cv_groups) = @_;

	my $concat_dirs_vec_ptr;
	my $concat_appearences_vec_ptr;
	my $concat_weight_matrix_positions_num_vec_ptr;
	
	my ($concat_dirs_vec_ptr,$concat_appearences_vec_ptr,$concat_weight_matrix_positions_num_vec_ptr) = &ParseDirsFile($concat_dirs_file);

	my @concat_dirs_vec = @$concat_dirs_vec_ptr;
	my @concat_appearences_vec = @$concat_appearences_vec_ptr;
	my @concat_weight_matrix_positions_num_vec = @$concat_weight_matrix_positions_num_vec_ptr;
	
	my $concat_dirs_num = scalar(@concat_dirs_vec);

	open(COMMON_OUT_FILE, ">$concat_common_out_file_path") or die "ConcatOutFiles could not open out file: $concat_common_out_file_path\n";
	
	
	my $collected_dir_num = 0;
	my $line;
	
	for (my $cur_dir_num = 0; $cur_dir_num < $concat_dirs_num; ++$cur_dir_num)
	{
		my $cur_concat_dirs = $concat_dirs_vec[$cur_dir_num];
		my $cur_concat_appearences = $concat_appearences_vec[$cur_dir_num];
		my $cur_concat_weight_matrix_positions_num= $concat_weight_matrix_positions_num_vec[$cur_dir_num];
		
		
		for (my $cur_cv_group = 0; $cur_cv_group < $num_of_cv_groups; ++$cur_cv_group)
		{
		
			my $cur_run_out_path = $cur_concat_dirs . "/CV_" . $cur_cv_group . "/" . $concat_run_out_file_name;
			
			if (!(-e $cur_run_out_path))
			{
				 print STDOUT "File Does not exist: $cur_run_out_path\n";
			}
			else
			{
				++$collected_dir_num;

				print STDOUT "collect dir num: $cur_dir_num , name: $cur_concat_dirs\n";
				open(CUR_INLFILE, $cur_run_out_path) or die "ConcatOutFiles could not open in file: $cur_run_out_path\n";
				
				while ( ($line = <CUR_INLFILE>) )
				{
					#chomp($line);
					chomp($cur_concat_weight_matrix_positions_num);
					chomp($cur_concat_appearences);
					$line = "$cur_concat_appearences" ."\t" . $line;
					$line = "$cur_concat_weight_matrix_positions_num" ."\t" . $line;
					$line = "$cur_cv_group" . "\t" . $line . "\n";
					$line = "$cur_dir_num" . "\t" . $line . "\n";
					
					print COMMON_OUT_FILE $line;
				}
				
				close(CUR_INLFILE);
				print STDOUT "		done collect dir: $cur_concat_dirs CV : $cur_cv_group  \n";
			}
		}
		print STDOUT "done collect dir ($cur_dir_num): $cur_concat_dirs\n";
		
	}
	close(COMMON_OUT_FILE);
	
	print "\nCollected $collected_dir_num dirs (out of $concat_dirs_num)\n\n";
}


__DATA__

Usage: 

-collect_likelihood <> collect likelihood

-collect_set <train/test> defualt test

-motif_list_file <file_name> defualt all_tf.txt

-cv_num <#> defualt is 5

---------------------------------------------------------------------------------
  
  

