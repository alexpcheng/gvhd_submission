#!/usr/bin/perl

use strict;

#require "$ENV{PERL_HOME}/Lib/learn_train_and_cal_test_likelihood_helper.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $MAP_FILE_NAME                                                            = "FEATURE_GXW_2_LOGO.map";
my $FMM_TABULAR_FEATURE_FILE_NAME                                           = "tmp_fmm_features_logo_tab.txt";

my $space = "___SPACE___";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my $feature_weight_matrix_in_file               = $ARGV[0];



# getting the flags
my %args = &load_args(\@ARGV);
my $logo_output_file                             = &get_arg("o", "fmm_logo.jpg", \%args);


#my $feature_weight_matrix_in_file                                            = &get_arg("feature_weight_matrix_in_file", "", \%args);
my $weight_2_logo_height_method_type                                         = &get_arg("weight_2_logo_height_method_type", "FeatureExpectations", \%args);
my $feature_wm_logo_type                                                     = &get_arg("feature_wm_logo_type", "LogoCompressedBlocks", \%args);

my $logo_matrix_output_file                                                  = &get_arg("logo_matrix_output_file", "fmm_logo_weight_matrix.gxw", \%args);
my $show_only_features_that_agree_with_feature                               = &get_arg("show_only_features_that_agree_with_feature", "", \%args);
my $add_all_single_nt_features                                               = &get_arg("add_all_single_nt_features", "true", \%args);

my $wm_logo_image_height                                                     = &get_arg("wm_logo_image_height", 1200, \%args);
my $wm_logo_image_width                                                      = &get_arg("wm_logo_image_width", 0, \%args);
my $wm_logo_image_char_width                                                 = &get_arg("wm_logo_image_char_width", 120, \%args);
my $wm_logo_image_char_horizontal_spacing                                    = &get_arg("wm_logo_image_char_horizontal_spacing", 20, \%args);
my $draw_only_features_over_more_than_one_position                           = &get_arg("draw_only_features_over_more_than_one_position", "false", \%args);


my $feature_loopy_inference_calibrated_node_percent_tresh_token              = &get_arg("feature_loopy_inference_calibrated_node_percent_tresh_token", 1, \%args);
my $feature_loopy_inference_calibration_tresh_token                          = &get_arg("feature_loopy_inference_calibration_tresh_token", 0.001, \%args);
my $feature_loopy_inference_max_iterations_token                             = &get_arg("feature_loopy_inference_max_iterations_token", 1000, \%args);

my $feature_loopy_inference_potential_type_token                             = &get_arg("feature_loopy_inference_potential_type_token", "CpdPotential", \%args);
my $feature_loopy_inference_distance_method_type_token                       = &get_arg("feature_loopy_inference_distance_method_type_token", "DmNormLInf", \%args);
my $feature_loopy_inference_use_max_spanning_trees_reduction_token           = &get_arg("feature_loopy_inference_use_max_spanning_trees_reduction_token", "true", \%args);

my $feature_loopy_inference_use_gbp_token                                    = &get_arg("feature_loopy_inference_use_gbp_token", "true", \%args);
my $feature_loopy_inference_use_only_exact                                   = &get_arg("feature_loopy_inference_use_only_exact", "false", \%args);
my $feature_loopy_inference_iter_log_token                                   = &get_arg("feature_loopy_inference_iter_log_token", "Out_cilque_graph_iter.log", \%args);

my $feature_loopy_inference_success_calibrated_node_percent_tresh_token      = &get_arg("feature_loopy_inference_success_calibrated_node_percent_tresh_token", 0.95, \%args);
my $feature_loopy_inference_success_calibration_tresh_token                  = &get_arg("feature_loopy_inference_success_calibration_tresh_token", 0.02, \%args);
my $feature_loopy_inference_calibration_method_type                          = &get_arg("feature_loopy_inference_calibration_method_type", "SynchronicBP", \%args);
my $feature_loopy_inference_average_messages_in_message_update               = &get_arg("feature_loopy_inference_average_messages_in_message_update", "false", \%args);

my $wm_logo_pixle_draw_thresh                                                = &get_arg("wm_logo_pixle_draw_thresh", 0, \%args);

my $wm_fill_feature_background                                               = &get_arg("wm_fill_feature_background", "true", \%args);
my $wm_feature_connect_draw_mode                                             = &get_arg("wm_feature_connect_draw_mode", "LineConnectedBoxs", \%args);

