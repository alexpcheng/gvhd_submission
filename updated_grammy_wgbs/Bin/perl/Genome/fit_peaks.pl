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

my $exec_str = &AddTemplate("$ENV{TEMPLATES_HOME}/Runs/fit_peaks.map");

$exec_str .= &AddStringProperty("input_track_file", &get_arg("d", "", \%args));

$exec_str .= &AddStringProperty("peak_resolution", &get_arg("peak_resolution", 10, \%args));
$exec_str .= &AddStringProperty("peak_shape_file", &get_arg("peak_shape_file", "", \%args));
$exec_str .= &AddStringProperty("peak_shape_mean", &get_arg("peak_shape_mean", 500, \%args));
$exec_str .= &AddStringProperty("peak_shape_std", &get_arg("peak_shape_std", 150, \%args));
$exec_str .= &AddStringProperty("output_peak_shape_file", &get_arg("output_peak_shape", "", \%args));
$exec_str .= &AddStringProperty("output_predicted_values_file", &get_arg("output_predicted_values", "", \%args));
if (length(&get_arg("peak_shape_file", "", \%args)) > 0)
{
  $exec_str .= &AddStringProperty("peak_shape_type", "FromFile");
}
else
{
  $exec_str .= &AddStringProperty("peak_shape_type", &get_arg("peak_shape_type", "NormalDistribution", \%args));
}

$exec_str .= &AddStringProperty("num_simulations", &get_arg("sim", 0, \%args));
$exec_str .= &AddStringProperty("max_pvalue", &get_arg("p", 1, \%args));

$exec_str .= &AddStringProperty("output_file", &get_arg("o", "out_peaks.gxt", \%args));

$exec_str .= &AddBooleanProperty("over_sample_data", &get_arg("over_sample_data", 0, \%args));
$exec_str .= &AddStringProperty("over_sample_file", &get_arg("over_sample_file", "", \%args));
$exec_str .= &AddStringProperty("over_sample_resolution", &get_arg("over_sample_resolution", 10, \%args));

if (&get_arg("use_baseline", 0, \%args) == 1)
{
  $exec_str .= &AddStringProperty("baseline_track_name", "baseline_track");
  $exec_str .= &AddStringProperty("baseline_track_file", &get_arg("baseline_file", "", \%args));
  $exec_str .= &AddStringProperty("sliding_window_length", &get_arg("window_size", 10000, \%args));
  $exec_str .= &AddStringProperty("sliding_window_jump", &get_arg("window_jump", 1000, \%args));
  $exec_str .= &AddStringProperty("sliding_window_max_value", &get_arg("window_max_value", "", \%args));
  $exec_str .= &AddStringProperty("sliding_window_max_percentile_value", &get_arg("window_max_percentile_value", "", \%args));
  $exec_str .= &AddStringProperty("sliding_window_min_value", &get_arg("window_min_value", "", \%args));
  $exec_str .= &AddStringProperty("sliding_window_min_percentile_value", &get_arg("window_min_percentile_value", "", \%args));
  $exec_str .= &AddStringProperty("sliding_window_min_num_values", &get_arg("window_min_num_values", "", \%args));
}

&RunGenie($exec_str, $xml, $tmp_xml, $tmp_clu, $run_file);

__DATA__

fit_peaks.pl

   Fits peaks in chips

   -d <str>:                           Data file as a gxt feature track file

   -peak_resolution <num>:             Peak resolution (default: 10 bp)
   -peak_shape_file <str>:             Peak shape file in the format (no header): <distance> <height>
   -peak_shape_type <num>:             NormalDistribution/GammaFunction (default: NormalDistribution)
   -peak_shape_mean <num>:             Mean for a Gamma function peak (default: 500)
   -peak_shape_std <num>:              Std for a Gamma function peak (default: 150)
   -output_peak_shape <str>:           Output peak shape file

   -sim <num>:                         Number of simulations to perform (default: 0)
   -p <num>:                           Max p-value for which to print (default: 1)

   -o <str>:                           Output peaks gxt track file (default: out_peaks.gxt)
   -output_predicted_values <str>:     Output predicted values file

   -over_sample_data:                  Oversample the data for the peak fitting (default: do not oversample)
   -over_sample_file <str>:            File for outputting the oversampled data
   -over_sample_resolution <num>:      Resolution for oversampling the data (default: 10 bp)

   -use_baseline:                      Use a sliding window as the baseline (default: no baseline)
   -baseline_file <str>:               File for outputting the baseline track
   -window_size <num>:                 (default: 10000)
   -window_jump <num>:                 (default: 1000)
   -window_max_value <num>:            (default: no constraints)
   -window_max_percentile_value <num>: (default: no constraints)
   -window_min_value <num>:            (default: no constraints)
   -window_min_percentile_value <num>: (default: no constraints)
   -window_min_num_values <num>:       (default: 0)

   -xml:                               Print only the xml file
   -run <str>:                         Print the stdout and stderr of the program into the file <str>

