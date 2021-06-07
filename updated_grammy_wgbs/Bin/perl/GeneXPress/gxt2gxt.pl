#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $output_track_name = get_arg("o", "", \%args);
my $output_track_type = get_arg("t", "Domain", \%args);

my $min_locations = get_arg("min_locations", 5, \%args);
my $min_experiments = get_arg("min_experiments", 10, \%args);

my $max_boundary_mismatches = get_arg("max_boundary_mismatches", 2, \%args);
my $max_avg_boundary_mismatches = get_arg("max_avg_boundary_mismatches", 2, \%args);
my $min_overlapping_experiments_fraction = get_arg("min_overlapping_experiments_fraction", 0.5, \%args);
my $domain_values = get_arg("domain_values", "Repressed Induced", \%args);

my $separate_domains = get_arg("no_separate_domains", 0, \%args) == 0 ? "true" : "false";
my $combined_domains = get_arg("no_combined_domains", 0, \%args) == 0 ? "true" : "false";
my $all_experiments = get_arg("no_all_experiments", 0, \%args) == 0 ? "true" : "false";
my $combined_experiment_sets = get_arg("combined_experiment_sets", 0, \%args) == 1 ? "true" : "false";
my $separate_experiment_sets = get_arg("separate_experiment_sets", 0, \%args) == 1 ? "true" : "false";
my $experiment_sets_file = get_arg("experiment_sets_file", "", \%args);

my $xml = get_arg("xml", 0, \%args);
my $run_file = get_arg("run", "", \%args);
my $save_xml_file = get_arg("sxml", "", \%args);

my $r = int(rand(100000));
my $tmp_xml = "tmp_$r.xml";
my $tmp_clu = "tmp_$r.clu";

my $exec_str = "bind.pl $ENV{TEMPLATES_HOME}/Runs/track2track.map ";

$exec_str .= "input_track_file=$file ";

$exec_str .= "output_track_file=$tmp_clu ";
$exec_str .= "output_track_name=$output_track_name ";
$exec_str .= "output_track_type=Chromosome${output_track_type}Track ";

$exec_str .= "min_locations=$min_locations ";
$exec_str .= "min_experiments=$min_experiments ";
$exec_str .= "max_boundary_mismatches=$max_boundary_mismatches ";
$exec_str .= "max_avg_boundary_mismatches=$max_avg_boundary_mismatches ";
$exec_str .= "min_overlapping_experiments_fraction=$min_overlapping_experiments_fraction ";
if (length($domain_values) > 0 and $domain_values ne "NULL") { $exec_str .= "domain_values='$domain_values' "; }

$exec_str .= "process_combined_domains=$combined_domains ";
$exec_str .= "process_separate_domains=$separate_domains ";
$exec_str .= "process_all_experiments=$all_experiments ";
$exec_str .= "process_combined_experiment_sets=$combined_experiment_sets ";
$exec_str .= "process_separate_experiment_sets=$separate_experiment_sets ";
if (length($experiment_sets_file) > 0) { $exec_str .= "experiment_sets_file=$experiment_sets_file "; }

$exec_str .= &AddStringProperty("sliding_window_length", &get_arg("window_size", 10000, \%args));
$exec_str .= &AddStringProperty("sliding_window_jump", &get_arg("window_jump", 1000, \%args));
$exec_str .= &AddStringProperty("sliding_window_max_value", &get_arg("window_max_value", "", \%args));
$exec_str .= &AddStringProperty("sliding_window_max_percentile_value", &get_arg("window_max_percentile_value", "", \%args));
$exec_str .= &AddStringProperty("sliding_window_min_value", &get_arg("window_min_value", "", \%args));
$exec_str .= &AddStringProperty("sliding_window_min_percentile_value", &get_arg("window_min_percentile_value", "", \%args));
$exec_str .= &AddStringProperty("sliding_window_min_num_values", &get_arg("window_min_num_values", "", \%args));

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file, $save_xml_file);

__DATA__

gxt2gxt.pl <file> 

    Creates a gxt from the gxt in <file> (e.g., from hmm to domain)

    -o <name>: Name of the output chromosome track
    -t <type>: Type of the output chromosome track (Cpd/Domain/Feature/Hmm, default: Domain)

    -xml:      Print only the xml

    SHARED Parameters:
      -min_locations <num>:                        (default: 5)
      -min_experiments <num>:                      (default: 10)
      -domain_values <name>:                       (default: 'Repressed Induced', enter NULL for no domain values)

    HMM -> DOMAIN Parameters:
      -max_boundary_mismatches <num>:              (default: 2)
      -max_avg_boundary_mismatches <num>:          (default: 2)
      -min_overlapping_experiments_fraction <num>: (default: 0.5)

    DOMAIN -> FEATURE Parameters:
      -no_separate_domains:                        (default: separate domains)
      -no_combined_domains                         (default: combined domains)
      -no_all_experiments:                         (default: all experiments)
      -combined_experiment_sets:                   (default: no combined experiment sets)
      -separate_experiment_sets:                   (default: no separate experiment sets)
      -experiment_sets_file <str>:                 tab-delimited file of experiment attributes

    FEATURE -> FEATURE Parameters:
      -window_size <num>:                          (default: 10000)
      -window_jump <num>:                          (default: 1000)
      -window_max_value <num>:                     (default: no constraints)
      -window_max_percentile_value <num>:          (default: no constraints)
      -window_min_value <num>:                     (default: no constraints)
      -window_min_percentile_value <num>:          (default: no constraints)
      -window_min_num_values <num>:                (default: 0)