my $draw_only_k_strongest_features                                           = &get_arg("draw_only_k_strongest_features", "-1", \%args);

my $draw_single_position_features_at_the_top                                 = &get_arg("draw_single_position_features_at_the_top", "false", \%args);

my $save_xml_name                                                                 = &get_arg("save_xml_name", "", \%args);


print STDOUT "---------------------------------params: ----------------------------------------\n";
print STDOUT "---- flags: -----\n";
print STDOUT "feature_weight_matrix_in_file:$feature_weight_matrix_in_file\n";
print STDOUT "logo_output_file:$logo_output_file\n";


print STDOUT "weight_2_logo_height_method_type:$weight_2_logo_height_method_type\n";
print STDOUT "feature_wm_logo_type:$feature_wm_logo_type\n";


print STDOUT "logo_matrix_output_file:$logo_matrix_output_file\n";
print STDOUT "show_only_features_that_agree_with_feature:$show_only_features_that_agree_with_feature\n";
print STDOUT "add_all_single_nt_features:$add_all_single_nt_features\n";

print STDOUT "wm_logo_image_height:$wm_logo_image_height\n";
print STDOUT "wm_logo_image_width:$wm_logo_image_width\n";
print STDOUT "wm_logo_image_char_width:$wm_logo_image_char_width\n";
print STDOUT "wm_logo_image_char_horizontal_spacing:$wm_logo_image_char_horizontal_spacing\n";
print STDOUT "draw_only_features_over_more_than_one_position:$draw_only_features_over_more_than_one_position\n";
print STDOUT "wm_logo_pixle_draw_thresh:$wm_logo_pixle_draw_thresh\n";



print STDOUT "feature_loopy_inference_calibrated_node_percent_tresh_token:$feature_loopy_inference_calibrated_node_percent_tresh_token\n";
print STDOUT "feature_loopy_inference_calibration_tresh_token:$feature_loopy_inference_calibration_tresh_token\n";
print STDOUT "feature_loopy_inference_max_iterations_token:$feature_loopy_inference_max_iterations_token\n";

print STDOUT "feature_loopy_inference_potential_type_token:$feature_loopy_inference_potential_type_token\n";
print STDOUT "feature_loopy_inference_distance_method_type_token:$feature_loopy_inference_distance_method_type_token\n";
print STDOUT "feature_loopy_inference_use_max_spanning_trees_reduction_token:$feature_loopy_inference_use_max_spanning_trees_reduction_token\n";

print STDOUT "feature_loopy_inference_use_gbp_token:$feature_loopy_inference_use_gbp_token\n";
print STDOUT "feature_loopy_inference_use_only_exact:$feature_loopy_inference_use_only_exact\n";
print STDOUT "feature_loopy_inference_iter_log_token:$feature_loopy_inference_iter_log_token\n";

print STDOUT "feature_loopy_inference_success_calibrated_node_percent_tresh_token:$feature_loopy_inference_success_calibrated_node_percent_tresh_token\n";
print STDOUT "feature_loopy_inference_success_calibration_tresh_token:$feature_loopy_inference_success_calibration_tresh_token\n";
print STDOUT "feature_loopy_inference_calibration_method_type:$feature_loopy_inference_calibration_method_type\n";
print STDOUT "feature_loopy_inference_average_messages_in_message_update:$feature_loopy_inference_average_messages_in_message_update\n";

print STDOUT "wm_fill_feature_background:$wm_fill_feature_background\n";
print STDOUT "wm_feature_connect_draw_mode:$wm_feature_connect_draw_mode\n";

print STDOUT "draw_only_k_strongest_features:$draw_only_k_strongest_features\n";
print STDOUT "draw_single_position_features_at_the_top:$draw_single_position_features_at_the_top\n";

print STDOUT "save_xml_name:$save_xml_name\n";


print STDOUT "--------------------------------------------------------------------------------\n\n";


my $wm2logo_exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/feature_gxw2logo.map");


$wm2logo_exec_str .= &AddStringProperty("FEATURE_WEIGHT_MATRIX_IN_FILE", $feature_weight_matrix_in_file);
$wm2logo_exec_str .= &AddStringProperty("WEIGHT_2_LOGO_HEIGHT_METHOD_TYPE", $weight_2_logo_height_method_type);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_WM_LOGO_TYPE", $feature_wm_logo_type);

