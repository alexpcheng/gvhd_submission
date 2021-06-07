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

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";


#######################
#
# Loading args:

my %args = load_args(\@ARGV);


my $xml = get_arg("xml", 0, \%args);
my $log_file = get_arg("log", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $seqs = get_arg("seqs", "", \%args);
die "ERROR - input sequences file name not given.\n" if ( $seqs eq "" );
die "ERROR - input sequences file ($seqs) not found.\n" unless ( -e $seqs );

my $seqs_list = get_arg("seqs_list", "", \%args);

my $bg = get_arg("bg", "", \%args);
die "ERROR - background weight matrix file name not given.\n" if ( $bg eq "" );
die "ERROR - background weight matrix file ($bg) not found.\n" unless ( -e $bg );

my $nuc = get_arg("nuc", "", \%args);
die "ERROR - nucleosome weight matrix file name not given.\n" if ( $nuc eq "" );
die "ERROR - nucleosome weight matrix file ($nuc) not found.\n" unless ( -e $nuc );

my $nuc_name = get_arg("nuc_name", "Nucleosome", \%args);

my $locations = get_arg("locations", "", \%args);
my $assert_locations = 1;

my $scaling_file = get_arg("scaling_file", "", \%args);
my $scaling_file_to_use = $scaling_file;

my $use_rev_comp = get_arg("use_rev_comp", "false", \%args);

my $max_coop_dist = get_arg("max_coop_dist", 100, \%args);

my $init_coop_file = get_arg("init_coop_file", "", \%args);
die "ERROR - linker function params file ($init_coop_file) not found.\n" if ( $init_coop_file ne "" and not(-e $init_coop_file) );

my $coop = get_arg("coop", "", \%args);

die "ERROR - initial linker function (coop) params not given.\n" if ( $init_coop_file eq "" and $coop eq "" );

my $coop_file_to_use = $init_coop_file;
if ( $init_coop_file eq "" and $coop ne "" ) {
  my @coop_list = split(/,/,$coop);
  chomp @coop_list;

  my $func_type = shift(@coop_list);
  my $num_params = @coop_list;

  $coop_file_to_use = "tmp_coop_$r.tab";
  open(COOP_FILE,">$coop_file_to_use");

  print COOP_FILE "regulator1\tregulator2\tfunction\tcoefficient";
  for ( my $i=1 ; $i <= $num_params ; $i++ ) {
    print COOP_FILE "\tparameter$i";
  }
  print COOP_FILE "\n$nuc_name\t$nuc_name\t$func_type\t1";

  foreach my $param (@coop_list) {
    print COOP_FILE "\t$param";
  }
  print COOP_FILE "\n";

  close COOP_FILE;
}

my $min_iters = get_arg("min_iters", 100, \%args);

my $max_iters = get_arg("max_iters", 100, \%args);

my $train_type = get_arg("train_type", "ConjugateGradient", \%args);

my $max_local_iters = get_arg("max_local_iters", 50, \%args);

my $step = get_arg("step", 0.1, \%args);

my $tolerance = get_arg("tolerance", 0.05, \%args);


# "switch" on value of 'action':
my $action = get_arg("action", "LF", \%args);
my $action_name;
if ( $action eq "LF" ) {
  $action_name = "FunctionParamsTraining";
}
elsif ( $action eq "TS" ) {
  $action_name = "TemperatureAndScalingTraining";
}
elsif ( $action eq "ALFTS" ) {
  $action_name = "AlternateTrainingOfFunctionParamsAndOfTemperatureAndScaling";
}
elsif ( $action eq "SLFTS" ) {
  $action_name = "SimultaneousTrainingOfFunctionParamsAndOfTemperatureAndScaling";
}
elsif ( $action eq "GFV" ) {
  $action_name = "GetFunctionValue";
}
elsif ( $action eq "GAO" ) {
  $action_name = "GetAverageOccupancy";
  $assert_locations = 0;
}
elsif ( $action eq "GFVAO" ) {
  $action_name = "GetFunctionValueAndAverageOccupancy";
}
elsif ( $action eq "GFVSP" ) {
  $action_name = "GetFunctionValueAndSitesLogProbabilities";
}
elsif ( $action eq "GALP" ) {
  $action_name = "GetAccessibilityLogProbabilities";
}
elsif ( $action eq "SC" ) {
  $action_name = "SampleConfigurations";
  $assert_locations = 0;
}
else { # default
  die "\nERROR - Unknown action $action\n";
}


my $goal_func_type = get_arg("goal_func_type", "AverageOccupancyBased", \%args);
unless ( $goal_func_type eq "AverageOccupancyBased" or $goal_func_type eq "AverageOccupancyCorrelationBased" or $goal_func_type eq "LinkerDistributionBased" or $goal_func_type eq "LinkerFunctionBased" or $goal_func_type eq "FunctionalSitesAccessibilityBased" ) {
  die "Unknown goal function type '$goal_func_type'\n";
}
if ( $goal_func_type eq "LinkerFunctionBased" ) {
  die "Goal Function is LinkerFunctionBased but action is not LF" unless ( $action eq "LF" );
  $assert_locations = 0;
}
if ( $goal_func_type eq "FunctionalSitesAccessibilityBased" ) {
  die "Goal Function is FunctionalSitesAccessibilityBased but action is not LF or SLFTS or GFV or GFVSP or GALP" unless ( $action eq "LF" or $action eq "SLFTS" or $action eq "GFV" or $action eq "GFVSP" or $action eq "GALP" );
  $assert_locations = 0;
}

if ( $assert_locations ) {
  die "ERROR - nucleosome locations file name not given.\n" if ( $locations eq "" );
  die "ERROR - nucleosome locations file ($locations) not found.\n" unless ( -e $locations );
}


my $func_val_file = get_arg("func_val_file", "function_value.tab", \%args);

my $av_occ_file = get_arg("av_occ_file", "av_occ.chr", \%args);

my $out_coop_file = get_arg("out_coop_file", "coop_out.tab", \%args);
my $temp_out_file = get_arg("temp_out_file", "temperature_opt.tab", \%args);
my $scaling_out_file = get_arg("scaling_out_file", "scaling_out.tab", \%args);

my $all_param_out_file = get_arg("all_param_out_file", "all_params_opt.tab", \%args);

my $train_toggle_file = get_arg("train_toggle_file", "", \%args);
my $train_toggle = get_arg("train_toggle", "", \%args);
my $train_linker_first = get_arg("train_linker_first", 0, \%args);

my $train_toggle_file_to_use = "";
if ( $action eq "TLFTS" ) {
  $train_toggle_file_to_use = $train_toggle_file;
  if ( $train_toggle_file eq "" and $train_toggle ne "" ) {
    my @train_toggle_list = split(/,/,$train_toggle);
    chomp @train_toggle_list;

    $train_toggle_file_to_use = "tmp_train_toggle_$r.tab";
    open(TOGGLE_FILE,">$train_toggle_file_to_use");

    my $first_index = shift(@train_toggle_list);
    print TOGGLE_FILE $first_index;

    foreach my $index (@train_toggle_list) {
      print TOGGLE_FILE "\t$index";
    }
    close TOGGLE_FILE;
  }
}


my $params2train = get_arg("params2train", "", \%args);
my $params2train_file = "";
unless ( $params2train eq "" ) {
  my @params2train_list = split(/,/,$params2train);
  chomp @params2train_list;

  $params2train_file = "tmp_params2train_$r.tab";
  open(PARAMS_2_TRAIN_FILE,">$params2train_file");

  my $first_index = shift(@params2train_list);
  print PARAMS_2_TRAIN_FILE $first_index;

  foreach my $index (@params2train_list) {
    print PARAMS_2_TRAIN_FILE "\t$index";
  }
  close PARAMS_2_TRAIN_FILE;
}


my $temp = get_arg("temp", 1.0, \%args);

my $nuc_scaling = get_arg("nuc_scaling", 0.5, \%args);

if ( $scaling_file eq "" )
{
  $scaling_file_to_use = "tmp_scaling_$r";

  open(OUTFILE, ">$scaling_file_to_use");

  print OUTFILE "Background\t1\n";
  print OUTFILE "$nuc_name\t$nuc_scaling\n";

  close OUTFILE;
}


my $perturbations_file = get_arg("pert_file", "", \%args);
my $perturbations = get_arg("perts", "", \%args);
my $max_perturbation_factor = get_arg("max_pert_factor", 1, \%args);
my $random_seed = get_arg("random_seed", 0, \%args);
my $rand_seed_out_file = get_arg("rand_seed_out_file", "", \%args);

my $perturbations_file_to_use = $perturbations_file;
if ( $perturbations_file eq "" and $perturbations ne "" ) {
  my @perts_list = split(/,/,$perturbations);
  chomp @perts_list;

  $perturbations_file_to_use = "tmp_perturbation_per_param_$r.tab";
  open(PERTS_FILE,">$perturbations_file_to_use");

  my $first_pert = shift(@perts_list);
  print PERTS_FILE $first_pert;

  foreach my $pert (@perts_list) {
    print PERTS_FILE "\t$pert";
  }
  close PERTS_FILE;
}


my $sites_file = get_arg("sites_file", "", \%args);
die "ERROR - goal function type is 'FunctionalSitesAccessibilityBased' and action is not 'GALP' but 'sites_file' not given.\n" if ( $goal_func_type eq "FunctionalSitesAccessibilityBased" and $action ne "GALP" and $sites_file eq "" );

my $use_sites_flags = get_arg("use_sites_flags", 0, \%args);
my $sites_out_file = get_arg("sites_out_file", "sites_out.chr", \%args);
my $accessibe_radius = get_arg("accessibe_radius", 10, \%args);

my $samp_linkers_file = get_arg("samp_linkers_file", "", \%args);
my $samp_reads_file = get_arg("samp_reads_file", "", \%args);
my $cfg_num_samps_file = get_arg("cfg_num_samps_file", "", \%args);
my $cfg_weights_file = get_arg("cfg_weights_file", "", \%args);

my $samps_per_seq_file = get_arg("samps_per_seq_file", "", \%args);
my $samps_per_seq = get_arg("samps_per_seq", "", \%args);
my $num_samps = get_arg("num_samps", "", \%args);
my $samp_per_bp = get_arg("samp_per_bp", 0, \%args);

die "using both 'samps_per_seq_file' and 'num_samps' options is illegal\n" if ( $samps_per_seq_file ne "" and $num_samps ne "" );
die "using both 'samps_per_seq' and 'num_samps' options is illegal\n" if ( $samps_per_seq ne "" and $num_samps ne "" );

my $num_seqs = GetNumRows($seqs) / 2 ;
if ( $num_samps ne "" and $samps_per_seq eq "" ) {
  $samps_per_seq = "$num_samps";
  for ( my $i=1 ; $i < $num_seqs ; $i++ ) {
    $samps_per_seq .= ",$num_samps";
  }
}

my $samps_per_seq_file_to_use = $samps_per_seq_file;
if ( $samps_per_seq_file eq "" and $samps_per_seq ne "" ) {
  my @samps_list = split(/,/,$samps_per_seq);
  chomp @samps_list;

  $samps_per_seq_file_to_use = "tmp_num_samples_per_seq_$r.tab";
  open(SAMPS_FILE,">$samps_per_seq_file_to_use");

  my $first_num_samps = shift(@samps_list);
  print SAMPS_FILE $first_num_samps;

  foreach my $num_samps (@samps_list) {
    print SAMPS_FILE "\t$num_samps";
  }
  close SAMPS_FILE;
}


my $debug = get_arg("debug", 0, \%args);


#######################
#
# Binding:

my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/learn_nucleosome_linker_model.map");

$exec_str .= &AddStringProperty("SEQUENCES_FILE", $seqs);
unless ( $seqs_list eq "" ) {
  $exec_str .= &AddStringProperty("SEQUENCES_LIST", $seqs_list);
}
$exec_str .= &AddStringProperty("BACKGROUND_MATRIX_FILE", $bg);
$exec_str .= &AddStringProperty("NUCLEOSOME_WEIGHT_MATRIX_FILE", $nuc);
$exec_str .= &AddStringProperty("NUCLEOSOME_WEIGHT_MATRIX_NAME", $nuc_name);
unless ( $locations eq "" ) {
  $exec_str .= &AddStringProperty("NUCLEOSOMES_LOCATIONS_FILE", $locations);
}
$exec_str .= &AddStringProperty("SCALING_FACTORS_TAB_FILE", $scaling_file_to_use);
$exec_str .= &AddStringProperty("TEMPERATURE", $temp);
$exec_str .= &AddStringProperty("USE_REV_COMP", $use_rev_comp);
$exec_str .= &AddStringProperty("MAX_COOPERATIVITY_DISTANCE", $max_coop_dist);
$exec_str .= &AddStringProperty("INITIAL_COOPERATIVITY_PARAMS_FILE", $coop_file_to_use);
$exec_str .= &AddStringProperty("LINKER_MODEL_GOAL_FUNCTION_TYPE", $goal_func_type);
$exec_str .= &AddStringProperty("MIN_TRAINING_ITERATIONS", $min_iters);
$exec_str .= &AddStringProperty("MAX_TRAINING_ITERATIONS", $max_iters);
$exec_str .= &AddStringProperty("TRAINING_PROCEDURE_TYPE", $train_type);
$exec_str .= &AddStringProperty("MAX_LOCAL_ITERATIONS", $max_local_iters);
$exec_str .= &AddStringProperty("TRAINING_PARAMETER_INITIAL_STEP_SIZE", $step);
$exec_str .= &AddStringProperty("TRAINING_PARAMETER_TOLERANCE", $tolerance);

$exec_str .= &AddStringProperty("LINKER_MODEL_ACTION_TYPE", $action_name);

$exec_str .= &AddStringProperty("FUNCTION_VALUE_OUTPUT_FILE", $func_val_file);
$exec_str .= &AddStringProperty("AVERAGE_OCCUPANCY_OUTPUT_FILE", $av_occ_file);

$exec_str .= &AddStringProperty("OUTPUT_COOPERATIVITY_PARAMS_FILE", $out_coop_file);
$exec_str .= &AddStringProperty("TEMPERATURE_OUTPUT_FILE", $temp_out_file);
$exec_str .= &AddStringProperty("SCALING_OUTPUT_FILE", $scaling_out_file);
$exec_str .= &AddStringProperty("ALL_PARAMS_OUTPUT_FILE", $all_param_out_file);

unless ( $train_toggle_file_to_use eq "" ) {
  $exec_str .= &AddStringProperty("TRAINING_STEP_TYPE_TOGGLING_FILE", $train_toggle_file_to_use);
}
unless ( $train_linker_first == 0 ) {
  $exec_str .= &AddStringProperty("FIRST_TRAIN_FUNCTION_PARAMS", "true");
}

unless ( $perturbations_file_to_use eq "" ) {
  $exec_str .= &AddStringProperty("PARAMS_PERTURBATION_FILE", $perturbations_file_to_use);
  $exec_str .= &AddStringProperty("MAX_PERTURBATION_FACTOR", $max_perturbation_factor);
  $exec_str .= &AddStringProperty("RANDOM_SEED", $random_seed);
  unless ( $rand_seed_out_file eq "" ) {
    $exec_str .= &AddStringProperty("RANDOM_SEED_OUTPUT_FILE", $rand_seed_out_file);
  }
}

unless ( $params2train_file eq "" ) {
  $exec_str .= &AddStringProperty("PARAM_TO_TRAIN_INDICES_FILE", $params2train_file);
}

unless ( $samp_linkers_file eq "" ) {
  $exec_str .= &AddStringProperty("SAMPLED_LINKER_LENGTHS_OUTPUT_FILE", $samp_linkers_file);
}
unless ( $samp_reads_file eq "" ) {
  $exec_str .= &AddStringProperty("SAMPLED_NUCLEOSOME_READS_OUTPUT_FILE", $samp_reads_file);
  unless ( $samp_per_bp == 0 ) {
    $exec_str .= &AddStringProperty("SAMPLE_STATS_PER_POSITION", "true");
  }
}
unless ( $cfg_num_samps_file eq "" ) {
  $exec_str .= &AddStringProperty("NUM_SAMPLES_PER_CONFIG_OUTPUT_FILE", $cfg_num_samps_file);
}
unless ( $cfg_weights_file eq "" ) {
  $exec_str .= &AddStringProperty("WEIGHT_PER_CONFIG_OUTPUT_FILE", $cfg_weights_file);
}

unless ( $samps_per_seq_file_to_use eq "" ) {
  $exec_str .= &AddStringProperty("NUM_SAMPLES_PER_SEQ_FILE", $samps_per_seq_file_to_use);
}

unless ( $sites_file eq "" ) {
  $exec_str .= &AddStringProperty("FUNCTIONAL_SITES_FILE", $sites_file);
}
unless ( $use_sites_flags == 0 ) {
  $exec_str .= &AddStringProperty("USE_FUNCTIONAL_SITES_FLAGS", "true");
}
unless ( $sites_out_file eq "" ) {
  $exec_str .= &AddStringProperty("SITES_LOG_PROBS_OUTPUT_FILE", $sites_out_file);
}

$exec_str .= &AddStringProperty("ACCESSIBILITY_RADIUS", $accessibe_radius);


#######################
#
# Running:

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $log_file, $save_xml_file);

