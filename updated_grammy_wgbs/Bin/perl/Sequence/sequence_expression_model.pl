#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/sequence_expression_model.map");

$exec_str .= &AddStringProperty("weight_matrices_file", &get_arg("m", "", \%args));
$exec_str .= &AddStringProperty("sequence_file", &get_arg("s", "", \%args));
$exec_str .= &AddStringProperty("sequence_list", &get_arg("l", "", \%args));
$exec_str .= &AddStringProperty("background_markov_order", &get_arg("b", 0, \%args));
$exec_str .= &AddStringProperty("background_matrix_file", &get_arg("bck", "", \%args));
$exec_str .= &AddStringProperty("background_log_ratio_threshold", &get_arg("wmt", "", \%args));
$exec_str .= &AddStringProperty("max_cooperativity_distance", &get_arg("mcd", "", \%args));
$exec_str .= &AddStringProperty("target_expression_file", &get_arg("e", "", \%args));
$exec_str .= &AddStringProperty("preprocess_target_data", &get_arg("preprocess", "AverageConsecutiveExperiments", \%args));
$exec_str .= &AddStringProperty("target_regulator_mapping_file", &get_arg("trm", "", \%args));
$exec_str .= &AddStringProperty("regulator_expression_file", &get_arg("r", "", \%args));
$exec_str .= &AddStringProperty("model_type", &get_arg("mt", "SoftmaxSampling", \%args));
$exec_str .= &AddStringProperty("GHMM_INST_TYPE", &get_arg("ghmm", "Cooperative", \%args));
$exec_str .= &AddStringProperty("scaling_factors_parameters_file", &get_arg("scaling", "", \%args));
$exec_str .= &AddStringProperty("logistic_parameters_file", &get_arg("logistic", "", \%args));
if (-f &get_arg("sequence_biases", "",  \%args))
{
    $exec_str .= &AddStringProperty("BIASES_PARAMETERS_FILE", &get_arg("sequence_biases", "", \%args));
}
if (-f &get_arg("coop", "", \%args))
{
  $exec_str .= &AddStringProperty("cooperativity_parameters_file", &get_arg("coop", "", \%args));
}
my $output_scaling_factors_parameters_file = &get_arg("oscaling", "", \%args);
if ($output_scaling_factors_parameters_file ne "")
{
	$exec_str .= &AddStringProperty("OUTPUT_SCALING_FACTORS_PARAMETERS_FILE", $output_scaling_factors_parameters_file);
}
my $output_free_energy_parameters_file = &get_arg("oFreeEnergyWeights", "", \%args);
if ($output_free_energy_parameters_file ne "")
{
	$exec_str .= &AddStringProperty("OUTPUT_FREE_ENERGY_PARAMETERS_FILE", $output_free_energy_parameters_file);
}
my $output_sequence_biases_parameters_file = &get_arg("osequencebiases", "",  \%args);
if ($output_sequence_biases_parameters_file ne "")
{
    $exec_str .= &AddStringProperty("output_sequence_biases_parameters_file", $output_sequence_biases_parameters_file);
}
$exec_str .= &AddStringProperty("output_logistic_parameters_file", &get_arg("ologistic", "", \%args));
$exec_str .= &AddStringProperty("output_cooperativity_parameters_file", &get_arg("ocoop", "", \%args));
$exec_str .= &AddStringProperty("output_weight_matrices_file", &get_arg("om", "", \%args));
$exec_str .= &AddStringProperty("num_samples", &get_arg("ns", 100, \%args));
$exec_str .= &AddStringProperty("output_sequence_file", &get_arg("os", "", \%args));
$exec_str .= &AddStringProperty("output_expression_variability_file", &get_arg("oev", "", \%args));
$exec_str .= &AddStringProperty("num_iterations", &get_arg("n", 1, \%args));
$exec_str .= &AddBooleanProperty("reverse_complement", &get_arg("norc", 0, \%args) == 1 ? 0 : 1);
if (length(&get_arg("st", "", \%args)) > 0)
{
    $exec_str .= &AddStringProperty("SCORE_TYPE", &get_arg("st", "LeastSquares", \%args));
}