$wm2logo_exec_str .= &AddStringProperty("LOGO_OUTPUT_FILE", $FMM_TABULAR_FEATURE_FILE_NAME);
$wm2logo_exec_str .= &AddStringProperty("LOGO_MATRIX_OUTPUT_FILE", $logo_matrix_output_file);
$wm2logo_exec_str .= &AddStringProperty("SHOW_ONLY_FEATURES_THAT_AGREE_WITH_FEATURE", $show_only_features_that_agree_with_feature);
if ($add_all_single_nt_features == 1)
{
  $add_all_single_nt_features = "true";
}
$wm2logo_exec_str .= &AddStringProperty("ADD_ALL_SINGLE_NT_FEATURES", $add_all_single_nt_features);

$wm2logo_exec_str .= &AddStringProperty("WM_LOGO_IMAGE_HEIGHT", $wm_logo_image_height);
$wm2logo_exec_str .= &AddStringProperty("WM_LOGO_IMAGE_WIDTH", $wm_logo_image_width);
$wm2logo_exec_str .= &AddStringProperty("WM_LOGO_IMAGE_CHAR_WIDTH", $wm_logo_image_char_width);
$wm2logo_exec_str .= &AddStringProperty("WM_LOGO_IMAGE_CHAR_HORIZONTAL_SPACING", $wm_logo_image_char_horizontal_spacing);

#print STDERR "DEBUG: DRAW_ONLY_FEATURES_OVER_MORE_THAN_ONE_POSITION = $draw_only_features_over_more_than_one_position\n";
$wm2logo_exec_str .= &AddStringProperty("DRAW_ONLY_FEATURES_OVER_MORE_THAN_ONE_POSITION", $draw_only_features_over_more_than_one_position);
$wm2logo_exec_str .= &AddStringProperty("WM_LOGO_PIXLE_DRAW_THRESH", $wm_logo_pixle_draw_thresh);


$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $feature_loopy_inference_calibrated_node_percent_tresh_token);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_TRESH_TOKEN", $feature_loopy_inference_calibration_tresh_token);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_MAX_ITERATIONS_TOKEN", $feature_loopy_inference_max_iterations_token);

$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_POTENTIAL_TYPE_TOKEN", $feature_loopy_inference_potential_type_token);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_DISTANCE_METHOD_TYPE_TOKEN", $feature_loopy_inference_distance_method_type_token);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_MAX_SPANNING_TREES_REDUCTION_TOKEN", $feature_loopy_inference_use_max_spanning_trees_reduction_token);

$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_GBP_TOKEN", $feature_loopy_inference_use_gbp_token);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_USE_ONLY_EXACT", $feature_loopy_inference_use_only_exact);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_ITER_LOG_TOKEN", $feature_loopy_inference_iter_log_token);

$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATED_NODE_PERCENT_TRESH_TOKEN", $feature_loopy_inference_success_calibrated_node_percent_tresh_token);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_SUCCESS_CALIBRATION_TRESH_TOKEN", $feature_loopy_inference_success_calibration_tresh_token);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_CALIBRATION_METHOD_TYPE", $feature_loopy_inference_calibration_method_type);
$wm2logo_exec_str .= &AddStringProperty("FEATURE_LOOPY_INFERENCE_AVERAGE_MESSAGES_IN_MESSAGE_UPDATE", $feature_loopy_inference_average_messages_in_message_update);

$wm2logo_exec_str .= &AddStringProperty("WM_FILL_FEATURE_BACKGROUND", $wm_fill_feature_background);
$wm2logo_exec_str .= &AddStringProperty("WM_FEATURE_CONNECT_DRAW_MODE", $wm_feature_connect_draw_mode);

$wm2logo_exec_str .= &AddStringProperty("DRAW_ONLY_K_STRONGEST_FEATURES", $draw_only_k_strongest_features);

if ($draw_single_position_features_at_the_top == 1)
{
  $draw_single_position_features_at_the_top = "true";
}

$wm2logo_exec_str .= &AddStringProperty("DRAW_SINGLE_POSITION_FEATURES_AT_THE_TOP", $draw_single_position_features_at_the_top);



