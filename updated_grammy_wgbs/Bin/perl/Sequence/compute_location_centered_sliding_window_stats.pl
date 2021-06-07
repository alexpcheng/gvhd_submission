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

#---------------------------------------------------------------------#
# LOAD ARGUMENTS                                                      #
#---------------------------------------------------------------------#
my %args = load_args(\@ARGV);

#---------------------------#
# Features (locations) file #
#---------------------------#
my $features_file_ref;
my $features_file = $ARGV[0];
if (length($features_file) < 1 or $features_file =~ /^-/) 
{
  $features_file_ref = \*STDIN;
}
else
{
  open(FEATURES_FILE, $features_file) or die("Could not open the features/locations file '$features_file'.\n");
  $features_file_ref = \*FEATURES_FILE;
}

#--------------------------#
# Statistics file          #
#--------------------------#
my $stats_file = get_arg("f", "", \%args);
my $stats_file_ref;
if (length($stats_file) == 0)
{
  die "Statistics file not given.\n";
}
open(STATS_FILE, $stats_file) or die("Could not open statistics file '$stats_file'.\n");
$stats_file_ref = \*STATS_FILE;
my $stats_column = get_arg("c", "4", \%args);

#--------------------------#
# Other parameters         #
#--------------------------#
my $sliding_window_resolution = get_arg("sw_res", 1 , \%args);
my $sliding_window_half_size = get_arg("sw_size", 0 , \%args);
my $numeric_sort = get_arg("numeric", 0 ,\%args); 
my $add_upstream = get_arg("add_upstream", 0 , \%args);
my $add_downstream = get_arg("add_downstream", 0 , \%args);
my $min_window_stat_weight = get_arg("min_wsw", "NULL" , \%args);
my $min_window_value = get_arg("min_wval", "NULL" , \%args);
my $coordinate_format = get_arg("coord", "rel", \%args);
my $output_format = get_arg("of", "chv", \%args);
my $orientation = get_arg("o", "0", \%args);
my $weight_mode = get_arg("weight_mode", "intersection", \%args); 
my $function = get_arg("func", "lin", \%args);
my $function_power = get_arg("pow", "", \%args);
my $function_relative_point_by_percent = get_arg("func_rel", 0.5, \%args);
my $function_distance_of_effective_rel_point_from_rel_point = get_arg("func_rel_dist", 0, \%args);
my $empty_value = get_arg("e", "", \%args);

$function_relative_point_by_percent = 
  ($function_relative_point_by_percent eq "c") ? 0.5 : 
  ($function_relative_point_by_percent eq "s") ? 0 : 
  ($function_relative_point_by_percent eq "e") ? 1 : 
  $function_relative_point_by_percent;

($function eq "lin") or ($function eq "sq") or ($function eq "sqrt") or
($function eq "delta") or ($function eq "delta_weighted_ave3") or (length($function_power) > 0)
or die("Unknown function (-func), expect: lin/sq/sqrt/delat/weighted_ave3, found: $function.\n");

if (length($function_power) > 0)
{
  $function = "pow";
}

($weight_mode eq "intersection") or ($weight_mode eq "intersection_rel") or ($weight_mode eq "relative2stats") or ($weight_mode eq "max") or ($weight_mode eq "sum") or die("Unknown weight mode (-weight_mode), expect: intersection/relative2stats, found: $weight_mode.\n");

($output_format eq "chv") or ($output_format eq "tab")
or die("Unknown output format (-of), expect: chv/tab, found: $output_format.\n");

($coordinate_format eq "gen") and ($output_format eq "tab")
and die("Cannot use tab output format (-of tab) with genomic coordinates (-coord gen).\nEither change to a chv format (-of chv) or to one of the relative coordinates (-coord rel/relp).\n");

($coordinate_format eq "gen") or ($coordinate_format eq "rel") or ($coordinate_format eq "relp") 
or die("Unknown coordinates format (-coord), expect: gen/rel/relp, found: $coordinate_format.\n");

my $DEBUG = 0;

#---------------------------------------------------------------------#
# MAJOR LOOP OVER FEATURES                                            #
#---------------------------------------------------------------------#
my @active_stats_array = ();
my $add_to_each_end = ($add_upstream < $add_downstream) ? $add_downstream : $add_upstream;
$add_to_each_end += $sliding_window_half_size;