if (length(&get_arg("reweight", "", \%args)) > 0)
{
  $exec_str .= &AddBooleanProperty("reweight_positive_and_negative_instances", 1);
  $exec_str .= &AddStringProperty("positive_to_negative_ratio", &get_arg("reweight", "", \%args));
}

my $configuration_adjacent_matrices_counts = get_arg("camc", 0, \%args);
if ($configuration_adjacent_matrices_counts == 1)
{
    $exec_str .= &AddBooleanProperty("configuration_adjacent_matrices_counts", 1);

    my @row = split(/\;/, $configuration_adjacent_matrices_counts);
    $exec_str .= &AddStringProperty("min_adjacent_matrices_distance", $row[0]);
    $exec_str .= &AddStringProperty("max_adjacent_matrices_distance", $row[1]);
    $exec_str .= &AddStringProperty("adjacent_matrices_distance_increment", $row[2]);
    $exec_str .= &AddStringProperty("compute_separate_adjacent_matrices", $row[3]);
}

$exec_str .= &AddBooleanProperty("single_matrices_counts", &get_arg("smc", 0, \%args) == 1 ? 1 : 0);
$exec_str .= &AddBooleanProperty("all_matrices_counts", &get_arg("amc", 0, \%args) == 1 ? 1 : 0);
$exec_str .= &AddBooleanProperty("configuration_matrices_coverage", &get_arg("cmc", 0, \%args) == 1 ? 1 : 0);

$exec_str .= &AddStringProperty("print_weight_matrix_configurations_output_file", &get_arg("pwmc_o", "", \%args));
$exec_str .= &AddStringProperty("print_weight_matrix_configurations_sequence_output_file", &get_arg("pwmc_os", "", \%args));

$exec_str .= &AddBooleanProperty("train_separate_weight_matrices", &get_arg("tswm", 0, \%args) == 1 ? 1 : 0);
$exec_str .= &AddBooleanProperty("train_joint_logistic_weights", &get_arg("tjlw", 0, \%args) == 1 ? 1 : 0);
$exec_str .= &AddBooleanProperty("train_all_parameters", &get_arg("tap", 0, \%args) == 1 ? 1 : 0);
$exec_str .= &AddBooleanProperty("train_all_parameters_and_separate_weight_matrices", &get_arg("tapaswm", 0, \%args) == 1 ? 1 : 0);


$exec_str .= &AddBooleanProperty("learn_individual_module_parameter", &get_arg("limp", 0, \%args));

$exec_str .= &AddStringProperty("output_file", $tmp_clu);

$exec_str .= &AddStringProperty("MATLAB_OUTPUT_FILE_NAME", &get_arg("matlab_output", "", \%args));


$exec_str .= &AddStringProperty("MATLAB_OUTPUT_FILE_NAME", &get_arg("matlab_output", "", \%args));


$exec_str .= &AddStringProperty("STRUCTURE_LEARNING_CANDIDATE_FEATURES_MAX_DOMAIN_SIZE", &get_arg("fmm_max_feature_size", "2", \%args));
$exec_str .= &AddStringProperty("STRUCTURE_LEARNING_MAX_FEATURE_NUM_RATIO_TO_PSSM_PARAMS", &get_arg("fmm_max_feature_num_ratio2pssm", "", \%args));

my $weight_least_squares_errors_pos_fraction = &get_arg("weight_to_positive_fraction", -1, \%args);

if ($weight_least_squares_errors_pos_fraction >= 0)
{
   $exec_str .= &AddStringProperty("WEIGHT_LEAST_SQUARES_ERRORS", "true");
   $exec_str .= &AddStringProperty("WEIGHT_LEAST_SQUARES_ERRORS_POS_FRACTION", $weight_least_squares_errors_pos_fraction);
}



my $learn_fmm_struct = &get_arg("learn_fmm_struct", 0, \%args) == 1 ? 1 : 0;
$exec_str .= &AddBooleanProperty("LEARNING_WEIGHT_MATRICES_STRUCTURE", $learn_fmm_struct );

