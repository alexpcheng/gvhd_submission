#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

# getting  the parameters
my $input_track_file                           = $ARGV[0];
my $chromosome_features_config_analysis_type   = $ARGV[1];

# getting the flags
my %args = &load_args(\@ARGV);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $input_track_name                                                        = &get_arg("input_track_name", "input_track", \%args);
my $split_min_length                                                        = &get_arg("split_min_length", 294, \%args);
my $after_split_output_file                                                 = &get_arg("after_split_output_file", "ChromosomeFeatureTrack_AfterSplit.gxt", \%args);
my $join_max_distance                                                       = &get_arg("join_max_distance", 20, \%args);
my $after_join_output_file                                                  = &get_arg("after_join_output_file", "ChromosomeFeatureTrack_AfterJoin.gxt", \%args);
my $work_in_fuzzy_mode                                                      = &get_arg("work_in_fuzzy_mode", "true", \%args);
my $feature_true_length                                                     = &get_arg("feature_true_length", 147, \%args);
my $feature_global_fuzziness                                                = &get_arg("feature_global_fuzziness", 2, \%args);
my $sliding_window_length                                                   = &get_arg("sliding_window_length", 1000, \%args);
my $sliding_window_jump                                                     = &get_arg("sliding_window_jump", 50, \%args);
my $output_chromosome_track                                                 = &get_arg("output_chromosome_track", "ChromosomeFeatureTrack_ConfigAnalysis", \%args);
my $output_chromosome_track_type                                            = &get_arg("output_chromosome_track_type", "ChromosomeFeatureTrack", \%args);
my $output_file                                                             = &get_arg("output_file", "ChromosomeFeatureTrack_ConfigAnalysis.gxt", \%args);

my $window_of_computation_method_type                                       = &get_arg("window_of_computation_method_type", "SlidingWindow", \%args);
my $non_overlapping_configs_min_distance                                    = &get_arg("non_overlapping_configs_min_distance", 20, \%args);
my $join_after_analysis_output_file                                         = &get_arg("join_after_analysis_output_file", "ChromosomeFeatureTrack_JoinAfterAnalysisOutputFile.gxt", \%args);
my $compute_which_features_in_best_config                                   = &get_arg("compute_which_features_in_best_config", "true", \%args);
my $join_chromosome_features_method                                         = &get_arg("join_chromosome_features_method", "WeightedMidByFuzzy", \%args);


my $fuzziness_method                                                        = &get_arg("fuzziness_method", "HardFuzzyUsingMid", \%args);
my $independent_cut_specificities_file                                      = &get_arg("independent_cut_specificities_file", "MNase.gxw", \%args);
my $max_edge_exposure                                                       = &get_arg("max_edge_exposure", 20, \%args);
my $feature_cut_protection_dist_file                                        = &get_arg("feature_cut_protection_dist_file", "nucleosome_cut_protection.dist", \%args);
my $length_filtering_dist_file                                              = &get_arg("length_filtering_dist_file", "454_length_filtering.dist", \%args);

my $sequences_file                                                          = &get_arg("sequences_file", "data.fas", \%args);
my $max_feature_length                                                      = &get_arg("max_feature_length", 177, \%args);
my $min_feature_length                                                      = &get_arg("min_feature_length", 127, \%args);
my $cut_distance_from_cut_specificities_start                               = &get_arg("cut_distance_from_cut_specificities_start", 2, \%args);

my $feature_model_file                                                      = &get_arg("feature_model_file", "Nucleosome.gxw", \%args);
my $f_cut_protec_dist_start_offset_from_f_start                             = &get_arg("f_cut_protec_dist_start_offset_from_f_start", 100, \%args);
my $feature_detection_precision                                             = &get_arg("feature_detection_precision", 20, \%args);

my $likelihood_over_configs_output_file_name                                = &get_arg("likelihood_over_configs_output_file_name", "likelihood_over_configs.m", \%args);



print STDERR "---------------------------------params: ----------------------------------------\n";

print STDERR "input_track_file:$input_track_file\n";
print STDERR "chromosome_features_config_analysis_type:$chromosome_features_config_analysis_type\n\n";