my $tmp_stat_str = <$stats_file_ref>;
my $end_of_stats = ($tmp_stat_str);
($end_of_stats) or die("The statistics file is empty.\n");
chomp($tmp_stat_str);

my @tmp_stat = split(/\t/,$tmp_stat_str,-1);

my $tmp_stat_chr = $tmp_stat[0];
my $tmp_stat_min = ($tmp_stat[2] < $tmp_stat[3]) ? $tmp_stat[2] : $tmp_stat[3];
my $tmp_stat_max = ($tmp_stat[2] < $tmp_stat[3]) ? $tmp_stat[3] : $tmp_stat[2];

my $active_stats_array_chr = "";
my $active_stats_array_min_pointer = 0;
my $active_stats_array_max_pointer = 0;

my $feature_item_width = 1; #1 + (2 * $sliding_window_half_size);
my $feature_item_jump = $sliding_window_resolution;

my $is_first_feature = 1;

while(my $feature_str = <$features_file_ref>)
{
  chomp($feature_str);

  if (length($feature_str) > 0)
  {
    my @feature = split(/\t/,$feature_str,-1);
    my $feature_chr = $feature[0];
    my $feature_id = $feature[1];

    my $feature_start = ($feature[2] < $feature[3]) ? ($feature[2] - $add_upstream) : ($feature[2] + $add_upstream);
    my $feature_end = ($feature[2] < $feature[3]) ? ($feature[3] + $add_downstream) : ($feature[3] - $add_downstream);
    my $feature_type = (length($feature[4]) > 0) ? $feature[4] : "LocationCenteredSlidingWindowStats";
    my $feature_min = ($feature_start < $feature_end) ? $feature_start : $feature_end;
    my $feature_max = ($feature_start < $feature_end) ? $feature_end : $feature_start;
    my $feature_pivot = int(($feature[2] + $feature[3]) / 2);
    my $feature_lower_bound_for_hash = ($feature[2] < $feature[3]) ? ($feature[2] - $add_to_each_end) : ($feature[3] - $add_to_each_end);
    my $feature_upper_bound_for_hash = ($feature[2] < $feature[3]) ? ($feature[3] + $add_to_each_end) : ($feature[2] + $add_to_each_end);

    #--------------------------------------------------------------#
    # Advance stats pointer to the current feature's coordinated   #
    #--------------------------------------------------------------#
    while ($end_of_stats and (($numeric_sort
			       and
			       (($active_stats_array_chr < $feature_chr)
				or
				(($active_stats_array_chr eq $feature_chr)
				 and
				 ($active_stats_array_max_pointer < $feature_lower_bound_for_hash))))
			      or
			      (!$numeric_sort
			       and
			       (($active_stats_array_chr lt $feature_chr)
				or
				(($active_stats_array_chr eq $feature_chr)
				 and
				 ($active_stats_array_max_pointer < $feature_lower_bound_for_hash))))))
    {
       @active_stats_array = ();
       push(@active_stats_array, $tmp_stat_str);

       $active_stats_array_chr = $tmp_stat_chr;
       $active_stats_array_min_pointer = $tmp_stat_min;
       $active_stats_array_max_pointer = $tmp_stat_max;

       $tmp_stat_str = <$stats_file_ref>;
       $end_of_stats = ($tmp_stat_str);
       if ($end_of_stats)
       {
	  chomp($tmp_stat_str);

	  @tmp_stat = split(/\t/,$tmp_stat_str,-1);
	  $tmp_stat_chr = $tmp_stat[0];
	  $tmp_stat_min = ($tmp_stat[2] < $tmp_stat[3]) ? $tmp_stat[2] : $tmp_stat[3];
	  $tmp_stat_max = ($tmp_stat[2] < $tmp_stat[3]) ? $tmp_stat[3] : $tmp_stat[2];
       }
    }

    #---------------------------------------------------------------#
    # Traverse the active stats array and remove non relevant stats #
    #---------------------------------------------------------------#
    my @tmp_new_active_stats_array = ();

    for (my $i = 0; $i < @active_stats_array; $i++)
    {
       my $tmp_new_stat_str = $active_stats_array[$i];
       my @tmp_new_stat = split(/\t/, $tmp_new_stat_str,-1);
       my $tmp_new_stat_chr = $tmp_new_stat[0];
       my $tmp_new_stat_min = ($tmp_new_stat[2] < $tmp_new_stat[3]) ? $tmp_new_stat[2] : $tmp_new_stat[3];
       my $tmp_new_stat_max = ($tmp_new_stat[2] < $tmp_new_stat[3]) ? $tmp_new_stat[3] : $tmp_new_stat[2];

       if ((!$numeric_sort and ($tmp_new_stat_chr gt $feature_chr || ($tmp_new_stat_chr eq $feature_chr && $tmp_new_stat_max >= $feature_min)))
	   or
	   ($numeric_sort and ($tmp_new_stat_chr > $feature_chr || ($tmp_new_stat_chr eq $feature_chr && $tmp_new_stat_max >= $feature_min))))
       {
	  push(@tmp_new_active_stats_array, $tmp_new_stat_str);
       }
    }
    @active_stats_array = @tmp_new_active_stats_array;

    #--------------------------------------------------------------#
    # Add additional stats to the active stats array, as needed    #
    #--------------------------------------------------------------#
    while ($end_of_stats and (($tmp_stat_chr eq $feature_chr)
			      and
			      ($tmp_stat_min <= $feature_upper_bound_for_hash)))
    {
       push(@active_stats_array, $tmp_stat_str);

       $active_stats_array_chr = $tmp_stat_chr;
       $active_stats_array_max_pointer = ($active_stats_array_max_pointer < $tmp_stat_max) ? $tmp_stat_max : $active_stats_array_max_pointer;

       $tmp_stat_str = <$stats_file_ref>;
       $end_of_stats = ($tmp_stat_str);
       if ($end_of_stats)
       {
	  chomp($tmp_stat_str);

	  @tmp_stat = split(/\t/,$tmp_stat_str,-1);
	  $tmp_stat_chr = $tmp_stat[0];
	  $tmp_stat_min = ($tmp_stat[2] < $tmp_stat[3]) ? $tmp_stat[2] : $tmp_stat[3];
	  $tmp_stat_max = ($tmp_stat[2] < $tmp_stat[3]) ? $tmp_stat[3] : $tmp_stat[2];
       }
    }

    #----------------------------------------------------#
    # Compute sliding window statistics for the feature  #
    #----------------------------------------------------#
    my @feature_centers_of_windows = ();
    my @feature_centers_of_windows_sorted = ();
    push(@feature_centers_of_windows, $feature_pivot);
    for (my $i = $feature_pivot + $sliding_window_resolution; $i <= $feature_max; $i += $sliding_window_resolution)
    {
       push(@feature_centers_of_windows, $i);
    }
    for (my $i = $feature_pivot - $sliding_window_resolution; $i >= $feature_min; $i -= $sliding_window_resolution)
    {
       push(@feature_centers_of_windows, $i);
    }
    if ($feature_start < $feature_end)
    {
       @feature_centers_of_windows_sorted = sort {$a <=> $b} @feature_centers_of_windows;
    }
    else
    {
       @feature_centers_of_windows_sorted = sort {$b <=> $a} @feature_centers_of_windows;
    }

    if ($output_format eq "chv")
    {
       my $feature_gen_start = $feature_centers_of_windows_sorted[0];
       my $feature_gen_end = $feature_centers_of_windows_sorted[@feature_centers_of_windows_sorted - 1];

       my $feature_start_to_print = 
       ($coordinate_format eq "gen") ? $feature_gen_start : 
       ($coordinate_format eq "rel") ? 0 : 
       ($coordinate_format eq "relp") ? -1*abs($feature_gen_start - $feature_pivot) : "";

       my $feature_end_to_print = 
       ($coordinate_format eq "gen") ? $feature_gen_end : 
       ($coordinate_format eq "rel") ? abs($feature_gen_end - $feature_gen_start) : 
       ($coordinate_format eq "relp") ? abs($feature_gen_end - $feature_pivot) : "";

       my $feature_chr_to_print = 
       ($coordinate_format eq "gen") ? $feature_chr : 
       ($coordinate_format eq "rel") ? "Relative" : 
       ($coordinate_format eq "relp") ? "RelativePivot" : "";

       print STDOUT "$feature_chr_to_print\t$feature_id\t$feature_start_to_print\t$feature_end_to_print\t";
       print STDOUT "$feature_type\t$feature_item_width\t$feature_item_jump\t";
    }
    elsif ($output_format eq "tab")
    {
       if ($is_first_feature == 1)
       {
	  my $is_before_pivot = 1;
	  for (my $i = 0; $i < @feature_centers_of_windows_sorted; $i++)
	  {
	     $is_before_pivot = ($feature_centers_of_windows_sorted[$i] == $feature_pivot) ? 0 : $is_before_pivot;

	     my $location = 
	     ($coordinate_format eq "rel") ? ($i * $sliding_window_resolution) :
	     (($coordinate_format eq "relp") and ($is_before_pivot == 1)) ?
	     -1*abs($feature_centers_of_windows_sorted[$i] - $feature_pivot) :
	     (($coordinate_format eq "relp") and ($is_before_pivot == 0)) ?
	     abs($feature_centers_of_windows_sorted[$i] - $feature_pivot) : "";

	     print STDOUT "\t$location";
	  }
	  print STDOUT "\n";
       }
       print STDOUT "$feature_id\t";
    }
    else
    {
       die("Error: unknown output format: $output_format.\n");
    }

    for (my $i = 0; $i < @feature_centers_of_windows_sorted; $i++)
    {
       my $window_center_location = $feature_centers_of_windows_sorted[$i];
       my $window_center_raw_value = ($weight_mode eq "max") ? -1000000000 : 0;
       my $window_center_weight = 0;

       for (my $j = 0; $j < @active_stats_array; $j++)
       {
	  my $tmp_new_stat_str = $active_stats_array[$j];
	  my @tmp_new_stat = split(/\t/, $tmp_new_stat_str,-1);
	  my $tmp_new_stat_chr = $tmp_new_stat[0];
	  my $tmp_new_stat_min = ($tmp_new_stat[2] < $tmp_new_stat[3]) ? $tmp_new_stat[2] : $tmp_new_stat[3];
	  my $tmp_new_stat_max = ($tmp_new_stat[2] < $tmp_new_stat[3]) ? $tmp_new_stat[3] : $tmp_new_stat[2];

	  my $intersection = &Intersection($tmp_new_stat_min, $tmp_new_stat_max, $window_center_location - $sliding_window_half_size, $window_center_location + $sliding_window_half_size);

	  if ($intersection > 0)
	  {
	    if(!$orientation or ($tmp_new_stat[2]>=$tmp_new_stat[3] and $feature[2]>=$feature[3]) or ($tmp_new_stat[3]>=$tmp_new_stat[2] and $feature[3]>=$feature[2])){
	      my $tmp_new_stat_value = $tmp_new_stat[$stats_column];

	      if ($weight_mode eq "intersection")
	      {
		 $window_center_raw_value += ($tmp_new_stat_value * $intersection);
		 $window_center_weight += $intersection;
	      }
	      elsif ($weight_mode eq "intersection_rel")
	      {
		 my $weight = &IntersectionRel2LocationCenter($tmp_new_stat_min, $tmp_new_stat_max, $window_center_location - $sliding_window_half_size, $window_center_location + $sliding_window_half_size);
		 $window_center_raw_value += ($tmp_new_stat_value * $weight);
		 $window_center_weight += $weight;
	      }
	      elsif ($weight_mode eq "relative2stats")
		{
		  my $weight = &WeightByRelativePositionDecreasedFromRelPosition($tmp_new_stat_min, $tmp_new_stat_max, $window_center_location - $sliding_window_half_size, $window_center_location + $sliding_window_half_size);
		  
		  $window_center_raw_value += ($tmp_new_stat_value * $weight);
		  $window_center_weight += $weight;
		}
	      elsif ($weight_mode eq "max")
		{
		  $window_center_raw_value = ($window_center_raw_value < $tmp_new_stat_value) ? $tmp_new_stat_value : $window_center_raw_value;
		  $window_center_weight = 1;
		}
	      elsif ($weight_mode eq "sum")
		{
		  $window_center_raw_value += $tmp_new_stat_value;
		  $window_center_weight = 1;
		}
	      else
		{
		  die("Error: undefined statistics for computing the weighted window average.\n");
		}
	    }
	  }
       }

       my $window_center_final_value = ($window_center_weight == 0) ? "" : ($window_center_raw_value / $window_center_weight);
       $window_center_final_value = (($min_window_stat_weight ne "NULL") and ($window_center_weight <= $min_window_stat_weight)) ? "" : $window_center_final_value;

       $window_center_final_value = (($min_window_value ne "NULL") and ($window_center_final_value <= $min_window_value)) ? "" : $window_center_final_value;

       $window_center_final_value = (length($window_center_final_value) > 0) ? $window_center_final_value : $empty_value;

       if ($output_format eq "chv")
       {
	  print STDOUT "$window_center_final_value";
	  print STDOUT ($i == (@feature_centers_of_windows_sorted -1)) ? "\n" : ";";
       }
       elsif ($output_format eq "tab")
       {
	  print STDOUT "$window_center_final_value";
	  print STDOUT ($i == (@feature_centers_of_windows_sorted -1)) ? "\n" : "\t";
       }
       else
       {
	  die("Error: unknown output format: $output_format.\n");
       }
    }
    $is_first_feature = 0;
  }
}

