#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
  $file_ref = \*STDIN;
}
else
{
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $matrices_file = get_arg("m", "", \%args);
my $use_weight_matrix_name = get_arg("n", "", \%args);
my $process_weight_matrices_separately = get_arg("pws", "", \%args);
my $sequences_file = get_arg("s", "", \%args);
my $sequences_list = get_arg("l", "", \%args);
my $do_not_preload_sequences = get_arg("no_preload", 0, \%args);
my $sequences_iterator_length = get_arg("sil", "", \%args);
my $sequences_iterator_sliding_window = get_arg("siw", "", \%args);
my $background_order = get_arg("b", 0, \%args);
my $background_matrix_file = get_arg("bck", "", \%args);
my $background_to_matrices_ratio = get_arg("bckr", "-1", \%args);
my $use_local_background_matrix = get_arg("local_bck", 0, \%args);
my $temperature = get_arg("temp", 1.0, \%args);
my $regulator_scaling_factor = get_arg("rsf", "", \%args);
my $regulator_scaling_factor_file = get_arg("sff", "", \%args);

my $regulator_threshold_file = get_arg("rtf", "", \%args);

my $weight_matrices_stats_type = get_arg("t", "WeightMatrixPositions", \%args);
my $num_simulations = get_arg("sim", 0, \%args);
my $max_pvalue = get_arg("p", 1, \%args);
my $output_file_precision = get_arg("precision", 3, \%args);
my $no_reverse_complement = get_arg("norc", 0, \%args);
my $print_best_position = get_arg("best", 0, \%args);
my $print_best_across_windows = get_arg("best_windows", 0, \%args);
my $print_all_positions = get_arg("all", 0, \%args);
my $double_strand_binding = get_arg("ds", 0, \%args);

my $print_sum_matrices = get_arg("sum_matrices", 0, \%args);
my $do_not_print_separate_matrices = get_arg("no_separate_matrices", 0, \%args);
my $print_chv_format = get_arg("print_chv", 0, \%args);
my $weight_matrix_flank = get_arg("matrix_flank", 0, \%args);
my $moving_average_window = get_arg("moving_window", "", \%args);

my $min_score = get_arg("min_score", "", \%args);
my $min_average_occupancy = get_arg("min_avg", 0, \%args);
my $max_average_occupancy = get_arg("max_avg", 1, \%args);
my $print_start_average_occupancy = get_arg("start_avg", 0, \%args);
my $print_average_occupancy = get_arg("avg", 0, \%args);

my $dont_sort_by_scores = get_arg("dontSort", 0, \%args);
my $do_not_compare_to_background_matrix = get_arg("no_bck_compare", 0, \%args);

my $min_high_occupancy_sites = get_arg("mhos", 0.5, \%args);
my $weight_matrix_clustering_num_matrices = get_arg("wmcnm", 1, \%args);
my $weight_matrix_clustering_distance_window = get_arg("wmcdw", -1, \%args);
my $weight_matrix_clustering_distance_increment = get_arg("wmcdi", 10, \%args);

my $num_samples = get_arg("ns", 100, \%args);
my $configuration_adjacent_matrices_counts = get_arg("camc", "EMPTY_CAMC", \%args);
my $sequence_feature_description = get_arg("sfd", 0, \%args);
my $single_matrices_counts = get_arg("smc", 0, \%args);
my $all_matrices_counts = get_arg("amc", 0, \%args);
my $configuration_probabilities = get_arg("cp", 0, \%args);
my $configuration_matrices_coverage = get_arg("cmc", 0, \%args);
my $allow_zero_probabilities = get_arg("azp", 0, \%args);


my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

#my $matrices_file = get_arg("m", "", \%args);
#my $use_weight_matrix_name = get_arg("n", "", \%args);

if (!$allow_zero_probabilities and $weight_matrices_stats_type eq "WeightMatrixPositions"){
  if ($use_weight_matrix_name eq ""){
    my $out=`cat $matrices_file | grep -P ';0\\\"|0;'`;
    my $out2=`cat $matrices_file | grep -P 'PositionSpecific'`;
    if ($out ne "" and $out2 ne ""){ die ("zero probabilities not allowed in matrices!\n") }
  }
  else{
    my $out=`cat $matrices_file | gxw_select.pl -w $use_weight_matrix_name | grep -P 'PositionSpecific'`;
    my $out2=`cat $matrices_file | gxw_select.pl -w $use_weight_matrix_name | grep -P ';0\\\"|0;'`;
    if ($out ne "" and $out2 ne ""){ die ("zero probabilities not allowed in matrices (in $use_weight_matrix_name)!\n") }
  }
}

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/weight_matrices_stats.map ";

$exec_str .= "sequence_file=$sequences_file ";

if (length($sequences_list) > 0)
{
    $exec_str .= "sequence_list=$sequences_list ";
}

$exec_str .= &AddStringProperty("min_sequence_length", $sequences_iterator_length);
$exec_str .= &AddStringProperty("sliding_window_length", $sequences_iterator_sliding_window);

$exec_str .= &AddStringProperty("temperature", $temperature);

$exec_str .= &AddBooleanProperty("preload_sequences", $do_not_preload_sequences == 1 ? 0 : 1);

$exec_str .= &AddBooleanProperty("print_sum_weight_matrices", $print_sum_matrices);
$exec_str .= &AddBooleanProperty("print_separate_weight_matrices", $do_not_print_separate_matrices == 1 ? 0 : 1);
$exec_str .= &AddBooleanProperty("print_chv_format", $print_chv_format);
$exec_str .= &AddStringProperty("moving_average_window", $moving_average_window);

$exec_str .= &AddStringProperty("weight_matrix_flank", $weight_matrix_flank);

if (length($use_weight_matrix_name) > 0)
{
    $exec_str .= "weight_matrix_name=$use_weight_matrix_name ";
}

$exec_str .= "weight_matrices_file=$matrices_file ";

if ($process_weight_matrices_separately == 1) { $exec_str .= "process_weight_matrices_separately=true "; };

$exec_str .= "background_markov_order=$background_order ";
if (length($background_matrix_file) > 0) { $exec_str .= "background_matrix_file=$background_matrix_file "; }
$exec_str .= &AddStringProperty("background_to_matrices_ratio", $background_to_matrices_ratio);
if ($use_local_background_matrix == 1) { $exec_str .= "use_local_background=true "; }
$exec_str .= &AddStringProperty("regulator_scaling_factor", $regulator_scaling_factor);
$exec_str .= &AddStringProperty("scaling_factors_parameters_file", $regulator_scaling_factor_file);
$exec_str .= &AddStringProperty("REGULATOR_THRESHOLD_FILE", $regulator_threshold_file);




my $coop_file = get_arg("coop", "", \%args);
my $directional_cooperativity = &get_arg("dir_coop", 0, \%args);
my $directional_cooperativity_str = $directional_cooperativity == 1 ? "true" : "false";

if (-f $coop_file)
{
  $exec_str .= &AddStringProperty("cooperativity_parameters_file", $coop_file);
}

$exec_str .= &AddStringProperty("max_cooperativity_distance", &get_arg("mcd", "", \%args));
$exec_str .= &AddStringProperty("cooperativities_are_directional", $directional_cooperativity_str);

my $ghmm_inst_type = get_arg("ghmm", "", \%args);
if ( $ghmm_inst_type eq "" ) {
  if ( $coop_file eq "" ) {
    $ghmm_inst_type = "Basic";
  }
  else {
    $ghmm_inst_type = "Cooperative";
  }
}

$exec_str .= &AddStringProperty("GHMM_INST_TYPE", $ghmm_inst_type);

$exec_str .= &AddStringProperty("min_score", $min_score);
$exec_str .= &AddStringProperty("min_average_occupancy", $min_average_occupancy);
$exec_str .= &AddStringProperty("max_average_occupancy", $max_average_occupancy);
if ($print_start_average_occupancy == 1)
{
    $exec_str .= &AddStringProperty("sequence_stats", "StartProbabilityPerBp");
}
elsif ($print_average_occupancy == 1)
{
    $exec_str .= &AddStringProperty("sequence_stats", "AverageOccupancy");
}

$exec_str .= &AddStringProperty("min_high_occupancy_sites", $min_high_occupancy_sites);
$exec_str .= &AddStringProperty("weight_matrix_clustering_num_matrices", $weight_matrix_clustering_num_matrices);
$exec_str .= &AddStringProperty("weight_matrix_clustering_distance_window", $weight_matrix_clustering_distance_window);
$exec_str .= &AddStringProperty("weight_matrix_clustering_distance_increment", $weight_matrix_clustering_distance_increment);

if (length($regulator_scaling_factor) > 0)
{
  my @row = split(/\,/, $regulator_scaling_factor);

  if (length($row[1]) == 0)
  {
    $row[1] = $row[0];
    $row[2] = 10;
  }

  open(OUTFILE, ">tmp_scaling_$r");

  print OUTFILE "Parameters";
  for (my $scaling = $row[0]; $scaling <= $row[1]; $scaling *= $row[2])
  {
    print OUTFILE "\t";
    print OUTFILE &format_number($scaling, 3);
  }
  print OUTFILE "\n";

  print OUTFILE "Background";
  for (my $scaling = $row[0]; $scaling <= $row[1]; $scaling *= $row[2])
  {
    print OUTFILE "\t1";
  }
  print OUTFILE "\n";

  if (length($use_weight_matrix_name) > 0)
  {
    print OUTFILE "$use_weight_matrix_name";
    for (my $scaling = $row[0]; $scaling <= $row[1]; $scaling *= $row[2])
    {
      print OUTFILE "\t$scaling";
    }
    print OUTFILE "\n";
  }
  else
  {
    my $matrices_str = `gxw2consensus.pl $matrices_file | cut -f1`;
    my @matrices = split(/\n/, $matrices_str);
    for (my $i = 0; $i < @matrices; $i++)
    {
      print OUTFILE "$matrices[$i]";
      for (my $scaling = $row[0]; $scaling <= $row[1]; $scaling *= $row[2])
      {
	print OUTFILE "\t$scaling";
      }
      print OUTFILE "\n";
    }
  }

  $exec_str .= &AddStringProperty("scaling_factors_parameters_file", "tmp_scaling_$r");
}

$exec_str .= &AddStringProperty("maximum_allowed_sequence_inserts", &get_arg("masi", "", \%args));
$exec_str .= &AddBooleanProperty("force_double_strand_on_sequence_insert", &get_arg("fdsosi", "", \%args));
$exec_str .= &AddStringProperty("sequence_insert_penalty", &get_arg("sip", "", \%args));

$exec_str .= "weight_matrices_stats_type=$weight_matrices_stats_type ";
$exec_str .= "max_pvalue=$max_pvalue ";
$exec_str .= &AddStringProperty("output_file_precision", $output_file_precision);
$exec_str .= "num_simulations=$num_simulations ";

$exec_str .= &AddStringProperty("max_training_iterations", &get_arg("i", 100, \%args));

$exec_str .= "num_samples=$num_samples ";
if ($configuration_adjacent_matrices_counts ne "EMPTY_CAMC")
{
    $exec_str .= "configuration_adjacent_matrices_counts=true ";

    my @row = split(/\;/, $configuration_adjacent_matrices_counts);
    $exec_str .= "min_adjacent_matrices_distance=$row[0] ";
    $exec_str .= "max_adjacent_matrices_distance=$row[1] ";
    $exec_str .= "adjacent_matrices_distance_increment=$row[2] ";
    $exec_str .= &AddStringProperty("adjacent_matrices_stats_type", $row[3]);
    $exec_str .= &AddStringProperty("adjacent_matrices_function", $row[4]);
    $exec_str .= &AddStringProperty("adjacent_matrices_function_mean", $row[5]);
    $exec_str .= &AddStringProperty("adjacent_matrices_function_std", $row[6]);
}

if ($all_matrices_counts == 1) { $exec_str .= "all_matrices_counts=true "; }
if ($configuration_probabilities == 1) { $exec_str .= "configuration_probabilities=true "; }
if ($sequence_feature_description == 1) { $exec_str .= "sequence_feature_description=true "; }
if ($single_matrices_counts == 1) { $exec_str .= "single_matrices_counts=true "; }
if ($configuration_matrices_coverage == 1) { $exec_str .= "configuration_matrices_coverage=true "; }

if ($no_reverse_complement == 1) { $exec_str .= "reverse_complement=false "; }

if ($print_best_across_windows == 1) { $exec_str .= "find_best_across_windows=true "; }
if ($print_best_position == 1) { $exec_str .= "find_best_position=true "; }
if ($print_all_positions == 1) { $exec_str .= "score_all_positions=true "; }
if ($double_strand_binding == 1) { $exec_str .= "double_strand_binding=true "; }

if ($dont_sort_by_scores == 1) { $exec_str .= "dont_sort_by_scores=true "; }

if ($do_not_compare_to_background_matrix and $do_not_compare_to_background_matrix ne "false") { $exec_str .= &AddStringProperty("COMPARE_TO_BACKGROUND_MATRIX", "false"); }


if ( $weight_matrices_stats_type eq "WeightMatricesConfigurationSamplingFunction" ) {

  my $gcf_calc_type = get_arg("gcf_calc_type", "LogProbabilityOfFactorExistence", \%args);
  if ($gcf_calc_type eq "LogProbFactorExist")
    {
      $gcf_calc_type = "LogProbabilityOfFactorExistence";
    }


  $exec_str .= "GHMM_SAMPLED_CONFIGURATIONS_FUCNTION_CALCULATOR_TYPE=$gcf_calc_type ";

  my $gcf_weight_calc_type = get_arg("gcf_weight_calc_type", "Uniform", \%args);

  if ($gcf_weight_calc_type eq "LinDecayFactorInter")
    {
      $gcf_weight_calc_type = "LinearlyDecayingWeightsBetweenFactorPairsWithinBoundedDistances";
    }

 if ($gcf_weight_calc_type eq "ConstWeightsFactorInter")
    {
      $gcf_weight_calc_type = "ConstantWeightsBetweenFactorPairsWithinBoundedDistances";
    }

 

  $exec_str .= "GHMM_CONFIGURATION_WEIGHT_CALCULATOR_TYPE=$gcf_weight_calc_type ";

  my $gcf_sub_config_chr_file = get_arg("gcf_sub_config_chr_file", "", \%args);
  die "ERROR - gcf_sub_config_chr_file not given.\n" if ( $gcf_sub_config_chr_file eq "" );
  die "ERROR - gcf_sub_config_chr_file $gcf_sub_config_chr_file is not found.\n" unless ( -e $gcf_sub_config_chr_file || $xml );
  $exec_str .= "GHMM_SUB_CONFIGURATION_LOCATIONS_FILE_NAME=$gcf_sub_config_chr_file ";

  my $gcf_factor_names_file = get_arg("gcf_factor_names_file", "", \%args);

  my $gcf_sub_config_func_reg_ref_point = get_arg("gcf_sub_config_func_reg_ref_point", "Right", \%args);
  die "ERROR - unknown type of gcf_sub_config_func_reg_ref_point ($gcf_sub_config_func_reg_ref_point).\n" unless ( $gcf_sub_config_func_reg_ref_point =~ m/Left|Right/i );

  my $gcf_sub_config_func_reg_start_offset = get_arg("gcf_sub_config_func_reg_start_offset", "", \%args);
  my $gcf_sub_config_func_reg_end_offset = get_arg("gcf_sub_config_func_reg_end_offset", "", \%args);

  if ( $gcf_calc_type =~ m/LogProbabilityOfFactorExistence/i ) {
    die "ERROR - gcf_factor_names_file not given.\n" if ( $gcf_factor_names_file eq "" );
    die "ERROR - gcf_factor_names_file $gcf_factor_names_file is not found.\n" unless ( -e $gcf_factor_names_file || $xml );
  }

  if ( $gcf_calc_type =~ m/LogProbabilityOfFactorExistence/i ) {
    die "ERROR - gcf_sub_config_func_reg_ref_point not given.\n" if ( $gcf_sub_config_func_reg_ref_point eq "" );
    die "ERROR - gcf_sub_config_func_reg_start_offset not given.\n" if ( $gcf_sub_config_func_reg_start_offset eq "" );
    die "ERROR - gcf_sub_config_func_reg_end_offset not given.\n" if ( $gcf_sub_config_func_reg_end_offset eq "" );
  }

  $exec_str .= "GHMM_CONFIGURATION_FUNCTION_FACTOR_NAMES_LIST_FILE=$gcf_factor_names_file ";
  $exec_str .= "GHMM_SUB_CONFIGURATION_FUNCTION_REGION_REFERENCE_POINT_TYPE=$gcf_sub_config_func_reg_ref_point ";
  $exec_str .= "GHMM_SUB_CONFIGURATION_FUNCTION_REGION_START_OFFSET=$gcf_sub_config_func_reg_start_offset ";
  $exec_str .= "GHMM_SUB_CONFIGURATION_FUNCTION_REGION_END_OFFSET=$gcf_sub_config_func_reg_end_offset ";

  if ( $gcf_weight_calc_type =~ m/ConstantWeightsBetweenFactorPairsWithinBoundedDistances|LinearlyDecayingWeightsBetweenFactorPairsWithinBoundedDistances/i ) {
    my $gcf_interaction_func_params_file = get_arg("gcf_inter_func_params_file", "", \%args);
    die "ERROR - gcf_interaction_func_params_file not given.\n" if ( $gcf_interaction_func_params_file eq "" );
    die "ERROR - gcf_interaction_func_params_file $gcf_interaction_func_params_file is not found.\n" unless ( -e $gcf_interaction_func_params_file || $xml );

    my $gcf_interaction_max_dist_file = get_arg("gcf_inter_max_dist_file", "", \%args);
    die "ERROR - gcf_interaction_max_dist_file not given.\n" if ( $gcf_interaction_max_dist_file eq "" );
    die "ERROR - gcf_interaction_max_dist_file $gcf_interaction_max_dist_file is not found.\n" unless ( -e $gcf_interaction_max_dist_file || $xml );

    $exec_str .= "GHMM_CONFIGURATION_FACTORS_INTERACTION_FUNCTION_PARAMS_FILE=$gcf_interaction_func_params_file ";
    $exec_str .= "GHMM_CONFIGURATION_FACTORS_INTERACTION_MAX_DISTANCES_FILE=$gcf_interaction_max_dist_file ";
  }
}


$exec_str .= "output_file_stat=$tmp_clu ";

#print "$exec_str, $xml, $tmp_xml, $tmp_clu, $run_file, $save_xml_file\n";
&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file, $save_xml_file);

