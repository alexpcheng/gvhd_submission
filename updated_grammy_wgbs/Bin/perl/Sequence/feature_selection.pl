#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";


if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}


my $r = int(rand(100000));
my $tmp_map = "tmp_$r.map";
my $tmp_clu = "tmp_$r.clu";


#
# Loading args:
#

my %args = load_args(\@ARGV);


my $print_map_file = get_arg("map", 0, \%args);
my $log_file = get_arg("log", "", \%args);
my $save_map_file = get_arg("smap", "", \%args);


my $feature_selection_type = get_arg("fs_type", "", \%args);
die "ERROR - feature selection type not given.\n" if ( $feature_selection_type eq "" );
die "ERROR - Unknown or unsupported feature selection type ($feature_selection_type).\n" unless ( $feature_selection_type =~ m/BasedOnPearsonCorrelationBetweenFeatureAndResponse|BasedOnAUCResponseClassifiedByThreshAndRankedByFeature/i );

my $feature_matrix_input_file = get_arg("fmat_input_file", "", \%args);
die "ERROR - input feature matrix file name not given.\n" if ( $feature_matrix_input_file eq "" );

my $feature_matrix_value_type = get_arg("fmat_val_type", "", \%args);
die "ERROR - input feature matrix value type not given.\n" if ( $feature_matrix_value_type eq "" );
die "ERROR - Unknown or unsupported feature value type ($feature_matrix_value_type).\n" unless ( $feature_matrix_value_type =~ m/AnyValue|Double|Int|Boolean|Char|String/i );

my $response_file = get_arg("response_file", "", \%args);
die "ERROR - response values file name not given.\n" if ( $response_file eq "" );

my $selected_features_matrices_files_list_file = get_arg("fs_res_fmat_files_list_file", "", \%args);
die "ERROR - selected features matrices output files list file name not given.\n" if ( $selected_features_matrices_files_list_file eq "" );

my $features_selection_measures_files_list_file = get_arg("fs_measures_files_list_file", "", \%args);
my $output_measures_for_selected_only = get_arg("output_measures_for_selected_only", 0, \%args);

my $features_selection_measures_significance = get_arg("fs_measure_significance", 1.0, \%args);
my $num_permutation_tests = get_arg("num_permutation_tests", 1000, \%args);
my $multiple_hyp_correction_type = get_arg("mhc", "None", \%args);
die "ERROR - unknown or unsupported type of multiple hypotheses correction ($multiple_hyp_correction_type).\n" unless ( $multiple_hyp_correction_type =~ m/None|FDR|Bonferroni/i );

my $corr_thresh = get_arg("corr_thresh", "", \%args);
my $is_abs_corr = get_arg("is_abs_corr", 0, \%args);

my $min_auc_gain = get_arg("min_auc_gain", "", \%args);
my $is_symmetric_auc_thresh = get_arg("is_symmetric_auc_thresh", 0, \%args);


#
# Binding template parameters:
#

my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/run_compute_features.map");
$exec_str .= &AddStringProperty("FEATURE_SELECTION_TYPE", $feature_selection_type);
$exec_str .= &AddStringProperty("FEATURE_MATRIX_FILE", $feature_matrix_input_file);
$exec_str .= &AddStringProperty("FEATURES_VALUE_TYPE", $feature_matrix_value_type);
$exec_str .= &AddStringProperty("RESPONSE_VALUES_FILE", $response_file);
$exec_str .= &AddStringProperty("SELECTED_FEATURES_MATRICES_FILES_LIST_FILE", $selected_features_matrices_files_list_file);

if ( $features_selection_measures_files_list_file ne "" ) {
  $exec_str .= &AddStringProperty("FEATURE_SELECTION_MEASURES_FILES_LIST_FILE", $features_selection_measures_files_list_file);

  if ( $output_measures_for_selected_only ) {
    $exec_str .= &AddStringProperty("OUTPUT_SELECTION_MEASURES_ONLY_FOR_SELECTED_FEATURES", "true");
  }
  else {
    $exec_str .= &AddStringProperty("OUTPUT_SELECTION_MEASURES_ONLY_FOR_SELECTED_FEATURES", "false");
  }
}

$exec_str .= &AddStringProperty("FEATURE_SELECTION_MEASURES_SIGNIFICANCE", $features_selection_measures_significance);
$exec_str .= &AddStringProperty("NUM_PERMUTATION_TESTS", $num_permutation_tests);
$exec_str .= &AddStringProperty("MULTIPLE_HYPOTHESIS_CORRECTION_TYPE", $multiple_hyp_correction_type);