#--------------------------#
# SUBROUTINES              #
#--------------------------#

#-------------------------------------------------------------------------------------#
# $intersection_weight IntersectionRel2LocationCenter($min_a, $max_a, $min_b, $max_b) #
#-------------------------------------------------------------------------------------#
sub IntersectionRel2LocationCenter
{
  my $min_a = $_[0];
  my $max_a = $_[1];
  my $min_b = $_[2];
  my $max_b = $_[3];

  my $min_of_max_ab = ($max_a < $max_b) ? $max_a : $max_b;
  my $max_of_min_ab = ($min_a < $min_b) ? $min_b : $min_a;

  my $res = $min_of_max_ab - $max_of_min_ab + 1;
  $res = ($res < 0) ? 0 : $res;

  if ($res > 0)
  {
     my $bcenter = ($max_b + $min_b) / 2;
     my $half_window_length = ($max_b - $min_b + 1) / 2;
     $res = 0;
     for (my $i=$max_of_min_ab; $i <= $min_of_max_ab; $i++)
     {
	$res += ($half_window_length+1 - abs($i - $bcenter) );
     }
     my $res_norm = 0; ## The computation of the normalization should be computed in a closed form without the enumeration (to speed up), but it iss past midnight and I am way too tired... ;-) Yair
     for (my $i=$min_b; $i <= $max_b; $i++)
     {
	$res_norm += ($half_window_length+1 - abs($i - $bcenter) );
     }
     $res = $res / $res_norm;
  }

  return $res;
}

