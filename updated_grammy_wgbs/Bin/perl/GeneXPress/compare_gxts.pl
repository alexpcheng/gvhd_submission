#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

my $space = "___SPACE___";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $input_track_file = get_arg("i", "", \%args);
my $reference_track_file = get_arg("r", "", \%args);
my $comparison_track_file = get_arg("c", "", \%args);
my $num_simulations = get_arg("s", 100, \%args);
my $max_pvalue = get_arg("p", 1, \%args);
my $group_queries = get_arg("group_queries", 0, \%args);

my $xml = get_arg("xml", 0, \%args);

my $input_min_locations = get_arg("imin_locations", 5, \%args);
my $input_min_experiments = get_arg("imin_experiments", 10, \%args);
my $input_domain_values = get_arg("idomain_values", "Repressed${space}Induced", \%args);
my $input_feature_types = get_arg("ifeature_types", "Repressed;Induced", \%args);

my $input_separate_domains = get_arg("ino_separate_domains", 0, \%args) == 0 ? "true" : "false";
my $input_combined_domains = get_arg("ino_combined_domains", 0, \%args) == 0 ? "true" : "false";
my $input_separate_features = get_arg("ino_separate_features", 0, \%args) == 0 ? "true" : "false";
my $input_combined_features = get_arg("ino_combined_features", 0, \%args) == 0 ? "true" : "false";
my $input_separate_locations = get_arg("iseparate_locations", 0, \%args) == 0 ? "false" : "true";
my $input_all_experiments = get_arg("ino_all_experiments", 0, \%args) == 0 ? "true" : "false";
my $input_combined_experiment_sets = get_arg("icombined_experiment_sets", 0, \%args) == 1 ? "true" : "false";
my $input_separate_experiment_sets = get_arg("iseparate_experiment_sets", 0, \%args) == 1 ? "true" : "false";
my $input_experiment_sets_file = get_arg("iexperiment_sets_file", "", \%args);

my $comparison_min_locations = get_arg("cmin_locations", 5, \%args);
my $comparison_min_experiments = get_arg("cmin_experiments", 10, \%args);
my $comparison_domain_values = get_arg("cdomain_values", "Repressed${space}Induced", \%args);
my $comparison_feature_types = get_arg("cfeature_types", "Repressed;Induced", \%args);

my $output_track_file = get_arg("ot", "", \%args);
my $output_track_objects = get_arg("oto", 0, \%args);

my $comparison_separate_domains = get_arg("cno_separate_domains", 0, \%args) == 0 ? "true" : "false";
my $comparison_combined_domains = get_arg("cno_combined_domains", 0, \%args) == 0 ? "true" : "false";
my $comparison_separate_features = get_arg("cno_separate_features", 0, \%args) == 0 ? "true" : "false";
my $comparison_combined_features = get_arg("cno_combined_features", 0, \%args) == 0 ? "true" : "false";
my $comparison_separate_locations = get_arg("cseparate_locations", 0, \%args) == 0 ? "false" : "true";
my $comparison_all_experiments = get_arg("cno_all_experiments", 0, \%args) == 0 ? "true" : "false";
my $comparison_combined_experiment_sets = get_arg("ccombined_experiment_sets", 0, \%args) == 1 ? "true" : "false";
my $comparison_separate_experiment_sets = get_arg("cseparate_experiment_sets", 0, \%args) == 1 ? "true" : "false";
my $comparison_experiment_sets_file = get_arg("cexperiment_sets_file", "", \%args);

my $min_distance_per_input_interval = get_arg("mink", 0, \%args);
my $increment_distance_per_input_interval = get_arg("inck", 10000, \%args);
my $max_distance_per_input_interval = get_arg("maxk", 0, \%args);

my $input_intervals_operation_type = get_arg("iiot", "First", \%args);

my $query_breaking_input_locations = get_arg("qb", "", \%args);
my $query_max_breaking_intervals_per_input_location = get_arg("qb_maxb", 0, \%args);

my $query_proximal_input_locations = get_arg("qi", "", \%args);
my $query_proximal_comparison_locations = get_arg("qc", "", \%args);
my $query_input_length_locations = get_arg("ql", "", \%args);
my $query_average_comparison_locations = get_arg("qa", "", \%args);
my $query_average_input_locations = get_arg("qai", "", \%args);
my $query_intersecting_average_comparison_locations = get_arg("qia", "", \%args);
my $query_intersecting_average_input_locations = get_arg("qiai", "", \%args);
my $query_intersecting_average_comparison_locations_no_length_normalization = get_arg("qiann", "", \%args);
my $query_intersecting_average_input_locations_no_length_normalization = get_arg("qiainn", "", \%args);
my $query_cross_correlation_locations = get_arg("qr", "", \%args);
my $query_average_cross_correlation_locations = get_arg("qra", "", \%args);
my $query_positional_value_comparison_locations = get_arg("qp", "", \%args);
my $query_positional_value_input_locations = get_arg("qpi", "", \%args);
my $query_positional_value_average_comparison_locations = get_arg("qpa", "", \%args);
my $query_positional_value_average_input_locations = get_arg("qpia", "", \%args);