#
#######################


# Removing tmp coop file if created:
if ( $init_coop_file eq "" and not $debug ) {
  system("rm $coop_file_to_use");
}

# Removing tmp scaling file if created:
if ( $scaling_file eq "" and not $debug ) {
  system("rm $scaling_file_to_use");
}

# Removing tmp train toggle file if created:
if ( $action eq "TLFTS" and $train_toggle_file_to_use ne "" and $train_toggle_file eq "" ) {
  system("rm $train_toggle_file_to_use");
}

# Removing tmp perturbations file if created:
if ( $perturbations_file eq "" and $perturbations_file_to_use ne "" and not $debug ) {
  system("rm $perturbations_file_to_use");
}

# Removing tmp num configuration samples per sequence file if created:
if ( $samps_per_seq_file eq "" and $samps_per_seq_file_to_use ne "" and not $debug ) {
  system("rm $samps_per_seq_file_to_use");
}

# Removing tmp params 2 train file if created:
unless ( $params2train eq "" or $debug ) {
  system("rm $params2train_file");
}

#
# END
#


__DATA__

learn_nucleosome_linker_model.pl

  Optimizes the parameters of a (nucleosome-nucleosome) cooperativity function that represents linker lengths preferences.

  Obligatory
  ----------
  -seqs <str>:               sequences fasta file
  -bg <str>:                 background matrix gxw file
  -nuc <str>:                nucleosome matrix gxw file
  -locations <str>:          nucleosome locations gxt file. expected to contain only single base features.
                             not obligatory only in case action is 'GAO' or in case goal_func_type is 'LinkerFunctionBased'.

  Linker Function Params:
  -----------------------
  linker function parameters must be specified using one of the following:

  -init_coop_file <str>:     initial linker function params file
  -coop <list>               a comma seperated list of the linker function type and parameters.
                             linker function type may be one of: Sinusoid/ExponentialyDecayingFunction/SimpleDecayingRepetitive/DecayingRepetitive/ValuePerPositionFunction.
                             (the number of parameters per function is determined in the c++ files 'Tools/cooperativity_functions.h' and 'Tools/general_function.h')
                             example - "-coop Sinusoid,0.5,1"

  Non-Obligatory
  --------------
  -nuc_name <str>:           name of nucleosome matrix (default: Nucleosome)
  -scaling_file <str>:       factors scaling file (default: no file)
  -nuc_scaling <double>:     nucleosome scaling factor (default: 1, if 'scaling_file' is given then 'nuc_scaling' is ignored)
  -temp <double>:            temperature (default: 0.5)
  -max_coop_dist <int>:      maximum linker coop distance (default: 100)
  -min_iters <int>:          minimum number of global training iterations (default: 100)
  -max_iters <int>:          maximum number of global training iterations (default: 100)
  -train_type <str>          training method type (ConjugateGradient/Simplex, default: ConjugateGradient)
  -max_local_iters <int>:    maximum number of local training iterations (default: 50)
  -step <double>:            initial training parameters step size (default: 0.1)
  -tolerance <double>:       parameter training tolerance (default: 0.05)

  -action <str>:             action to be performed (LF/TS/ALFTS/SLFTS/GFV/GAO/GFVAO/GFVSP/GALP/SC, default: LF)
                             LF    - Train Linker Function parameters
                             TS    - Train Temperature and Scaling
                             ALFTS - Alternate training of Linker Function parameters and of Temperature and Scaling
                             SLFTS - Simultaneous training of Linker Function parameters and of Temperature and Scaling
                             GFV   - Get Function Value
                             GAO   - Get Average Occupancy
                             GFVAO - Get Function Value and Average Occupancy
                             GFVSP - Get Function Value and Sites log Probabilities.
                             GALP  - Get Accessibility Log Probabilities per position.
                             SC    - Sample Configurations

  -goal_func_type <str>:     type of goal function to be minimized. (default: AverageOccupancyBased)
                             one of:
                               AverageOccupancyBased
                               AverageOccupancyCorrelationBased
                               LinkerDistributionBased
                               LinkerFunctionBased           (in this case, the action is asserted to be 'LF')
                               FunctionalSitesAccessibilityBased  (in this case, the action is asserted to be 'LF' or 'SLFTS' or 'GFV' or 'GFVSP')

  -func_val_file <str>:      function value output file name (default: function_value.tab) relevant when action is GFV or GFVAO or GFVSP
  -av_occ_file <str>:        average occupancy output file name (default: av_occ.chr) relevant when action is GAO or GFVAO

  -all_param_out_file <str>: output file for all trained parameters (default: all_params_opt.tab) relevant and required when action is LF/TS/SLFTS/CIP

  -out_coop_file <str>:      name of output linker function params file (default: coop_out.tab) relevant and required when action is ALFTS
  -temp_out_file <str>:      temperature output file (default: temperature_opt.tab) relevant and required when action is ALFTS
  -scaling_out_file <str>:   scaling factors output file (default: scaling_opt.tab) relevant and required when action is ALFTS

  -train_toggle_file <str>:  training step type toggling file. relevant when action is ALFTS.
                             the file should contain a single tab delimited row with increasing positive integers.
                             NOTE - the row should NOT end with a newline.
                             for example, if "5  10  20" is given, then the training step type will be toggled in steps 5, 10, and 20.
  -train_toggle <int list>:  a comma seperated list of increasing positive integers, replacing the need to give an input train toggle file.
                             relevant when action is ALFTS. if train toggle file is given, then the train toggle list is ignored.
  -train_linker_first:       relevant when action is ALFTS. if set then will start with linker params training.
                             else, will start with temperature and scaling.

  -params2train <int list>:  a comma seperated list of indices (0-based) of the linker function parameters to be trained.
                             if not given then all linker params will be trained.

  -pert_file <str>:          perturbation step size per parameter file. relevant when action is LF/TS/SLFTS.
                             if given, then will try to escape from a local minimum basin by randomly picking another point
                             in the parameter space out of a subset of other possible points. this subset is determined by
                             the values given in 'pert_file', and by the 'max_pert_factor' (see below).
                             the file should contain a single tab delimited row with positive reals.
                             NOTE - the row should NOT end with a newline.
                             if action is LF - the values should correspond to the linker function parameters.
                                               note that if training only a subset of the parameters (see -params2train) then the values
                                               should correspond to the trained ones.
                             if action is TS - the (two) values should correspond to the temperature and nucleosome scaling factor.
                             if action is SLFTS - the first two values should correspond to the temperature and nucleosome scaling factor.
                                                  the remaining ones should correspond to the linker function parameters.
  -perts <int list>:         a comma seperated list of positive reals, replacing the need to give an input perturbations file.
                             relevant when action is LF/TS/SLFTS. if perturbations file is given, then the perturbations list is ignored.
  -max_pert_factor <int>:    the maximal perturbation jump factor. for the i-th parameter, an integer R from {0,...,'max_pert_factor'}
                             is randomly selected when computing a perturbation. This R is multiplied by the perturbation step size of 
                             the i-th parameter to get the actual i-th parameter perturbation size.
  -random_seed <int>:        the random seed used. for a specific value of the random seed, the sequence of perturbations is deterministic.
                             this enables reproducing run result for a certain run.
  -rand_seed_out_file <str>: random seed output file. may especially be of interest when random seed is not given as input (else will
                             simply contain the inputed seed). not created if name not given.

  -sites_file <str>:         an input data file that is required in case goal function type is FunctionalSitesAccessibilityBased,
                             unless action is GALP.
                             each row of the file describes a single site in a tab delimited format:

                             <seq_index>  <start_pos>  <end_pos>  <is_positive>  <factor>

                             seq_index   - 0 based index of the input sequence where the site is located
                             start_pos   - 0 based start position of the site within the sequence
                             end_pos     - 0 based end position of the site within the sequence
                             is_positive - 0/1 flag. '1' flags the site as functional. '0' as non-functional.
                             factor      - a positive real number, used as multiplicative factor of the contribution of this site.

  -use_sites_flags:          if set, will use the 'is_positive' flag of the input sites_file. in that case will assert that
                             all factors are positives.
                             default: ignores the flags, with negative factors representing "negative" sites.

  -sites_out_file <str>:     name of output chr file detailing site log probability of being accesible (default: "sites_out.chr").
                             relevant when action is GFVSP or GALP.

  -accessibe_radius <int>:   radius of accessibility around each position (default: 10).
                             to be used when computing genome-wide accesibility probs (when action is GALP and 'sites_file' not given).

  -samp_linkers_file <str>:  output file for linker lengths statistics derived from sampled configurations. relevant when action is SC.
                             if not given then linker statistics will not be computed.
  -samp_reads_file <str>:    output file for nucleosome reads derived from sampled configurations. relevant when action is SC.
                             if not given then nucleosome reads will not be computed.
  -cfg_num_samps_file <str>: output file detailing each sampled configuration (nucleosome start positions) and the number of times it was sampled.
                             if not given then the "times per configuration" stats will not be computed.
  -cfg_weights_file <str>:   output file detailing each sampled configuration (nucleosome start positions) and its normalized weight.
                             if not given then the "weight per configuration" stats will not be computed.
  -samps_per_seq_file <str>: num of configurations to sample per sequence file. relevant when action is SC.
                             the file should contain a single tab delimited row with positive integers.
                             NOTE - the row should NOT end with a newline.
                             if there are two input sequences, then an example of the file content is: "100   200". this means
                             that 100 configurations will be sampled on the first sequence, and 200 on the second one.
  -samps_per_seq <int list>: a comma seperated list of positive integers, replacing the need to give an input num samples per sequence file.
                             if the file is given then the list is ignored. relevant when action is SC.
  -num_samps <int>:          num of configurations to sample on each of the input sequences. replaces the need to use '-samps_per_seq_file'
                             and '-samps_per_seq'.
  -samp_per_bp:              if set then sampled reads stats will be per bp. relevant only if the '-samp_reads_file' is given.

  -xml:                      print only the xml file
  -log <str>:                print the stdout and stderr of the program into the file <str>
  -sxml <str>:               save the xml file into <str>