#-------------------------------------------------------------------#
# $intersection_length Intersection($min_a, $max_a, $min_b, $max_b) #
#-------------------------------------------------------------------#
sub Intersection
{
  my $min_a = $_[0];
  my $max_a = $_[1];
  my $min_b = $_[2];
  my $max_b = $_[3];

  my $min_of_max_ab = ($max_a < $max_b) ? $max_a : $max_b;
  my $max_of_min_ab = ($min_a < $min_b) ? $min_b : $min_a;

  my $res = $min_of_max_ab - $max_of_min_ab + 1;

  $res = ($res < 0) ? 0 : $res;
  return $res;
}

#-------------------------------------------------------------------#
# $weight = WeightByRelativePositionDecreasedFromRelPosition        #
#           ($min_stat, $max_stat, $min_window, $max_window)        #
#-------------------------------------------------------------------#
sub WeightByRelativePositionDecreasedFromRelPosition
{
  my $min_stat = $_[0];
  my $max_stat = $_[1];
  my $min_window = $_[2];
  my $max_window = $_[3];

  my $min_of_max_ab = ($max_stat < $max_window) ? $max_stat : $max_window;
  my $max_of_min_ab = ($min_stat < $min_window) ? $min_window : $min_stat;

  my $res = $min_of_max_ab - $max_of_min_ab + 1;

  if ($res > 0)
  {
    $res = 0;
    for (my $i = $max_of_min_ab; $i <= $min_of_max_ab; $i++)
    {
      my $distance_from_stat_end1 = abs($i - $min_stat) + 1;
      my $length_of_stat = abs($max_stat - $min_stat) + 1;

      $res += &WeightByRelativePositionDecreasedFromRelPositionOne($distance_from_stat_end1,$length_of_stat);
    }
  }

  $res = ($res < 0) ? 0 : $res;

  return $res;
}

