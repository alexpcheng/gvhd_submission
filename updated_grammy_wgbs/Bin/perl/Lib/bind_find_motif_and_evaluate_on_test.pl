#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/run_feature_weight_helper.pl";

#file consts
my $space = "___SPACE___";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

# getting  the parameters
my $out_file                          = $ARGV[0];
my $background_matrix_file            = $ARGV[1];
my $matrix_name                       = $ARGV[2];
;

# getting the flags
 my %args = &load_args(\@ARGV);

my $letters_at_position_feature_max_positions_num                  = &get_arg("l", 2, \%args);
my $sum_weights_penalty_coefficient                                = &get_arg("c", 0.1, \%args);
my $max_features_parameters_num                                    = &get_arg("max_features_parameters_num", 72, \%args);

my $use_also_reverse_complement_of_un_aligned_seqs                = &get_arg("use_also_reverse_complement_of_un_aligned_seqs", "true", \%args);
my $motif_finder_motif_length                                     = &get_arg("motif_finder_motif_length", 8, \%args);
my $motif_finder_max_output_motifs_num                            = &get_arg("motif_finder_max_output_motifs_num", 12, \%args);

my $motif_finder_seed_length                                      = &get_arg("motif_finder_seed_length", 8, \%args);
my $motif_finder_seed_right_padding                               = &get_arg("motif_finder_seed_right_padding", 0, \%args);
my $motif_finder_seed_left_padding                                = &get_arg("motif_finder_seed_left_padding", 0, \%args);
my $motif_finder_seed_exact_parent_seqs_fraction_thresh           = &get_arg("motif_finder_seed_exact_parent_seqs_fraction_thresh", 0.05, \%args);
my $motif_finder_mis_match_thresh_for_un_exact_seed               = &get_arg("motif_finder_mis_match_thresh_for_un_exact_seed", 2, \%args);
my $motif_finder_seed_un_exact_parent_seqs_fraction_thresh        = &get_arg("motif_finder_seed_un_exact_parent_seqs_fraction_thresh", 0.1, \%args);


my $motif_finder_init_seqs_max_hits_per_seq                      = &get_arg("motif_finder_init_seqs_max_hits_per_seq", 1, \%args);
my $motif_finder_max_iterations                                  = &get_arg("motif_finder_max_iterations", 10, \%args);
my $motif_finder_test_for_convergence                            = &get_arg("motif_finder_test_for_convergence", "true", \%args);
my $motif_finder_convergence_thresh                              = &get_arg("motif_finder_convergence_thresh", 0.05, \%args);
my $motif_finder_sample_size_from_each_seq                       = &get_arg("motif_finder_sample_size_from_each_seq", 1, \%args);
my $em_best_hit_motif_finder_sample_method_type                  = &get_arg("em_best_hit_motif_finder_sample_method_type", "SampleBestProbabilitySeqs", \%args);
my $motif_em_iter_log_out_file_name                              = &get_arg("motif_em_iter_log_out_file_name", "motif_em_iter_log.log", \%args);
my $feature_motif_finder_output_seqs_files_prefix                = &get_arg("feature_motif_finder_output_seqs_files_prefix", "Out_motif_feature_seqs", \%args);
my $pssm_motif_finder_output_seqs_files_prefix                   = &get_arg("pssm_motif_finder_output_seqs_files_prefix", "Out_motif_pssm_seqs", \%args);

my $motif_finder_mask_pos_of_found_motifs                        = &get_arg("motif_finder_mask_pos_of_found_motifs", "true", \%args);
my $motif_finder_mask_pos_of_found_motifs_factor                 = &get_arg("motif_finder_mask_pos_of_found_motifs_factor", 0.9, \%args);
my $motif_masking_method_type                                    = &get_arg("motif_masking_method_type", "MaskBestHitInEachSeq", \%args);

