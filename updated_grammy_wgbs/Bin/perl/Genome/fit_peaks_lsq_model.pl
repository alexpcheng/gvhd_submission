#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA>;
   exit;
}

my %args = load_args(\@ARGV);
my $DEBUG = get_arg("debug", 0, \%args);

$DEBUG and print STDERR "** DEBUG MODE **\n";

my $signal_file = $ARGV[0];
my $signal_file_ref;

if (length($signal_file) < 1 or $signal_file =~ /^-/) 
{
   #$signal_file_ref = \*STDIN;
   die("Sorry dude, I don't work with pipeline... Pass the signal chv file as the first argument.\n");
}
else
{
   open(SIGNAL_FILE, $signal_file) or die("Could not open the signal chr file '$signal_file'.\n");
   $signal_file_ref = \*SIGNAL_FILE;
}

my $peak_shape_init_file = get_arg("shape", "", \%args);
my $peak_shape_init_length = get_arg("slength", 147, \%args);
my $arg_num_iterations = get_arg("iter", 1, \%args);
my $value_column = get_arg("vc", 5, \%args);

my $r = int(rand(1000000));
my $tmp_output_dir = "TMP_peak_fitting_iter_" . "$arg_num_iterations" . "_rand" . "$r";
system("mkdir -p $tmp_output_dir");
my $segment_counter = 1;

my $arg_peak_shape_init_file;

if (length($peak_shape_init_file) > 0)
{
   $arg_peak_shape_init_file = $peak_shape_init_file;
   open(FILE, $arg_peak_shape_init_file) or die("Could not open the peak shape initial file '$arg_peak_shape_init_file'.\n");
   close(FILE);
}
elsif (0)
{
   $arg_peak_shape_init_file = "$tmp_output_dir" . "/init_peak_shape";
   open(FILE, ">$arg_peak_shape_init_file") or die("Could not open a file '$arg_peak_shape_init_file' for writing.\n");

   for (my $i=0; $i < $peak_shape_init_length; $i++)
   {
      my $v = rand(1);
      print FILE "$v\n";
   }

   close(FILE);

   print STDERR "Random initial peak shape\n";
}

my $arg_signal_file = "$tmp_output_dir" . "/signal_file" . "$segment_counter";
my $arg_locations_file = "$tmp_output_dir" . "/locations_file" . "$segment_counter";
my $arg_output_inferred_centers_of_peaks_file_name = get_arg("ocp", "peak_fitting_inferred_centers_of_peaks.chv", \%args);
my $arg_output_inferred_average_occupancy_file_name = get_arg("oao", "peak_fitting_inferred_ave_occ.chv", \%args);

open(ARG_SIGNAL_FILE, ">$arg_signal_file") or die("Could not open the file '$arg_signal_file' for writing.\n");
open(ARG_LOCATIONS_FILE, ">$arg_locations_file") or die("Could not open the file '$arg_locations_file' for writing.\n");
open(OUTPUT_CENTERS_OF_PEAKS_FILE, ">$arg_output_inferred_centers_of_peaks_file_name") or die("Could not open the file '$arg_output_inferred_centers_of_peaks_file_name' for writing.\n");
open(OUTPUT_AVE_OCC_FILE, ">$arg_output_inferred_average_occupancy_file_name") or die("Could not open the file '$arg_output_inferred_average_occupancy_file_name' for writing.\n");

my $arg_output_figure_file_name = get_arg("ofig", "", \%args);
my $arg_output_figure_file_format = get_arg("figmat", "png", \%args);
my $arg_output_inferred_peak_shape_file_name = get_arg("opeak", "peak_fitting_inferred_peak_shape.tab", \%args);
my $arg_output_resnorm_file_name = get_arg("oresnorm", "", \%args);

my $arg_enforce_symmetry = get_arg("sym", 0, \%args);
$arg_enforce_symmetry = (length($arg_enforce_symmetry) == 0) ? 1 : $arg_enforce_symmetry;
my $arg_binding_start = get_arg("bstart", 1, \%args);
my $arg_binding_length = get_arg("blength", 147, \%args);
my $max_gap = get_arg("maxgap", 100, \%args);
my $min_length = get_arg("minl", 150, \%args);
my $max_length = get_arg("maxl", 10000, \%args);

my @queue = ();
my $line = <SIGNAL_FILE>;
chomp($line);
my @r = split(/\t/,$line);
my $global_chr = $r[0];
my $global_start = $r[2];
my $last_start = 0;
my $start;
my $item_jump;
my $val;
my $segment_not_fitted = 1;