#---------------------------------------------------------------------------------#
# $weight = WeightByRelativePositionDecreasedFromRelPositionOne                   #
#           ($distance_from_stat_end1,$length_of_stat)                            #
#---------------------------------------------------------------------------------#
sub WeightByRelativePositionDecreasedFromRelPositionOne
{
  my $my_distance_from_stat_end1 = $_[0];
  my $my_length_of_stat = $_[1];

  my $tmp_center = ($function_relative_point_by_percent * $my_length_of_stat);

  $tmp_center += $function_distance_of_effective_rel_point_from_rel_point;

  if ($tmp_center < 1)
  {
    $tmp_center = 1; 
  }
  elsif ($tmp_center > $my_length_of_stat)
  {
    $tmp_center = $my_length_of_stat;
  }

  my $normalizing_factor = 0;
  my $unnormalized_res = 0;

  my $increament = (floor($tmp_center - 1) > 0) ? ($tmp_center - 1) / floor($tmp_center - 1) : 0;
  my $lin_val = 1 - $increament;
  my $true_val;

  if ($function eq "delta")
  {
    $normalizing_factor = 1;
    $unnormalized_res = (($my_distance_from_stat_end1 >= $tmp_center) 
			 and 
			 ($my_distance_from_stat_end1 < $tmp_center + 1)) ? 1 : 0;
  }
  elsif ($function eq "delta_weighted_ave3")
  {
    $normalizing_factor = 1;
    $unnormalized_res = (($my_distance_from_stat_end1 >= $tmp_center) 
			 and 
			 ($my_distance_from_stat_end1 < $tmp_center + 1)) ? 1 :
			   (($my_distance_from_stat_end1 >= $tmp_center + 1) 
			    and 
			    ($my_distance_from_stat_end1 < $tmp_center + 2)) ? 0.5 :
			      (($my_distance_from_stat_end1 >= $tmp_center - 1) 
			       and 
			       ($my_distance_from_stat_end1 < $tmp_center)) ? 0.5 : 0;
  }
  else
  {
    for (my $i = 1; $i <= $tmp_center; $i++)
    {
      $lin_val = $lin_val + $increament;

      $true_val = 
	($function eq "lin") ? $lin_val :
	  ($function eq "sq") ? ($lin_val * $lin_val) :
	    ($function eq "sqrt") ? sqrt($lin_val) : 
	      ($function eq "pow") ? $lin_val ** $function_power : 
		die("Error: undefined function: '$function'.\n");

      $normalizing_factor += $true_val;

      if ($i == $my_distance_from_stat_end1)
      {
	$unnormalized_res = $true_val;
      }
    }

    $increament = floor($my_length_of_stat - $tmp_center) ? ($tmp_center - 1) / floor($my_length_of_stat - $tmp_center) : 0;

    for (my $i = floor($tmp_center) + 1; $i <= $my_length_of_stat; $i++)
    {
      $lin_val -= $increament;
      $lin_val = ($lin_val > 0) ? $lin_val : 0;

      $true_val = 
	($function eq "lin") ? $lin_val :
	  ($function eq "sq") ? ($lin_val * $lin_val) :
	    ($function eq "sqrt") ? sqrt($lin_val) : 
	      ($function eq "pow") ? $lin_val ** $function_power : 
		die("Error: undefined function: '$function'.\n");

      $normalizing_factor += $true_val;

      if ($i == $my_distance_from_stat_end1)
      {
	$unnormalized_res = $true_val;
      }
    }
  }

  my $res = ($normalizing_factor > 0) ? ($unnormalized_res / $normalizing_factor) : 0;
  return $res;
}