print STDERR "input_track_name:$input_track_name\n";
print STDERR "split_min_length:$split_min_length\n";
print STDERR "after_split_output_file:$after_split_output_file\n";
print STDERR "join_max_distance:$join_max_distance\n";
print STDERR "after_join_output_file:$after_join_output_file\n";
print STDERR "work_in_fuzzy_mode:$work_in_fuzzy_mode\n";
print STDERR "feature_true_length:$feature_true_length\n";
print STDERR "feature_global_fuzziness:$feature_global_fuzziness\n";
print STDERR "sliding_window_length:$sliding_window_length\n";
print STDERR "sliding_window_jump:$sliding_window_jump\n";
print STDERR "output_chromosome_track:$output_chromosome_track\n";
print STDERR "output_chromosome_track_type:$output_chromosome_track_type\n";
print STDERR "output_file:$output_file\n";

print STDERR "window_of_computation_method_type:$window_of_computation_method_type\n";
print STDERR "non_overlapping_configs_min_distance:$non_overlapping_configs_min_distance\n";
print STDERR "join_after_analysis_output_file:$join_after_analysis_output_file\n";
print STDERR "compute_which_features_in_best_config:$compute_which_features_in_best_config\n";
print STDERR "join_chromosome_features_method:$join_chromosome_features_method\n";

print STDERR "fuzziness_method:$fuzziness_method\n";
print STDERR "independent_cut_specificities_file:$independent_cut_specificities_file\n";
print STDERR "max_edge_exposure:$max_edge_exposure\n";
print STDERR "feature_cut_protection_dist_file:$feature_cut_protection_dist_file\n";
print STDERR "length_filtering_dist_file:$length_filtering_dist_file\n";

print STDERR "sequences_file:$sequences_file\n";
print STDERR "max_feature_length:$max_feature_length\n";
print STDERR "min_feature_length:$min_feature_length\n";
print STDERR "cut_distance_from_cut_specificities_start:$cut_distance_from_cut_specificities_start\n";
print STDERR "feature_model_file:$feature_model_file\n";
print STDERR "f_cut_protec_dist_start_offset_from_f_start:$f_cut_protec_dist_start_offset_from_f_start\n";
print STDERR "feature_detection_precision:$feature_detection_precision\n";

print STDERR "likelihood_over_configs_output_file_name:$likelihood_over_configs_output_file_name\n";



print STDERR "xml:$xml\n";
print STDERR "run_file:$run_file\n";
print STDERR "save_xml_file:$save_xml_file\n";

print STDERR "--------------------------------------------------------------------------------\n\n";



my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/run_analyze_chromosome_features_configurations.map");

$exec_str .= &AddStringProperty("FILE", $input_track_file);
$exec_str .= &AddStringProperty("CHROMOSOME_FEATURES_CONFIG_ANALYSIS_TYPE", $chromosome_features_config_analysis_type);

$exec_str .= &AddStringProperty("INPUT_TRACK_NAME", $input_track_name);
$exec_str .= &AddStringProperty("SPLIT_MIN_LENGTH", $split_min_length);
$exec_str .= &AddStringProperty("AFTER_SPLIT_OUTPUT_FILE", $after_split_output_file);
$exec_str .= &AddStringProperty("JOIN_MAX_DISTANCE", $join_max_distance);
$exec_str .= &AddStringProperty("AFTER_JOIN_OUTPUT_FILE", $after_join_output_file);
$exec_str .= &AddStringProperty("WORK_IN_FUZZY_MODE", $work_in_fuzzy_mode);
$exec_str .= &AddStringProperty("FEATURE_TRUE_LENGTH", $feature_true_length);
$exec_str .= &AddStringProperty("FEATURE_GLOBAL_FUZZINESS", $feature_global_fuzziness);
$exec_str .= &AddStringProperty("SLIDING_WINDOW_LENGTH", $sliding_window_length);
$exec_str .= &AddStringProperty("SLIDING_WINDOW_JUMP", $sliding_window_jump);
$exec_str .= &AddStringProperty("OUTPUT_CHROMOSOME_TRACK", $output_chromosome_track);
$exec_str .= &AddStringProperty("OUTPUT_CHROMOSOME_TRACK_TYPE", $output_chromosome_track_type);
$exec_str .= &AddStringProperty("OUTPUT_ANALYSIS_FILE", $output_file);
$exec_str .= &AddStringProperty("WINDOW_OF_COMPUTATION_METHOD_TYPE", $window_of_computation_method_type);
$exec_str .= &AddStringProperty("NON_OVERLAPPING_CONFIGS_MIN_DISTANCE", $non_overlapping_configs_min_distance);
$exec_str .= &AddStringProperty("JOIN_AFTER_ANALYSIS_OUTPUT_FILE", $join_after_analysis_output_file);
$exec_str .= &AddStringProperty("COMPUTE_WHICH_FEATURES_IN_BEST_CONFIG", $compute_which_features_in_best_config);
$exec_str .= &AddStringProperty("JOIN_CHROMOSOME_FEATURES_METHOD", $join_chromosome_features_method);