my $query_positional_value_symmetric = get_arg("qpsym", "", \%args);
my $query_positional_value_fraction_from_left = get_arg("qpfraction", "", \%args);
my $query_positional_value_bp_from_left = get_arg("qpleftbp", "", \%args);
my $query_positional_value_bp_from_right = get_arg("qprightbp", "", \%args);
my $query_positional_value_elementary_from_left = get_arg("qpleftelementary", "", \%args);
my $query_positional_value_opportunistic = get_arg("qpopportunistic", "", \%args);

$query_breaking_input_locations =~ s/ /$space/g;
$query_proximal_input_locations =~ s/ /$space/g;
$query_proximal_comparison_locations =~ s/ /$space/g;
$query_input_length_locations =~ s/ /$space/g;
$query_average_comparison_locations =~ s/ /$space/g;
$query_average_input_locations =~ s/ /$space/g;
$query_intersecting_average_comparison_locations =~ s/ /$space/g;
$query_intersecting_average_input_locations =~ s/ /$space/g;
$query_intersecting_average_comparison_locations_no_length_normalization =~ s/ /$space/g;
$query_intersecting_average_input_locations_no_length_normalization =~ s/ /$space/g;
$query_cross_correlation_locations =~ s/ /$space/g;
$query_average_cross_correlation_locations =~ s/ /$space/g;
$query_positional_value_comparison_locations =~ s/ /$space/g;
$query_positional_value_input_locations =~ s/ /$space/g;
$query_positional_value_average_comparison_locations =~ s/ /$space/g;
$query_positional_value_average_input_locations =~ s/ /$space/g;

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/compare_tracks.map ";

$exec_str .= "input_track_file=$input_track_file ";
if (length($reference_track_file) > 0) { $exec_str .= "reference_track_file=$reference_track_file "; }
$exec_str .= "comparison_track_file=$comparison_track_file ";

$exec_str .= "num_simulations=$num_simulations ";
$exec_str .= "max_pvalue=$max_pvalue ";
$exec_str .= "output_file=$tmp_clu ";
$exec_str .= &AddStringProperty("output_track_file", $output_track_file);
$exec_str .= &AddBooleanProperty("output_chromosome_track_objects", $output_track_objects);

$exec_str .= "input_min_locations=$input_min_locations ";
$exec_str .= "input_min_experiments=$input_min_experiments ";
if (length($input_domain_values) > 0 and $input_domain_values ne "NULL") { $exec_str .= "input_domain_values='$input_domain_values' "; }
if (length($input_feature_types) > 0 and $input_feature_types ne "NULL") { $exec_str .= "input_feature_types='$input_feature_types' "; }

$exec_str .= "input_process_combined_domains=$input_combined_domains ";
$exec_str .= "input_process_separate_domains=$input_separate_domains ";
$exec_str .= "input_process_combined_features=$input_combined_features ";
$exec_str .= "input_process_separate_features=$input_separate_features ";
$exec_str .= "input_process_separate_locations=$input_separate_locations ";
$exec_str .= "input_process_all_experiments=$input_all_experiments ";
$exec_str .= "input_process_combined_experiment_sets=$input_combined_experiment_sets ";
$exec_str .= "input_process_separate_experiment_sets=$input_separate_experiment_sets ";
if (length($input_experiment_sets_file) > 0) { $exec_str .= "input_experiment_sets_file=$input_experiment_sets_file "; }

$exec_str .= "comparison_min_locations=$comparison_min_locations ";
$exec_str .= "comparison_min_experiments=$comparison_min_experiments ";
if (length($comparison_domain_values) > 0 and $comparison_domain_values ne "NULL") { $exec_str .= "comparison_domain_values='$comparison_domain_values' "; }
if (length($comparison_feature_types) > 0 and $comparison_feature_types ne "NULL") { $exec_str .= "comparison_feature_types='$comparison_feature_types' "; }

$exec_str .= "comparison_process_combined_domains=$comparison_combined_domains ";
$exec_str .= "comparison_process_separate_domains=$comparison_separate_domains ";
$exec_str .= "comparison_process_combined_features=$comparison_combined_features ";
$exec_str .= "comparison_process_separate_features=$comparison_separate_features ";
$exec_str .= "comparison_process_separate_locations=$comparison_separate_locations ";
$exec_str .= "comparison_process_all_experiments=$comparison_all_experiments ";
$exec_str .= "comparison_process_combined_experiment_sets=$comparison_combined_experiment_sets ";
$exec_str .= "comparison_process_separate_experiment_sets=$comparison_separate_experiment_sets ";
if (length($comparison_experiment_sets_file) > 0) { $exec_str .= "comparison_experiment_sets_file=$comparison_experiment_sets_file "; }