if ($learn_fmm_struct > 0)
{
   $exec_str .= &AddStringProperty("NUM_OF_FEATURES_TO_ADD_IN_GRAFTING_ITERATION", &get_arg("num_of_features_to_add_in_grafting_iteration", "1", \%args));
   $exec_str .= &AddStringProperty("MAX_GRAFTING_ITERATIONS", &get_arg("max_grafting_iterations", "1000", \%args));
   $exec_str .= &AddStringProperty("REMOVE_ZERO_WEIGHT_FEATURES_AFTER_EACH_GRAFTING_ITERATION", &get_arg("remove_zero_weight_features_after_each_grafting_iteration", "false", \%args));
   $exec_str .= &AddStringProperty("REMOVE_ZERO_WEIGHT_FEATURES_AFTER_FULL_GRAFTING", &get_arg("remove_zero_weight_features_after_full_grafting", "false", \%args));
   $exec_str .= &AddStringProperty("SUM_WEIGHTS_PENALTY_COEFFICIENT", &get_arg("sum_weights_penalty_coefficient", "0.1", \%args));
   $exec_str .= &AddStringProperty("USE_ONLY_POSITIVE_WEIGHTS", &get_arg("use_only_positive_weights", "true", \%args));
   $exec_str .= &AddStringProperty("CAL_FUNCTION_PENALTY", &get_arg("cal_function_penalty", "true", \%args));

   my $tmp_structure_learning_weight_matrix_to_learn;

   for (my $i = 1; $i<=10; $i = $i +1)
   {
      $tmp_structure_learning_weight_matrix_to_learn="";
      $tmp_structure_learning_weight_matrix_to_learn=&get_arg("structure_learning_weight_matrix_to_learn_" .$i, "", \%args);
      if ($tmp_structure_learning_weight_matrix_to_learn ne "")
      {
	#print STDERR "DEBUG AddStringProperty STRUCTURE_LEARNING_WEIGHT_MATRIX_TO_LEARN_$i , value:$tmp_structure_learning_weight_matrix_to_learn \n";
          $exec_str .= &AddStringProperty("STRUCTURE_LEARNING_WEIGHT_MATRIX_TO_LEARN_" . $i, $tmp_structure_learning_weight_matrix_to_learn);
      }
   }
}

my $train_single_free_energy_weight_wm_name = &get_arg("train_single_free_energy_weight_wm_name", "", \%args);
if ($train_single_free_energy_weight_wm_name ne "")
{
	#print STDERR "DEBUG TRAIN_SINGLE_FREE_ENERGY_WEIGHT_WM_NAME= $train_single_free_energy_weight_wm_name";
   $exec_str .= &AddStringProperty("TRAIN_SINGLE_FREE_ENERGY_WEIGHT_WM_NAME", $train_single_free_energy_weight_wm_name);
}