#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         compute_location_centered_sliding_window.pl <file.chr>
 
 Description:    Given a chr file of features and an extended chr file of statistics, computes sliding window 
                 statistics (specify the statistic column, window size, sliding resolution) for each 
                 feature's surrounding (specify upstream/downstream surrounding), and outputs them 
                 in a chv/tab format (specify format and genomic vs feature-relative coordinates). 
                 Can specify a filter of minimum "statistical weight" for windows.

                 Statistical weight := total intersection of statistics with the window, in bp.

 Output:         chv/tab file format.

 IMPORTANT!!!    It is assumed that the features file (<file.chr>) is sorted by chromosome 
                 (lexicographic order), then by start coordinate (minimum of 3rd-n-4th chr coulmns,
                 numerical order). The statistics file (-f <file.chr>) is assumed to be sorted too 
                 in the same order.
                 The statistics file is assumed to have unique entries by chromosome and start!!!
                 Remark: works ok even if the features file is sorted before adding the surroundings.

 Flags:

   -f <file.chr>              The statistics (chr) file.

   -c <int>                   The column of the statistics. (0-based, default: 4)

   -sw_res <int>              The sliding (widnow) resolution. (default: 1 bp)

   -sw_size <int>             The (sliding) window HALF size. (default: 0 bp)

   -add_upstream <int>        Add <int> bp upstream to the feature's start. (default = 0)

   -add_downstream <int>      Add <int> bp downstream to the feature's end. (default = 0)

   -min_wsw <double>          For windows with "statistical weight" <= <double> report empty value.
                              (default: report all window values that have at least one statistic).

   -min_wval <double>         For windows with values <= <double> report empty value.
                              (default: report all values, no cutoff).

   -e <str>                   Defines the "empty value" (default: "").

   -weight_mode <mode>:
                              The way to assign a weight for a statistics, where <mode> is either: 

                               intersection:     the length of intersection of the stats and the window (default).
                               intersection_rel: the relative area of the intersection under a triangle centered over the window
                                                 (1 for the center, 0 outside the window)
                               relative2stats:   by a function on the distance of the intersection relative 
                                                 to the stats length (defined by -func).
                               max:              take the max stats that intersect with window.
                               sum:              take the sum over stats that intersect with window (no weighting).

   -func <function>           The function that gives a weight for a location relative to the stats,
                              which is defined on the distance of the location to the stats' relative point 
                              ('-func_rel') and on the stats' length. <func> is either:

                               lin:   linear (default)
                               sq:    square
                               sqrt:  square root
                               delta: a delta function that is 1 if the intersection is with the 'effective relative point'
                                      (see '-func_rel' and '-func_rel_dist'), and 0 otherwise.
                               delta_weighted_ave3: as the delta function, but giving half the weight to 
                                                    adjucent (1bp) locations. (E.g. if the stats' val is v 
                                                    and the delta specifies location x, then if the intersection
                                                    is at x, the val is v, and at (x-1) or (x+1) the val is v/2)
                               *** you can specify any power function using the '-pow' flag ***

   -pow <num>                 Specify a <num> power function instead of the '-func' flag 
                              (default = "", i.e. define a function according to '-func')

   -func_rel <percent>        The relative point for the function ('-func'), i.e. the function's peak,
                              that is defined by the distance from the start of the statistic by the
                              percent from the length of the statistics.
                              E.g., the start is 0, the center is 0.5, and the end is 1 (default = 0.5)

   -func_rel_dist <int>       The effective relative point for the function ('-func') is offseted by <int>
                              relative to the statistic's start (default: 0).

                              E.g., '-func lin -func_rel c -func_rel_dist 2' specify a function peaked 2 bp
                              from the center of the statistics torwards its end, and that decreases linearly
                              in both directions.

   -coord <gen/rel/relp>      The feature's coordinates: (default: rel)
                              gen:  genome.
                              rel:  relative to the feature's actual start, including the add_upstream.
                              relp: relaive to the feature's pivot (center between original feature's start and end).

   -of <chv/tab>              The output format:
                              chv:  standard chv format, i.e. 
                                    <chr><\t><id><\t><start><\t><end><\t><type><\t><width><\t><jump><\t><val1;val2;...>
                              tab:  a matrix features x locations, with both headers. 
                                    works only with rel/relp coordinates!!!

   -numeric                   Assume numeric sort instead of lexicographic.
   -o                         for each feature, count only statistics that have the same orientation.