while(length($line) > 0)
{
   @r = split(/\t/,$line);
   my $chr = $r[0];
   $segment_not_fitted = 1;

   if ($chr eq $global_chr)
   {
      # continue processing this chromosome

      $start = $r[2] - $global_start + 1;

      if ((($start - $last_start) > $max_gap) or ($start > $max_length))
      {
	 # compute peak fitting for last segment
	 &ComputeSegmentPeakFitting();

	 $segment_not_fitted = 0;
	 $global_start = $r[2];
	 $last_start = 0;
	 unshift(@queue, $line);
      }
      else
      {
	 $val = $r[$value_column];
	 my $tmp_location = $start;

	 print ARG_SIGNAL_FILE "$val\t";
	 print ARG_LOCATIONS_FILE "$tmp_location\t";

	 $last_start = $tmp_location;
      }
   }
   else
   {
      # compute peak fitting for last segment of previous chromosome
      &ComputeSegmentPeakFitting();

      $segment_not_fitted = 0;
      $global_chr = $chr;
      $global_start = $r[2];
      $last_start = 0;
      unshift(@queue, $line);
   }

   $line = &NextSignalLine();
}

if ( $segment_not_fitted )
{
   &ComputeSegmentPeakFitting();
}

&Finish();

#-------------#
# Subroutines #
#-------------#

#--------------------------------------#
# 1 = &Finish()                        #
#--------------------------------------#
sub Finish
{
   my $arg_output_inferred_peak_shape_files = "$tmp_output_dir" . "/inf_peak_shape_file";
   my $tmp_num_iterations = $arg_num_iterations - 1;

   print STDERR "Number of iterations left: $tmp_num_iterations\n";

   system("paste $arg_output_inferred_peak_shape_files\* | transpose.pl -q | compute_column_stats.pl -skip 0 -skipc 0 -med | cut.pl -f 2- | transpose.pl -q > $arg_output_inferred_peak_shape_file_name");

   if ($arg_num_iterations > 1)
   {
      my $self_param = "\"$signal_file\" -shape \"$arg_output_inferred_peak_shape_file_name\" -slength $peak_shape_init_length -ofig \"$arg_output_figure_file_name\" -figmat $arg_output_figure_file_format -opeak \"$arg_output_inferred_peak_shape_file_name\" -ocp $arg_output_inferred_centers_of_peaks_file_name -oao $arg_output_inferred_average_occupancy_file_name -iter $tmp_num_iterations -sym $arg_enforce_symmetry -bstart $arg_binding_start -blength $arg_binding_length -maxgap $max_gap -minl $min_length";

      #exec("fit_peaks_lsq_model.pl $self_param");
      system("fit_peaks_lsq_model.pl $self_param");
   }
   elsif ($arg_num_iterations == 1)
   {
      #system ("rm -rf $tmp_output_dir");
   }

   return 1;
}

#--------------------------------------#
# ???   = &ComputeSegmentPeakFitting() #
#--------------------------------------#
sub ComputeSegmentPeakFitting
{
   print ARG_SIGNAL_FILE "\n";
   print ARG_LOCATIONS_FILE "\n";

   close(ARG_SIGNAL_FILE);
   close(ARG_LOCATIONS_FILE);

   my $tmp_chr = $global_chr;
   my $tmp_id = "Segment" . "$segment_counter";
   my $tmp_start = $global_start;
   my $tmp_end = ($global_start - 1) + $last_start;
   my $tmp_length = $tmp_end - $tmp_start + 1;

   print STDERR "$tmp_chr\t$tmp_id\t$tmp_start\t$tmp_end\t$tmp_length\n";

   my $arg_output_inferred_peak_shape_file = "$tmp_output_dir" . "/inf_peak_shape_file" . "$segment_counter";
   my $arg_output_figure_file = ($arg_num_iterations == 1) ? "$arg_output_figure_file_name" . "_segment" . "$segment_counter" : "";
   my $arg_output_resnorm_file = "$arg_output_resnorm_file_name" . "_segment" . "$segment_counter";
   my $arg_output_inferred_centers_of_peaks_file = ($arg_num_iterations == 1) ? "$tmp_output_dir" . "/centers_of_peaks" . "$segment_counter" : "";
   my $arg_output_inferred_average_occupancy_file = ($arg_num_iterations == 1) ? "$tmp_output_dir" . "/ave_occ" . "$segment_counter" : "";

   my $params = "(\'$arg_signal_file\',\'$arg_locations_file\',\'$arg_peak_shape_init_file\',\'$arg_output_figure_file\',\'$arg_output_figure_file_format\',\'$arg_output_inferred_peak_shape_file\',\'$arg_output_inferred_centers_of_peaks_file\',\'$arg_output_inferred_average_occupancy_file\',$arg_enforce_symmetry,$arg_binding_start,$arg_binding_length,\'$arg_output_resnorm_file\')";

   my $matlabDev = "$ENV{DEVELOP_HOME}/Matlab";
   my $mfile = "peak_fitting";
   my $matlabPath = "matlab";

   my $command = "$matlabPath -nodisplay -nodesktop -nojvm -nosplash -r \"path (path,'$matlabDev'); $mfile$params; exit;\" > /dev/null";

   if ($tmp_length >= $min_length)
   {

      print STDERR "Calling Matlab with: $command\n";

      my $failed_to_run_matlab = 0;

      my $command_results = system($command);

      while($command_results != 0)
      {
	 $command_results = system($command);
	 $failed_to_run_matlab = 1;
	 sleep(10);
      }

      sleep(10);

      $failed_to_run_matlab and print STDERR "Failed to run Matlab\n";

      if ($arg_num_iterations == 1)
      {
	 chomp($tmp_end);
	 my $type_name = "InferredCentersOfPeaks";
	 my $tmp_vals = `cat $arg_output_inferred_centers_of_peaks_file | sed 's/\t/\;/g' | sed -r 's/\ +//g'`;

	 chomp($tmp_vals);
	 chop($tmp_vals);

	 print OUTPUT_CENTERS_OF_PEAKS_FILE "$tmp_chr\t$tmp_id\t$tmp_start\t$tmp_end\t$type_name\t1\t1\t$tmp_vals\n";

	 $tmp_end = ($global_start - 1) + `cat $arg_output_inferred_average_occupancy_file | transpose.pl -q | wc | sed -r 's/[ ]+/\t/g' | cut.pl -f 2`;
	 chomp($tmp_end);

	 $tmp_vals = `cat $arg_output_inferred_average_occupancy_file | sed 's/\t/\;/g'`;
	 chomp($tmp_vals);
	 chop($tmp_vals);


	 print OUTPUT_AVE_OCC_FILE "$tmp_chr\t$tmp_id\t$tmp_start\t$tmp_end\t$type_name\t1\t1\t$tmp_vals\n";
      }
   }

   $segment_counter++;

   $arg_signal_file = "$tmp_output_dir" . "/signal_file" . "$segment_counter";
   $arg_locations_file = "$tmp_output_dir" . "/locations_file" . "$segment_counter";

   open(ARG_SIGNAL_FILE, ">$arg_signal_file") or die("Could not open the file '$arg_signal_file' for writing.\n");
   open(ARG_LOCATIONS_FILE, ">$arg_locations_file") or die("Could not open the file '$arg_locations_file' for writing.\n");

   return 1;
}