$exec_str .= &AddStringProperty("FUZZINESS_METHOD", $fuzziness_method);
$exec_str .= &AddStringProperty("INDEPENDENT_CUT_SPECIFICITIES_FILE", $independent_cut_specificities_file);
$exec_str .= &AddStringProperty("MAX_EDGE_EXPOSURE", $max_edge_exposure);
$exec_str .= &AddStringProperty("FEATURE_CUT_PROTECTION_DIST_FILE", $feature_cut_protection_dist_file);
$exec_str .= &AddStringProperty("LENGTH_FILTERING_DIST_FILE", $length_filtering_dist_file);

$exec_str .= &AddStringProperty("SEQUENCES_FILE", $sequences_file);
$exec_str .= &AddStringProperty("MAX_FEATURE_LENGTH", $max_feature_length);
$exec_str .= &AddStringProperty("MIN_FEATURE_LENGTH", $min_feature_length);
$exec_str .= &AddStringProperty("CUT_DISTANCE_FROM_CUT_SPECIFICITIES_START", $cut_distance_from_cut_specificities_start);
$exec_str .= &AddStringProperty("FEATURE_MODEL_FILE", $feature_model_file);
$exec_str .= &AddStringProperty("F_CUT_PROTEC_DIST_START_OFFSET_FROM_F_START", $f_cut_protec_dist_start_offset_from_f_start);
$exec_str .= &AddStringProperty("FEATURE_DETECTION_PRECISION", $feature_detection_precision);

$exec_str .= &AddStringProperty("LIKELIHOOD_OVER_CONFIGS_OUTPUT_FILE_NAME", $likelihood_over_configs_output_file_name);



&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file, $save_xml_file);

__DATA__

Usage: 
Analyzing chromosome feature configurations

analyze_chromosome_features_configurations.pl <input_track_file> <chromosome_features_config_analysis_type>

input_track_file = a chromosome feature track in gxw format
chromosome_features_config_analysis_type <BestExplainingConfig/MinConfigsThatExplainData/SumValues/SumValuesPerNt/WindowLength> 
this str determines the analysis that will be perform

The options are:
----------------
1. BestExplainingConfig - Compute the percent of features that the best configuration explains
                          over the running windows.

2. MinConfigsThatExplainData - Compute the minimal number of configurations that is needed to explain all features 
                          over the running windows. NOT IMPLEMETED

3. SumValues - count the feature reads (values)
                          over the running windows.

4. SumValuesPerNt - same like SumValues but normalized in the window length

5. WindowLength - compute the window length (relevant to non-overlapping windows method)

6. NumFeatures - count the features instances (relevant with join option)
                          over the running windows.

7. NumFeaturesPerNt - same like SumValues but normalized in the window length

8. ReadsEntropy - compute the entropy of the reads

9. InputForMatlabLikelihoodOverConfigs - create the input file for matlab analysis of likelihood over configurations

flags:
-----------
     -split_min_length <#> defualt is 294 
			features above this length will be split to two features. 
			negative values will skip this part

     -after_split_output_file <file name> defualt is ChromosomeFeatureTrack_AfterSplit.gxt
	 
     -join_max_distance <#> defualt is 20
			this is the max length between features (including fuziness)
			that can be joined.
			negative values will skip this part

     -after_join_output_file <file name> defualt is ChromosomeFeatureTrack_AfterJoin.gxt

     -work_in_fuzzy_mode <true/false> defualt is true
			this option allow the features to be fuzzy (not fixed to thier input coordinate
			but have some freedom to move). 

     -feature_true_length <#> defualt is 147 
			this is the true length of all features. it means that features longer or shorter
			are not measured accuratlly and hence have some fuzziness ((len-true_len)/2)
			negative values will ignore this source of fuzziness

     -feature_global_fuzziness <#> defualt is 2
			this is a measure of global fuzziness.
			it is related to the belief in the accuracy of meassurment.
			negative values will ignore this.