if (length($regulator_scaling_factor) > 0 and $xml != 1)
{
    system("rm tmp_scaling_$r");
}

__DATA__

gxw2stats.pl <gxw file>

   Takes a gxw file and a sequence fasta file and finds
   all positions of the matrices above the background

   -m <str>:         matrices file (gxw format)
   -n <str>:         use this matrix only out of the gxw file (default: use all matrices)
   -pws:             process weight matrices separately (applicable to all commands)

   -s <str>:         sequences file (fasta format)
   -l <str>:         use only these sequences from the file <str> (default: use all sequences in fasta file)
   -sil <num>:       use sliding window on sequence: this parameter specifies substring iterator length
   -siw <num>:       use sliding window on sequence: this parameter specifies distance between two substrings 
   -no_preload:      load the sequences one by one (default: preload the sequences)
   -temp <num>:      Temperature scaling (default: 1.0)

   -b <num>:         background order (default: 0)
   -bck <str>:       Background matrix file to load (optional, background will be computed form the sequences otherwise)
   -bckr <num>:      Background matrix to matrices ratio (default: -1 for equal value between background and matrices)
   -local_bck:       Compute the background locally for each sequence (as opposed to a single global matrix)

   -rsf <num>:       Regulator scaling factor (default: -1 for using the background ratios.
                     Format: <num> or <min>,<max>,<mul> where the latter is to go from min to max in multiplication jumps <mul>
   -sff <num>:       Regulator scaling factor file
   -coop <str>:      Cooperativity parameters file
   -mcd <num>:       Max cooperativity distance in basepairs (default: 100)
   -dir_coop         Use directional cooperativities (default: undirectional).
                     In directional cooperativity one can specify (see '-coop' flag) different cooperativity functions for A-B and B-A.
                     Notice: This option currently work with the 'BasicCooperative' but not the 'Cooperative' GHHM instance (see the '-ghmm' flag).

   -ghmm <str>:      Type of GHMM instance to be used
                     (default: if coop file is given - Cooperative ; else - Basic)
		     Options: Basic
                              BasicCooperative
                              Cooperative

   -rtf <str>:      Regulator Threshold File (format <regulator name>\t<threshold>). 
		    Threshold under which the probability of the Regulator to bind the DNA is epsilon
		    If the threshold is "NaN" then there is no threshold (threshold is -MAXDOUBLE)


   -sim <num>:       Number of simulations to perform (default: 0)
   -p <num>:         Max p-value for which to print (default: 1)
   -precision <num>: Precision for output file (default: 3)

   -i <num>:         max training iterations (default: 100)

   -best:            print the best score across the sequence (or individual windows)
   -best_windows:    print the best score across all windows

   -norc:            do *not* use reverse complement in sequence (default: use reverse complement)

   -t <str>:         stats type to compute (default: WeightMatrixPositions)
                     Options: WeightMatrixAverageOccupancy
                              WeightMatrixClustering
                              WeightMatrixCounts
                              WeightMatrixFreeEnergy
                              WeightMatrixMaxConfiguration
                              WeightMatrixPositions
                              WeightMatrixSequenceFeatures
			      WeightMatricesConfigurationSamplingFunction


   -xml:             print only the xml file
   -run <str>:       Print the stdout and stderr of the program into the file <str>
   -sxml <str>:      Save the xml file into <str>


   WeightMatrixAverageOccupancy
   ============================
   -min_avg <num>:        Minimum average occupancy to print (default: 0)
   -max_avg <num>:        Maximum average occupancy to print (default: 1)
   -start_avg:            Print the probability of starting matrices as opposed to average occupancies
   -avg:                  Print the fraction occupancy of the matrix across the entire region
   -matrix_flank <num>:   Compute the avg occupancy of the matrix only within its central bps without <num> flank on each side (default: 0)
   -sum_matrices:         Print the sum of all matrices
   -print_chv:            Print the results in a chv format
   -moving_window <num>:  Print the results as a combined (num/2 on each side) moving average window of <num>
   -no_separate_matrices: Do **not** print each matrix separately

   WeightMatrixPositions
   =====================
   -all:             print the score for each position
   -ds:              double-strand binding (average strands)
   -min_score <num>: Minimum score to print
   -masi <num>:      Maximum allowed sequence inserts
   -fdsosi:          Force double strand when doing sequence inserts
   -sip <num>:       Sequence insert penalty
   -dontSort:        don't sort according to score, print by position (useful when you want to intersect the results according to position)
   -no_bck_compare:  do not compare weight matrix stats to background matrix stats
   -azp:             Allow zero probabilities in weight matrix (default: not allowed)

   WeightMatrixClustering
   ======================
   -mhos <str>:      Minimum high occupancy sites (specify multiple cutoffs with ';', e.g., "0.1;0.2") (default: 0.5)
   -wmcnm <num>:     Weight matrix clustering num matrices (default: 1)
   -wmcdw <num>:     Weight matrix clustering distance window (default: -1 for cumulative clustering, not specific windows)
   -wmcdi <num>:     Weight matrix clustering distance increment (default: 10)

   WeightMatrixSequenceFeatures
   ============================
   -ns <num>:        Num samples
   -sfd:             Description sequence feature
   -smc:             Single matrices counts
   -amc:             All matrices counts
   -camc <str>:      Configuration adjacent matrices counts (str has the form: <min;max;inc;XXX;NoFunction/Gaussian;mean;std>)
                     [XXX] = CombinedAdjacentMatricesCount/SeparateAdjacentMatricesCount/SeparateProximalMatricesCount
   -cp:              Configuration probabilities
   -cmc:             Configuration matrices coverage

   WeightMatricesConfigurationSamplingFunction
   ===========================================
   -ns <num>:             Num configurations to sample on each sequence (default: 100).

   -gcf_calc_type <str>:  Type of function to calculate over sampled configurations.
			  One of:
                             <LogProbabilityOfFactorExistence> (= LogProbFactorExist   ,currently the only function).

   -gcf_weight_calc_type <str>: Type of configuration weight calculation (type of importance sampling).
                                One of:
                                  Uniform (the default)
                                  ConstantWeightsBetweenFactorPairsWithinBoundedDistances (altenranatively = ConstWeightsFactorInter)
                                  LinearlyDecayingWeightsBetweenFactorPairsWithinBoundedDistances (=LinDecayFactorInter)

   -gcf_sub_config_chr_file <str>: Name of chr file that defines for each sequence the region on which the weight is calculated.
                                   Each sequence is expected to appear exactly once.


   Parameters for the function to compute over the configurations probability distribution:
   ----------------------------------------------------------------------------------------

   -gcf_factor_names_file <str>:   Name of file containing a list of factor names (one per line). 
                                   For example, for LogProbabilityOfFactorExistence - the names of factor that exist/not exist

   -gcf_sub_config_func_reg_ref_point <str>: Within the sub-configuration region (defined in the chr file), it may be that
                                             only a sub-region will be used for the function calculation.
                                             This option defines a reference point for that sub-region within the
                                             sub-configuration region.
                                             One of:
                                               Left  - The start position of the sub-configuration region.
                                               Right - The end position of the sub-configuration region.
                                            (default: Right)

   -gcf_sub_config_func_reg_start_offset <int>: Offset of sub-region start from the reference point.
   -gcf_sub_config_func_reg_end_offset   <int>: Offset of sub-region end from the reference point.


   Parameters relevant for the 'ConstantWeightsBetweenFactorPairsWithinBoundedDistances'  (= 'ConstWeightsFactorInter')
   or the 'LinearlyDecayingWeightsBetweenFactorPairsWithinBoundedDistances' ( = 'LinDecayFactorInter') cases:
   -------------------------------------------------------------------------------------

   -gcf_inter_func_params_file <str>:  Name of a 2-column, tab-delimited, file detailing parameters of directional
                                             factor-factor interactions (in LOG space).
                                             Format example:
                                               Factor1,Factor2   -0.666

   -gcf_inter_max_dist_file <str>:     Name of a 2-column, tab-dliemited, file detailing max distance between
                                             interacting factor pairs.
                                             Format example:
                                               Factor1,Factor2   667 (the neighbot of the beast...)

   NOTE: The above two input files must contain exactly the same factor pairs.
         If a pair does not appear in them, then its interaction does not affect the configuration weight.

