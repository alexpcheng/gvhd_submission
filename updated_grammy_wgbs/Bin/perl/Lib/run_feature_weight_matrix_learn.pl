#! /usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";
require "$ENV{PERL_HOME}/Lib/xml_util.pl";
require "$ENV{PERL_HOME}/System/q_util.pl";

my $train_procedure_type_token = "TRAINING_PROCEDURE_TYPE_TOKEN"; 
my $step_token = "STEP_TOKEN";
my $train_procedure_params_token = "TRAIN_PROCEDURE_PARAMETERS_TOKEN";

my $feature_max_positions_num_token ="LETTERS_AT_POSITION_FEATURE_MAX_POSITIONS_NUM_TOKEN";
my $filter_count_percent_token ="INITIAL_FILTER_COUNT_PERCENT_THRESH_TOKEN";
my $filter_p_val_thresh_token ="INITIAL_FILTER_P_VALUE_THRESH_TOKEN";
my $max_param_token ="MAX_FEATURES_PARAMETERS_NUM_TOKEN";
my $max_iter_token ="MAX_ITERATIONS_NUM_TOKEN";
my $weight_start_point_strategy_token ="LEARNING_WEIGHT_START_POINT_STRATEGY";
my $sum_weights_penalty_coeff_token ="SUM_WEIGHTS_PENALTY_COEFFICIENT_TOKEN";

my @feature_max_positions_num_vec = (1,2,3);
my @filter_count_percent_vec = (0.05,0.1);
my @filter_p_val_thresh_vec = (0.1,0.25);
my @max_param_vec = (5,10,15,20);
my @sum_weights_penalty_coeff_vec = (0.3,0.2,0.1,0.05,0.01);

my $feature_wheight_matrix_exe = "~/Develop/genie/Programs/map_learn";
my $num_of_sec_between_q_monitoring = 2;


sub run_feature_weight_matrix_learn_with_params
{
  my ($template_map_file,$infile_prefix,$outfile_prefix,$group_num, $out_results_file_name, $is_delete_tmp_files) = @_;

  open(INFILE, "<$template_map_file") or die "could not open in file: $template_map_file\n";
  my $org_map_str="";
  while (<INFILE>)
  {
      $org_map_str = $org_map_str . $_;
  }
  close(INFILE);
  
  my $updated_xml_str = $org_map_str;
  
  `make_labeled_cross_validation_sets.pl $infile_prefix -o $outfile_prefix -g $group_num;`;

  #&create_labeled_cross_validation_sets($infile_prefix,$outfile_prefix,$group_num, "");
  
  my $append_due_not_first_collect = 0;
  
  my $feature_max_positions_num;
  my $filter_count_percent;
  my $filter_p_val_thresh; 
  my $max_param;
  my $sum_weights_penalty_coeff;
  my @cur_cmd_lines;

  my $h = 0;
  foreach $feature_max_positions_num (@feature_max_positions_num_vec)
    {
      $updated_xml_str = &set_filed_in_xml_str($updated_xml_str,$feature_max_positions_num_token,$feature_max_positions_num,($step_token));

      foreach $filter_count_percent (@filter_count_percent_vec)
	{
	  $updated_xml_str = &set_filed_in_xml_str($updated_xml_str,$filter_count_percent_token,$filter_count_percent,($step_token));
	
	  foreach $filter_p_val_thresh (@filter_p_val_thresh_vec)
	    {
	      $updated_xml_str = &set_filed_in_xml_str($updated_xml_str,$filter_p_val_thresh_token,$filter_p_val_thresh,($step_token));
	
	      foreach $max_param (@max_param_vec)
		{
		  $updated_xml_str = &set_filed_in_xml_str($updated_xml_str,$max_param_token,$max_param,($step_token));
		
		  foreach $sum_weights_penalty_coeff (@sum_weights_penalty_coeff_vec)
		    {
		      $updated_xml_str = &set_filed_in_xml_str($updated_xml_str,$sum_weights_penalty_coeff_token,$sum_weights_penalty_coeff,($step_token));
		
		      print "RUNNING ITERATION ($h): $feature_max_positions_num , $filter_count_percent , $filter_p_val_thresh , $max_param , $sum_weights_penalty_coeff \n";
		      ++$h;
		
		      undef @cur_cmd_lines;
		
		      for (my $i = 0; $i < $group_num; ++$i)
			{
			  # copying the map file
			  my $cur_dir = $outfile_prefix . "_" . $i;
			  my $cur_map_file = $cur_dir . "/" . $template_map_file;
			  open(OUT_MAP_FILE, ">$cur_map_file") or die "could not open out map file: $cur_map_file\n";
			  print OUT_MAP_FILE $updated_xml_str;
			  close(OUT_MAP_FILE);
			
			  # creating the command line
			  $cur_cmd_lines[$i] =  " cd $cur_dir; $feature_wheight_matrix_exe $template_map_file; cd ../ ;"		
			
			}
		
		      #running in parallel $group_num
		      &run_parallel_q_processes(\@cur_cmd_lines, $group_num, $num_of_sec_between_q_monitoring,$is_delete_tmp_files));
			
		      #collecting 
		      my $out_dir_prefix = $outfile_prefix . "_";
		
		     `collect_feature_learn_cv_results.pl $out_dir_prefix  -a $append_due_not_first_collect  -g $group_num  -o $out_results_file_name`;
			
		
		
		      if ($append_due_not_first_collect  == 0)
			{
			  $append_due_not_first_collect  = 1;
			}
			
		    }
		
		}
	
	    }
	
	}
    }


  #my $updated_xml_str = &set_filed_in_xml_str($org_map_str,$feature_max_positions_num_token,$new_value,($step_token));
  
  #my $field_str = &get_filed_in_xml_str($org_map_str,$train_procedure_type_token,$new_value,($step_token,$train_procedure_params_token ));


}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0 and $ARGV[0] ne "--help")
{
  my %args = load_args(\@ARGV);

  run_feature_weight_matrix_learn_with_params($ARGV[0],$ARGV[1],
				       get_arg("o", $ARGV[1], \%args),
				       get_arg("g", 5, \%args),
				       get_arg("r", "CV_OUT.txt", \%args),
				       get_arg("d", 1, \%args)	     );

  print "END make_labeled_cross_validation_sets";
}
else
{
  print "Usage: run_feature_weight_matrix_learn.pl map_file.map input_file_prefix \n\n";
  print "      -o <output stub>: prefix of the output dirs (default is same as input file)\n";
  print "      -g <cv number>:   number of cross validation groups to make (default 5)\n\n";
  print "      -r <output result file name>: results file name\n";
  print "      -d <0/1>: delete out and error tmp files (default 1)\n";
}