my $train_single_scaling_factor_wm_name = &get_arg("train_single_scaling_factor_wm_name", "", \%args);
if ($train_single_scaling_factor_wm_name ne "")
{
	#print STDERR "DEBUG TRAIN_SINGLE_FREE_ENERGY_WEIGHT_WM_NAME= $train_single_free_energy_weight_wm_name";
   $exec_str .= &AddStringProperty("TRAIN_SINGLE_SCALING_FACTOR_WM_NAME", $train_single_scaling_factor_wm_name);
}

   $exec_str .= &AddStringProperty("MAX_LOCAL_ITERATIONS", &get_arg("max_local_iterations", "1000", \%args));
   $exec_str .= &AddStringProperty("CONSTRAIN_WEIGHT_MATRICES", &get_arg("constrain_weight_matrices", "false", \%args));
   $exec_str .= &AddStringProperty("REVERSE_COMPLEMENT", &get_arg("reverse_complement", "false", \%args));


   $exec_str .= &AddStringProperty("STRUCT_LEARN_FILTER_CANDIDATE_FEATURES_BEFORE_START", &get_arg("filter_candidate_features_before_start", "false", \%args));
   $exec_str .= &AddStringProperty("STRUCT_LEARN_FILTER_CANDIDATE_FEATURES_BEFORE_EACH_ITER", &get_arg("filter_candidate_features_before_each_iter", "false", \%args));

   $exec_str .= &AddStringProperty("STRUCT_LEARN_FEATURE_LEARNER_BS_SEQS_THRESH_PER_POS", &get_arg("feature_learner_bs_seqs_thresh_per_pos", "0.3", \%args));
   $exec_str .= &AddStringProperty("STRUCT_LEARN_FEATURE_LEARNER_BS_SEQS_PERCENT_FROM_BEST_THRESH", &get_arg("feature_learner_bs_seqs_percent_from_best_thresh", "0.1", \%args));
   $exec_str .= &AddStringProperty("STRUCT_LEARN_FEATURE_LEARNER_K_BEST_BS_SEQS", &get_arg("feature_learner_k_best_bs_seqs", "300", \%args));

   $exec_str .= &AddStringProperty("STRUCT_LEARN_INITIAL_FILTER_COUNT_PERCENT_THRESH", &get_arg("initial_filter_count_percent_thresh", "0.03", \%args));

   $exec_str .= &AddStringProperty("STRUCT_LEARN_FEATURE_LEARNER_BS_SEQS_ONLY_FROM_POSITIVE_SEQS_THRESH", &get_arg("feature_learner_bs_seqs_only_from_positive_seqs_thresh", "0.9", \%args));
   $exec_str .= &AddStringProperty("STRUCT_LEARN_FEATURE_LEARNER_BS_SEQS_USE_POSTERIOR_AS_PROBS", &get_arg("feature_learner_bs_seqs_use_posterior_as_probs", "false", \%args));

   $exec_str .= &AddStringProperty("STRUCT_LEARN_LETTERS_AT_TWO_POSITIONS_CHI2_FILTER_THRESH", &get_arg("letters_at_two_positions_chi2_filter_thresh", "-1", \%args));
   $exec_str .= &AddStringProperty("STRUCT_LEARN_LETTERS_AT_MULTIPLE_POSITIONS_BINOMIAL_FILTER_THRESH", &get_arg("letters_at_multiple_positions_binomial_filter_thresh", "0.25", \%args));
   $exec_str .= &AddStringProperty("STRUCT_LEARN_MULTIPLE_HYPOTHESIS_CORRECTION", &get_arg("multiple_hypothesis_correction", "None", \%args));
   $exec_str .= &AddStringProperty("STRUCT_LEARN_FEATURES_STATISTICAL_TESTS_FILTER_OUT_FILE_NAME", &get_arg("features_statistical_tests_filter_out_file_name", "out_features_filter_statistical_tests.txt", \%args));

   #print "DEBUG: exe str - $exec_str\n";

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file);

__DATA__