if ($train_background_matrix_file ne "")
{
	my $train_background_matrix_file                                 = &get_arg("train_background_matrix_file", "test_background_data.fa", \%args);
}
print STDOUT "---------------------------------params: ----------------------------------------\n";
print STDOUT "out_file:$out_file\n";
print STDOUT "background_matrix_file:$background_matrix_file\n";
print STDOUT "matrix_name:$matrix_name\n";
print STDOUT "---- flags: -----\n";
print STDOUT "letters_at_position_feature_max_positions_num:$letters_at_position_feature_max_positions_num\n";
print STDOUT "sum_weights_penalty_coefficient:$sum_weights_penalty_coefficient\n";
print STDOUT "max_features_parameters_num:$max_features_parameters_num\n";

print STDOUT "use_also_reverse_complement_of_un_aligned_seqs:$use_also_reverse_complement_of_un_aligned_seqs\n";
print STDOUT "motif_finder_motif_length:$motif_finder_motif_length\n";
print STDOUT "motif_finder_max_output_motifs_num:$motif_finder_max_output_motifs_num\n";

print STDOUT "motif_finder_seed_length:$motif_finder_seed_length\n";
print STDOUT "motif_finder_seed_right_padding:$motif_finder_seed_right_padding\n";
print STDOUT "motif_finder_seed_left_padding:$motif_finder_seed_left_padding\n";
print STDOUT "motif_finder_seed_exact_parent_seqs_fraction_thresh:$motif_finder_seed_exact_parent_seqs_fraction_thresh\n";
print STDOUT "motif_finder_mis_match_thresh_for_un_exact_seed:$motif_finder_mis_match_thresh_for_un_exact_seed\n";
print STDOUT "motif_finder_seed_un_exact_parent_seqs_fraction_thresh:$motif_finder_seed_un_exact_parent_seqs_fraction_thresh\n";

print STDOUT "motif_finder_init_seqs_max_hits_per_seq:$motif_finder_init_seqs_max_hits_per_seq\n";
print STDOUT "motif_finder_max_iterations:$motif_finder_max_iterations\n";
print STDOUT "motif_finder_test_for_convergence:$motif_finder_test_for_convergence\n";
print STDOUT "motif_finder_convergence_thresh:$motif_finder_convergence_thresh\n";
print STDOUT "motif_finder_sample_size_from_each_seq:$motif_finder_sample_size_from_each_seq\n";
print STDOUT "em_best_hit_motif_finder_sample_method_type:$em_best_hit_motif_finder_sample_method_type\n";
print STDOUT "motif_em_iter_log_out_file_name:$motif_em_iter_log_out_file_name\n";
print STDOUT "feature_motif_finder_output_seqs_files_prefix:$feature_motif_finder_output_seqs_files_prefix\n";
print STDOUT "pssm_motif_finder_output_seqs_files_prefix:$pssm_motif_finder_output_seqs_files_prefix\n";
print STDOUT "motif_finder_mask_pos_of_found_motifs:$motif_finder_mask_pos_of_found_motifs\n";
print STDOUT "motif_finder_mask_pos_of_found_motifs_factor:$motif_finder_mask_pos_of_found_motifs_factor\n";
print STDOUT "motif_masking_method_type:$motif_masking_method_type\n";
print STDOUT "train_background_matrix_file:$train_background_matrix_file\n";