$exec_str .= "min_distance_per_input_interval=$min_distance_per_input_interval ";
$exec_str .= "increment_distance_per_input_interval=$increment_distance_per_input_interval ";
$exec_str .= "max_distance_per_input_interval=$max_distance_per_input_interval ";
$exec_str .= "min_offset_per_input_interval=$min_distance_per_input_interval ";
$exec_str .= "increment_offset_per_input_interval=$increment_distance_per_input_interval ";
$exec_str .= "max_offset_per_input_interval=$max_distance_per_input_interval ";
$exec_str .= "input_intervals_operation_type=$input_intervals_operation_type ";

if (length($query_breaking_input_locations) > 0)
{ 
    $exec_str .= "query_breaking_input_locations=$query_breaking_input_locations ";
    $exec_str .= "max_breaking_intervals_per_input_location=$query_max_breaking_intervals_per_input_location ";
}
if (length($query_proximal_input_locations) > 0) { $exec_str .= "query_proximal_input_locations=$query_proximal_input_locations "; }
if (length($query_proximal_comparison_locations) > 0) { $exec_str .= "query_proximal_comparison_locations=$query_proximal_comparison_locations "; }
if (length($query_input_length_locations) > 0) { $exec_str .= "query_input_length_locations=$query_input_length_locations "; }
if (length($query_average_comparison_locations) > 0) { $exec_str .= "query_average_comparison_locations=$query_average_comparison_locations "; }
$exec_str .= &AddStringProperty("query_average_input_locations", $query_average_input_locations);
$exec_str .= &AddStringProperty("query_intersecting_average_input_locations", $query_intersecting_average_input_locations);
$exec_str .= &AddStringProperty("query_intersecting_average_comparison_locations", $query_intersecting_average_comparison_locations);
$exec_str .= &AddStringProperty("query_intersecting_average_input_locations_no_length_normalization", $query_intersecting_average_comparison_locations_no_length_normalization);
$exec_str .= &AddStringProperty("query_intersecting_average_comparison_locations_no_length_normalization", $query_intersecting_average_input_locations_no_length_normalization);
$exec_str .= &AddStringProperty("query_cross_correlation_locations", $query_cross_correlation_locations);
$exec_str .= &AddStringProperty("query_average_cross_correlation_locations", $query_average_cross_correlation_locations);
$exec_str .= &AddStringProperty("query_positional_value_comparison_locations", $query_positional_value_comparison_locations);
$exec_str .= &AddStringProperty("query_positional_value_input_locations", $query_positional_value_input_locations);
$exec_str .= &AddStringProperty("query_positional_value_average_comparison_locations", $query_positional_value_average_comparison_locations);
$exec_str .= &AddStringProperty("query_positional_value_average_input_locations", $query_positional_value_average_input_locations);

$exec_str .= &AddBooleanProperty("group_queries", $group_queries);

$exec_str .= &AddBooleanProperty("query_positional_value_symmetric", $query_positional_value_symmetric);
if (length($query_positional_value_fraction_from_left) > 0)
{
    my @row = split(/\,/, $query_positional_value_fraction_from_left);
    $exec_str .= &AddStringProperty("query_positional_value_fraction_from_left_start", $row[0]);
    $exec_str .= &AddStringProperty("query_positional_value_fraction_from_left_end", $row[1]);
    $exec_str .= &AddStringProperty("query_positional_value_fraction_from_left_window", $row[2]);
}
if (length($query_positional_value_bp_from_left) > 0)
{
    my @row = split(/\,/, $query_positional_value_bp_from_left);
    $exec_str .= &AddStringProperty("query_positional_value_bp_from_left_start", $row[0]);
    $exec_str .= &AddStringProperty("query_positional_value_bp_from_left_end", $row[1]);
    $exec_str .= &AddStringProperty("query_positional_value_bp_from_left_window", $row[2]);
}
if (length($query_positional_value_bp_from_right) > 0)
{
    my @row = split(/\,/, $query_positional_value_bp_from_right);
    $exec_str .= &AddStringProperty("query_positional_value_bp_from_right_start", $row[0]);
    $exec_str .= &AddStringProperty("query_positional_value_bp_from_right_end", $row[1]);
    $exec_str .= &AddStringProperty("query_positional_value_bp_from_right_window", $row[2]);
}
if (length($query_positional_value_elementary_from_left) > 0)
{
    my @row = split(/\,/, $query_positional_value_elementary_from_left);
    $exec_str .= &AddStringProperty("query_positional_value_elementary_from_left_start", $row[0]);
    $exec_str .= &AddStringProperty("query_positional_value_elementary_from_left_end", $row[1]);
    $exec_str .= &AddStringProperty("query_positional_value_elementary_from_left_window", $row[2]);
}
if (length($query_positional_value_opportunistic) > 0)
{
    $exec_str .= &AddStringProperty("query_positional_value_opportunistic_windows", "true");
    $exec_str .= &AddStringProperty("query_positional_value_opportunistic_windows_fraction", $query_positional_value_opportunistic);
}

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu);