REMARK: if in fuzzy mode either the true negth need to be positie or the global fuzziness not negative

     -sliding_window_length <#process to use> defualt is 1000
			the window length, for computation over sliding window

     -sliding_window_jump <#process to use> defualt is 50
			the sliding window jump

     -output_file <file name> defualt is ChromosomeFeatureTrack_ConfigAnalysis.gxt 
			name of the output gxw file.

     -window_of_computation_method_type <SlidingWindow/NonOverlapingConfigurationsWindows> defualt SlidingWindow
			the type of windows used for the calculation

     -non_overlapping_configs_min_distance <#> defualt is 20
			if the window method type is NonOverlapingConfigurationsWindows this is the length of the gap for non overlap

     -join_after_analysis_output_file <file name> defualt is ChromosomeFeatureTrack_JoinAfterAnalysisOutputFile.gxt
			gives different types to features in different configs 
			(usefull for BestExplainingConfig / MinConfigsThatExplainData

     -compute_which_features_in_best_config <true/false> defualt is false
			if true will give type 1 to features in best config and 0 to the others
			the output will be at join_after_analysis_output_file

     -join_chromosome_features_method <WeightedMidByFuzzy/MidInCommonFuzzy/SoftJoinToBestExplain> defualt is WeightedMidByFuzzy
			determine thew method in which the features will be joined 
			SoftJoinToBestExplain used with SoftFuzzyCutProbModel

     -fuzziness_method <HardFuzzyUsingMid/SoftFuzzyCutProbModel> default  HardFuzzyUsingMid
			determinse the way the fuzziness work:
				1. HardFuzzyUsingMid - the fuzziness by length relative to the true length and uniform prior
				2. SoftFuzzyCutProbModel - a soft fuziness based on modeling the length filtering,cut protection and cut preferences

     -independent_cut_specificities_file <gxw file name> 
			the gxw of the cutting enzyme (nuclease)

     -max_edge_exposure <#> default 20
			the distance from the edge of a feature from wich the feature is protected from cut

     -feature_cut_protection_dist_file <dist file name>
			the distribution file of the feature protection from cut (see tab2dist)

     -length_filtering_dist_file <dist file name>
			the distribution file of the length filting before sequencing (see tab2dist)

     -sequences_file <sequences fasta file name> defualt data.fas
			this file holds the (chromosomes) sequences on wich the features are annotated (used with SoftFuzzyCutProbModel)

     -max_feature_length <#> defualt 177
			maximum length of feature in the data (usede with SoftFuzzyCutProbModel)

     -min_feature_length <#> defualt 177
			minimum length of feature in the data (usede with SoftFuzzyCutProbModel)

     -cut_distance_from_cut_specificities_start <#> defualt 2
			the number of nucleotide between where the cut specificities model start and the actual cut (used with SoftFuzzyCutProbModel)

     -feature_model_file <file name> default Nucleosome.gxw
			the file for the feature prior (can be uniform) (used with SoftFuzzyCutProbModel)

     -f_cut_protec_dist_start_offset_from_f_start <#> default 100
			 this is the index of the true feature start in the feature_cut_protection_dist (used with SoftFuzzyCutProbModel)

     -feature_detection_precision <#> default 20
			 the is the min distance between joined feature starts (used with SoftFuzzyCutProbModel)

     -likelihood_over_configs_output_file_name <file name> default likelihood_over_configs.m,
			 the name of the out file that is an input file for matlab analysis of data (joined) over configurations


run flags:
----------
   -xml:             print only the xml file
   -run <str>:       Print the stdout and stderr of the program into the file <str>
   -sxml <str>:      Save the xml file into <str>

for future use:
---------------
     -input_track_name <str> defualt is input_track (no need to change)
     -output_chromosome_track <str> defualt is ChromosomeFeatureTrack_ConfigAnalysis (no need to change)
     -output_chromosome_track_type <str> defualt is ChromosomeFeatureTrack (no need to change)