print STDOUT "--------------------------------------------------------------------------------\n\n";

	my $find_and_eval_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/find_motif_and_evaluate_on_test.map");

	$find_and_eval_str .= &AddStringProperty("BACKGROUND_MATRIX_FILE", $background_matrix_file);
	$find_and_eval_str .= &AddStringProperty("WEIGHT_MATRIX_NAME", $matrix_name);

	$find_and_eval_str .= &AddStringProperty("LETTERS_AT_POSITION_FEATURE_MAX_POSITIONS_NUM", $letters_at_position_feature_max_positions_num);
	$find_and_eval_str .= &AddStringProperty("SUM_WEIGHTS_PENALTY_COEFFICIENT", $sum_weights_penalty_coefficient);
	$find_and_eval_str .= &AddStringProperty("MAX_FEATURES_PARAMETERS_NUM", $max_features_parameters_num);

	$find_and_eval_str .= &AddStringProperty("USE_ALSO_REVERSE_COMPLEMENT_OF_UN_ALIGNED_SEQS", $use_also_reverse_complement_of_un_aligned_seqs);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_MOTIF_LENGTH", $motif_finder_motif_length);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_MAX_OUTPUT_MOTIFS_NUM", $motif_finder_max_output_motifs_num);


	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_SEED_LENGTH", $motif_finder_seed_length);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_SEED_RIGHT_PADDING", $motif_finder_seed_right_padding);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_SEED_LEFT_PADDING", $motif_finder_seed_left_padding);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_SEED_EXACT_PARENT_SEQS_FRACTION_THRESH", $motif_finder_seed_exact_parent_seqs_fraction_thresh);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_MIS_MATCH_THRESH_FOR_UN_EXACT_SEED", $motif_finder_mis_match_thresh_for_un_exact_seed);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_SEED_UN_EXACT_PARENT_SEQS_FRACTION_THRESH", $motif_finder_seed_un_exact_parent_seqs_fraction_thresh);

	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_INIT_SEQS_MAX_HITS_PER_SEQ", $motif_finder_init_seqs_max_hits_per_seq);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_MAX_ITERATIONS", $motif_finder_max_iterations);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_TEST_FOR_CONVERGENCE", $motif_finder_test_for_convergence);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_CONVERGENCE_THRESH", $motif_finder_convergence_thresh);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_SAMPLE_SIZE_FROM_EACH_SEQ", $motif_finder_sample_size_from_each_seq);
	$find_and_eval_str .= &AddStringProperty("EM_BEST_HIT_MOTIF_FINDER_SAMPLE_METHOD_TYPE", $em_best_hit_motif_finder_sample_method_type);
	$find_and_eval_str .= &AddStringProperty("MOTIF_EM_ITER_LOG_OUT_FILE_NAME", $motif_em_iter_log_out_file_name);
	$find_and_eval_str .= &AddStringProperty("FEATURE_MOTIF_FINDER_OUTPUT_SEQS_FILES_PREFIX", $feature_motif_finder_output_seqs_files_prefix);
	$find_and_eval_str .= &AddStringProperty("PSSM_MOTIF_FINDER_OUTPUT_SEQS_FILES_PREFIX", $pssm_motif_finder_output_seqs_files_prefix);

	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_MASK_POS_OF_FOUND_MOTIFS", $motif_finder_mask_pos_of_found_motifs);
	$find_and_eval_str .= &AddStringProperty("MOTIF_FINDER_MASK_POS_OF_FOUND_MOTIFS_FACTOR", $motif_finder_mask_pos_of_found_motifs_factor);
	$find_and_eval_str .= &AddStringProperty("MOTIF_MASKING_METHOD_TYPE", $motif_masking_method_type);

	$find_and_eval_str .= &AddStringProperty("TRAIN_BACKGROUND_DATA_FILE_SEQ", $train_background_matrix_file);



	my $ret_exec_str = "$find_and_eval_str | sed 's/$space/ /g' > $out_file";

#DEBUG
print STDERR "$ret_exec_str\n";
	
`$ret_exec_str`;

__DATA__

Usage: 

There are 3 modes of run:
1. running cv
2. collecting cv results
3. calculate sequences features indications for one of the CV dirs learned model

----------------------------- 1. running cv -------------------------------------
bind_find_motif_and_evaluate_on_test.pl <out file> <background_matrix_file> <matrix_name> 

	-l <letters_at_position_feature_max_positions_num>
	-c <sum_weights_penalty_coefficient>
	
	DEBUG - and more flags the doc will be added soon ...