$wm2logo_exec_str = "$wm2logo_exec_str | sed 's/$space/ /g' > $MAP_FILE_NAME ";


#print STDERR "$wm2logo_exec_str\n";

#print STDERR "before remove map file\n";
if (-e $MAP_FILE_NAME)
{
	system ("rm $MAP_FILE_NAME");
}

#print STDERR "before remove (1) $FMM_TABULAR_FEATURE_FILE_NAME \n" ;
#`rm $FMM_TABULAR_FEATURE_FILE_NAME;`; 
#print STDERR "before bind map file\n";

#print STDERR "before run map file\n";
#print STDERR "$ENV{GENIE_EXE} $MAP_FILE_NAME\n";

if ($save_xml_name ne "")
{
  &RunGenie($wm2logo_exec_str, 0, $MAP_FILE_NAME, "", "", $save_xml_name);
}
else
{
  &RunGenie($wm2logo_exec_str, 0, $MAP_FILE_NAME, "", "", "");
}


#print STDERR "fmm_tab_logo2fmm_logo.pl -o $logo_output_file -i $FMM_TABULAR_FEATURE_FILE_NAME -w $wm_logo_image_width  -h $wm_logo_image_height -cw $wm_logo_image_char_width -cs $wm_logo_image_char_horizontal_spacing\n";

#-w $wm_logo_image_width  -h $wm_logo_image_height -cw $wm_logo_image_char_width -cs $wm_logo_image_char_horizontal_spacing

system ("fmm_tab_logo2fmm_logo.pl -o $logo_output_file -i $FMM_TABULAR_FEATURE_FILE_NAME");

#print STDERR "before remove (2) $FMM_TABULAR_FEATURE_FILE_NAME \n" ;
#`rm $FMM_TABULAR_FEATURE_FILE_NAME;`; 

__DATA__

Usage: 

----------------------------- parameters -------------------------------------

gxw2fmm_logo.pl <feature_weight_matrix_in_file>

----------------------------- flags -------------------------------------

	-o <file name> default fmm_logo.jpg


	-weight_2_logo_height_method_type <UniqueFeatureExpectations / ExponentialOfWeight / FeatureExpectations / OnlyPositiveWeights> default FeatureExpectations
	-feature_wm_logo_type <LogoCompressedBlocks> default LogoCompressedBlocks

	-logo_matrix_output_file <str> default "fmm_logo_weight_matrix.gxw"
	-show_only_features_that_agree_with_feature <str> default ""
	-add_all_single_nt_features <true / false > default true

	-wm_logo_image_height <#> defualt 1200
	-wm_logo_image_width <#> defualt 0
	-wm_logo_image_char_width <#> defualt 120
	-wm_logo_image_char_horizontal_spacing <#> defualt 20
	-draw_only_features_over_more_than_one_position <true / false > default false
	-wm_logo_pixle_draw_thresh <#> defualt 0

	-feature_loopy_inference_calibrated_node_percent_tresh_token <#> default 1
	-feature_loopy_inference_calibration_tresh_token <double> default 0.001
	-feature_loopy_inference_max_iterations_token <double> default 1000
	-feature_loopy_inference_potential_type_token <> default CpdPotential
	-feature_loopy_inference_distance_method_type_token <> default DmNormLInf
	-feature_loopy_inference_use_max_spanning_trees_reduction_token <true / false > default true
	-feature_loopy_inference_use_gbp_token <true / false > default true
	-feature_loopy_inference_use_only_exact <true / false > default false
	-feature_loopy_inference_iter_log_token <log file name> default Out_cilque_graph_iter.log
	-feature_loopy_inference_success_calibrated_node_percent_tresh_token <double> default0.95
	-feature_loopy_inference_success_calibration_tresh_token <double> default 0.02
	-feature_loopy_inference_calibration_method_type <> default AsynchronyRBP
	-feature_loopy_inference_average_messages_in_message_update <true / false > default false

	-wm_fill_feature_background <true / false > default true
	-wm_feature_connect_draw_mode <LineConnectedBoxs / BoxAroundFeature> default LineConnectedBoxs
	
	-draw_only_k_strongest_features <positive int> if parameter is not given then no limitation is imposed. this is the default
	-draw_single_position_features_at_the_top <true / false > default false, draws the single position features in the top of the log

For Debug:

-save_xml_name if a file name is provided it will save the gxw2tab run file