__DATA__

compare_gxts.pl

    Compares gxts with simulations

    -i <file>:     File name of the input track
    -r <file>:     File name of the reference track
    -c <file>:     File name of the comparison track

    -s <num>:      Num simulations (default: 100)
    -p <num>:      Max Pvalue (default: 1)
   -group_queries: Print a query if any other query passed the p-value threshold

    -xml:          Print only the xml

    <***IMPORTANT***>: The parameters below should be prefixed with "i" or "c" to represent parameters to 
                       either the input or the comparison track (e.g., min_locations --> imin_locations for 
                       specifying a minimum number of locations for the input track)

    SHARED Parameters:
      -min_locations <num>:                        (default: 5)

    DOMAIN Parameters:
      -min_experiments <num>:                      (default: 10)
      -domain_values <name>:                       (default: 'Repressed Induced', enter NULL for no domain values)
      -no_separate_domains:                        (default: separate domains)
      -no_combined_domains                         (default: combined domains)
      -no_all_experiments:                         (default: all experiments)
      -combined_experiment_sets:                   (default: no combined experiment sets)
      -separate_experiment_sets:                   (default: no separate experiment sets)
      -experiment_sets_file <str>:                 tab-delimited file of experiment attributes

    FEATURE Parameters:
      -feature_types <name>:                       (default: 'Repressed Induced', enter NULL for no feature types)
      -no_separate_features:                       (default: separate features)
      -no_combined_features                        (default: combined features)
      -separate_locations                          (default: no separate locations)

    OUTPUT
      -ot <str>:                                   Output results into a track gxt file
      -oto:                                        Output the actual objects of each result into the track gxt file

    COMPARISON QUERIES

      -mink <num>:                                 Min k bp distance between input and comparison locations (default: 0)
      -inck <num>:                                 Increment k in <num> chunks (default: 10000)
      -maxk <num>:                                 Max k bp distance between input and comparison locations (default: 0)
      -iiot <str>:                                 Input intervals operation type (for cross correlations)
                                                   (All/Max/First default: First)

      -qb <name>:                                  Count input locations that do not break comparison locations <name is the query name>
      -qb_maxb <num>:                              Max breaking intervals per input interval (default: 0)

      -qi <name>:                                  Count input locations within comparison locations <name is the query name>
      -qc <name>:                                  Count comparison locations within input locations <name is the query name>
      -ql <name>:                                  Count average length of input locations <name is the query name>
      -qa <name>:                                  Count average value of comparison locations
      -qai <name>:                                 Count average value of input locations
      -qia <name>:                                 Count average value of comparison locations with intersecting locations
      -qiai <name>:                                Count average value of input locations with intersecting locations
      -qiann <name>:                               Count average value of comparison locations with intersecting locations (no length normalization)
      -qiainn <name>:                              Count average value of input locations with intersecting locations (no length normalization)
      -qr <name>:                                  Compute cross correlation <name is the query name>
      -qra <name>:                                 Compute average cross correlation <name is the query name>
      -qp <name>:                                  Compuate average value of comparison location according to positions aligned by input locations 
      -qpi <name>:                                 Compuate average value of input location according to positions aligned by comparison locations 
      -qpa <name>:                                 Compuate average value of comparison location according to positions aligned by input locations (report average comparison) 
      -qpia <name>:                                Compuate average value of input location according to positions aligned by comparison locations (report average input)

    POSITIONAL VALUE QUERIES
      -qpsym:                                      Symmetric treatment of left/right borders of aligned positions
      -qpfraction <num1,num2,num3>                 Fraction from left (num1 = start fraction, num2 = end fraction, num3 = fraction window)
      -qpleftbp <num1,num2,num3>                   Bp from left (num1 = start bp from left, num2 = end bp from left, num3 = left bp window)
      -qprightbp <num1,num2,num3>                  Bp from right (num1 = start bp from right, num2 = end bp from right, num3 = right bp window)
      -qpleftelementary <num1,num2,num3>           Num of items from elementary track from left (num1 = from left, num2 = from left, num3 = window)
      -qpopportunistic <num>:                      Perform an opportunistic alignment: each input is reversed if the sum of the first <num> fraction
                                                   of queries is greater than the sum of the last <num> fraction of queries