sequence_expression_model.pl

   Runs a model of sequence and expression

   -m <str>:                 Matrices file (gxw format)
   -om <str>:                Output matrices file
   -s <str>:                 Sequences file (fasta format)
   -l <str>:                 Use only these sequences from the file <str> (default: use all sequences in fasta file)
   -b <num>:                 Background order (default: 0)
   -bck <str>:               Background matrix file to load (optional, background will be computed form the sequences otherwise)
   -wmt <str>:               Weight matrix threshold below which weight matrix matches are not considered

   -e <str>:                 Target expression
   -preprocess <str>:        Preprocessing instructions for the expression data file (default: AverageConsecutiveExperiments)
                             Preprocessing options: None/AverageConsecutiveExperiments
   -r <str>:                 Regulator expression
   -trm <str>:               Target regulator mapping file

   -scaling <str>:           Scaling factors parameters file
   -logistic <str>:          Logistic parameters file
   -sequence_biases <str>:   Expression sequence biases parameters file
   -coop <str>:              Cooperativity parameters file
   -mcd <num>:               Max cooperativity distance (in bp, default: 100)
   -oscaling <str>:          Output scaling factors parameters file
   -ologistic <str>:         Output logistic parameters file
   -osequencebiases <str>:   Output expression sequence biases parameters file
   -ocoop <str>:             Output cooperativity parameters file

   -reweight <num>:          Reweight the positive and negative expression to make the positive/negative ratio be <num>

   -mt <str>:                Model type (FreeEnergy/Softmax/SoftmaxSampling, default: SoftmaxSampling)

   -ghmm <str>:              GHMM Instance type (Cooperative/BasicCooperative, default: Cooperative)

   -n <num>:                 Number of iterations (default: 1)

   -ns <num>:                Number of samples (default: 100)

   -norc:                    Do *not* use reverse complement in sequence (default: use reverse complement)

   -fmm_max_feature_size <#> defualt is 2, max fmm domain size if learning structure
   -fmm_max_feature_num_ratio2pssm <#> defualt is 3, ratio of fmm feature num to pssm feature num if learning structure

   -weight_to_positive_fraction <real> defualt is -1, reweight least sum square, if negative doesn't reweight

   -structure_learning_weight_matrix_to_learn_<index 1-10> <str Weight matrix name> can pass up to 10 specific matricies for learn structure step
                                                                                    if non pass as argument will learn all

   -max_local_iterations <#> number of optimization algorithm max local iteration default is 1000
   -constrain_weight_matrices <true/false> default is  false, does to constrain pssm to it's consensus while learning
   -reverse_complement <true/false> default is  false, does to use reverse complement binding in equal probability to forward


   structure learning parameters
   =============================
   
   -num_of_features_to_add_in_grafting_iteration <#> defualt 1
   -max_grafting_iterations <#> defualt 1000
   -remove_zero_weight_features_after_each_grafting_iteration <true/false> defualt false
   -remove_zero_weight_features_after_full_grafting <true/false> defualt false
   -sum_weights_penalty_coefficient <double> defualt 0.1
   -use_only_positive_weights <true/false> defualt true
   -cal_function_penalty <true/false> defualt true

   -filter_candidate_features_before_start <true/false> defualt false
   -filter_candidate_features_before_each_iter <true/false> defualt false

   -feature_learner_bs_seqs_thresh_per_pos <[0,1]> defualt 0.3
   -feature_learner_bs_seqs_percent_from_best_thresh <[0,1]> defualt 0.1
   -feature_learner_k_best_bs_seqs <#> defualt 300

   -initial_filter_count_percent_thresh <[0,1]> defualt 0.03

   -feature_learner_bs_seqs_only_from_positive_seqs_thresh <[0,1]> defualt 0.03
   -feature_learner_bs_seqs_use_posterior_as_probs <true/false> defualt false
 
   -letters_at_two_positions_chi2_filter_thresh <[0,1]> defualt -1 (negative is nofilter)
   -letters_at_multiple_positions_binomial_filter_thresh <[0,1]> defualt 0.25 (negative is nofilter)
   -multiple_hypothesis_correction <None,FDR,Bonferroni> defualt None
   -features_statistical_tests_filter_out_file_name <file name> defualt out_features_filter_statistical_tests.txt

   GeneralTraining
   ===============
   -tswm              Train separate weight matrices
   -tjlw              Train joint logistic weights
   -tap               Train all parameters (logistic and scaling factors)
   -tapaswm           Train all parameters and separate weight matrices
   -limp              Learn individual module parameter (module specific logistic bias)
   -st <str>:         Score type (default : LeastSquares)
                      Score type options: LeastSquares/LogLikelihood/Devised/Bayesian
   -learn_fmm_struct  Learn FMM matrices structure
   -train_single_free_energy_weight_wm_name <str weight matrix name> defualt "", train single free energy weight matrix name, if "" then won't train
   -train_single_scaling_factor_wm_name <str weight matrix name> defualt "", train single scaling factor weight matrix name, if "" then won't train

   
   WeightMatrixSequenceFeatures
   ============================
   -smc:                 Single matrices counts
   -amc:                 All matrices counts
   -camc <str>:          Configuration adjacent matrices counts (str has the form: <min;max;inc;true/false>)
   -cmc:                 Configuration matrices coverage

   -pwmc_o <str>:        PrintWeightMatrixConfigurations expression predictions file
   -pwmc_os <str>:       PrintWeightMatrixConfigurations sequence configuration predictions file
   
   -matlab_output <str>: Prints a matlab format output
   -oev <str>:           Output Expression variability file

   -xml:                 Print only the xml file
   -run <str>:           Print the stdout and stderr of the program into the file <str>