#---------------------------#
# $line = &NextSignalLine() #
#---------------------------#
sub NextSignalLine
{
   my $line1 = "";

   if (@queue > 0)
   {
      $line1 = shift(@queue);
   }
   elsif ($line1 = <SIGNAL_FILE>)
   {
      chomp($line1);
   }

   return $line1;
}


__DATA__

Syntax:

    fit_peaks_lsq_model.pl <file.chr>

Description:

    A peak fitting algorithem for a location data <file.chr>.

    Given a peak shape, the method fits a model for the data, that assumes the signal
    to be noisy measurements (normaly distributed with a fixed variance) of a non-negative
    linear combination of local peaks and a global baseline signal.
    As an option, one can try to optimize the peak shape as well. This is done by first taking
    the peak shape as fixed and optimizing for the "concentrations" of the peaks, and then take 
    these "concentrations" as fixed and optimizing for the peak shape.

    *** Assumes <file.chr> has "objects" that are unique and of size 1bp only, and that they
        are sorted by chromosome (lexicographic) and then by "start" (numeric). 
        Also, that there is no "reveresed object". ***

    *** Do not work with pipeline!! ***

Output:

    Does not output anything to the STDOUT. Rather, save a CHV file format of the inferred
    average occupancy and of the centers-of-peaks, plus possibly a figure of both.

Flags:

arg_output_resnorm_file

    -shape <file>          The peak shape file, in the format: <value1> \n <value2> \n ... \n <valueN> 

    -ofig <str>            The output figure file name (default: no figure).

    -figmat <fm>           The figure file format, where <fm> = 
                           ai/bmp/emf/eps/fig/jpg/m/pbm/pcx/pgm/png/ppm/tif (default: png).

    -opeak <str>           The inferred peak shape output file name 
                           (default: peak_fitting_inferred_peak_shape.tab).

    -ocp <str>             The inferred center-of-peaks (chv format) output file name 
                           (default: peak_fitting_inferred_centers_of_peaks.chv).

    -oao <str>             The inferred average occupancy (chv format) output file name 
                           (default: peak_fitting_inferred_ave_occ.chv).

    -oresnorm <str>        An output file with value of the squared 2-norm of the residual and 
                           the number of fitted parameters (default: do not output this file).

    -iter <int>            The number of iteration for peak shape learning (default: 1, 
                           i.e. use only the initial given peak shape, with no learning).

    -sym                   Enforce a symmetry on the peak shape (default: do not inforce symmtery).

    -bstart <int>          The start of the binding relative to the peak shape start (default: 1, 
                           i.e. the peak shape starts where the binding starts).

    -blength <int>         The length of the binding relative to the binding start (by '-bstart')
                           (default: 147bp, as for a nucleosome)

    -maxgap <int>          When consecutive locations are distanced more than <int>, we break into 
                           independent segments for the peak fitting algorithem (default: 100bp).

    -minl <int>            Minimnum length for a segment to be fitted (default: 150bp).

    -maxl <int>            Maximum length for a segment to be fitted (default: 10kbp).
                           ***The next segment would have only 1bp overlap***

    -vc <int>              The value column in the input chr file (0-based, default: 5).