if ( $feature_selection_type eq "BasedOnPearsonCorrelationBetweenFeatureAndResponse" ) {
  die "ERROR - correlation threshold not given.\n" if ( $corr_thresh eq "" );
  die "ERROR - correlation threshold value ($corr_thresh) must be in [0,1].\n" if ( $corr_thresh < 0 or $corr_thresh > 1 );

  $exec_str .= &AddStringProperty("CORRELATION_THRESHOLD", $corr_thresh);

  if ( $is_abs_corr ) {
    $exec_str .= &AddStringProperty("IS_ABS_CORRELATION", "true");
  }
  else {
    $exec_str .= &AddStringProperty("IS_ABS_CORRELATION", "false");
  }
}
elsif ( $feature_selection_type eq "BasedOnAUCResponseClassifiedByThreshAndRankedByFeature" ) {
  die "ERROR - minimum AUC gain not given.\n" if ( $min_auc_gain eq "" );
  die "ERROR - minimum AUC gain value ($min_auc_gain) must be in [0,0.5].\n" if ( $min_auc_gain < 0 or $min_auc_gain > 0.5 );

  $exec_str .= &AddStringProperty("MIN_AUC_GAIN", $min_auc_gain);

  if ( $is_symmetric_auc_thresh ) {
    $exec_str .= &AddStringProperty("IS_SYMMETRIC_AUC_THRESHOLD", "true");
  }
  else {
    $exec_str .= &AddStringProperty("IS_SYMMETRIC_AUC_THRESHOLD", "false");
  }
}


#
# Running:
#

&RunGenie($exec_str, $print_map_file, $tmp_map, $tmp_clu, $log_file, $save_map_file);


#
# END
#


__DATA__

feature_selection.pl

  Given a feature matrix (as can be computed using compute_sequence_features.pl), tests each feature,
  against a corresponding response vector, whether it passes some criterion (usually, computes some desired
  measure, such as correlation, and checks if passes some threshold).
  For each different response vector (multiple can be given, see below), outputs the sub-matrix of features
  that passed.


  --help:                             prints this message.

  -map:                               print only the map file
  -log <str>:                         print the stdout and stderr of the program into the file <str>
  -smap <str>:                        save the map file into <str>


  -fs_type <str>:                      type of feature selection to use. one of:
                                         BasedOnPearsonCorrelationBetweenFeatureAndResponse
                                         BasedOnAUCResponseClassifiedByThreshAndRankedByFeature
                                         BasedOnAUCFeatureClassifiedByThreshAndRankedByResponse (currently not supported !!).

  -fmat_input_file <str>:              name of feature matrix input file.

  -fmat_val_type <str>:                type of feature values in feature matrix input file.
                                       one of: AnyValue/Double/Int/Boolean/Char/String.

  -response_file <str>:                name of file containing response matrix.
                                       the (i,j)-th element holds the value of response j for object i.
                                       includes a row header (response names) and a column header (object names).

  -fs_res_fmat_files_list_file <str>:  name of a two column tab-delimited list file, of the following format:
                                          <response vector name>  <selected features matrix output file name>
                                       an output file name is expected to be given for each response vector that appears
                                       in the input response matrix.

  -fs_measures_files_list_file <str>:  name of a two column tab-delimited list file, of the following format:
                                          <response vector name>  <features selection measures output file name>
                                       an output file name is expected to be given for each response vector that appears
                                       in the input response matrix.
                                       for a specific response vector, its corresponding features selection measures output
                                       file will hold for each feature its selection measure (based on which it was selected or not)
                                       in a two tab-delimited column format: <feature_name>  <measure>.

  -output_measures_for_selected_only:  if set, and if -fs_measures_file is given, will output selection measures for
                                       selected features only.


  -fs_measure_significance <double>:   for each feature, its selection measure may have a p-value (for example by permutation tests),
                                       and this p-value may be required to be less than the significance value given here. (default: 1.0).

  -num_permutation_tests <int>:        number of permutation tests to perform in order to compute a p-value for a selection measure.
                                       (default: 1000)

  -mhc <str>:                          type of multiple hypotheses correction to use. one of: None/FDR/Bonferroni (default: None).


  From here - options per chosen feature selection type (-fs_type):

  'BasedOnPearsonCorrelationBetweenFeatureAndResponse':
  =====================================================

  -corr_thresh <double>:               correlation threshold, between 0 and 1.
  -is_abs_corr:                        if set, then the threshold will be on the correlation absolute value.


  'BasedOnAUCResponseClassifiedByThreshAndRankedByFeature':
  =========================================================

  -min_auc_gain <double>:              minimum AUC gain above 0.5 (between 0 and 0.5).
                                       for instance, for a min gain of 0.2, only features for which auc is >= 0.7 are selected.

  -is_symmetric_auc_thresh:            if set, then for min gain 'G', will select features for which auc is >= 0.5 + G
                                       or <= 0.5 - G.


