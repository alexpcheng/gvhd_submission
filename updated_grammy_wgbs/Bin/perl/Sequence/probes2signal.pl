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
# LOAD ARGUMENTS: "locations_file" is the chr probes-file             #
#---------------------------------------------------------------------#
my %args = load_args(\@ARGV);

my $locations_file = $ARGV[0];
my $locations_file_ref;

if (length($locations_file) < 1 or $locations_file =~ /^-/) 
{
  $locations_file_ref = \*STDIN;
}
else
{
  open(LOCATIONS_FILE, $locations_file) or die("Could not open the locations file '$locations_file'.\n");
  $locations_file_ref = \*LOCATIONS_FILE;
}

#---------------------------------------------------------------------#
# The "containing_locations_file" specifies boundries within to       #
# calc/output the signal. If not given, we work on entire data,       #
# for each chromosome from its lowest to highest location.            #
# for doing so we traverse the "locations_file" (=probes file)        #
# and extract this info.                                              #
#---------------------------------------------------------------------#
my $containing_locations_file = get_arg("f", "", \%args);
my $rand = int(rand(1000000));

if (length($containing_locations_file) > 0)
{
  open(CONTAINING_LOCATIONS_FILE, $containing_locations_file) 
    or die("Could not open the containing locations file '$containing_locations_file'.\n");
}
else
{
  my $tmp_file_name;
  if (length($locations_file) < 1 or $locations_file =~ /^-/) 
  {
    my $TMP1 = \*STDIN;
    open(TMP2, ">tmp2_probes2signal_$rand") or die("Could not open the file 'tmp2_probes2signal_$rand' for writing.\n");
    while (my $l = <$TMP1>) { chomp($l); print TMP2 "$l\n"; }
    close(TMP2);
    open(TMP2, "tmp2_probes2signal_$rand") or die("Could not open the file 'tmp2_probes2signal_$rand' for reading.\n");
    $locations_file_ref = \*TMP2;
    $tmp_file_name = "tmp2_probes2signal_$rand";
  }
  else
  {
    $tmp_file_name = $locations_file;
  }

  my $str1 = `cat $tmp_file_name | add_column.pl -b -max 2,3 | cut.pl -f 2,1 > tmp1_probes2signal_$rand`;
  my $str2 = `cat $tmp_file_name | add_column.pl -b -min 2,3 | cut.pl -f 2,1 >> tmp1_probes2signal_$rand`;
  my $str3 = `cat tmp1_probes2signal_$rand | list2neighborhood.pl | transpose.pl -q | compute_column_stats.pl -skipc 0 skip 1 -max -min | transpose.pl -q | body.pl 2 -1 | lin.pl | cut.pl -f 2,1,4,3 | sort.pl -c0 0 -c1 2,3 -op1 min -n1 > tmp_probes2signal_$rand`;

  open(CONTAINING_LOCATIONS_FILE, "tmp_probes2signal_$rand")
    or die("Could not open the containing locations file 'tmp_probes2signal_$rand'.\n");
}

my $containing_locations_file_ref = \*CONTAINING_LOCATIONS_FILE;

#---------------------------------------------------------------------#
# LOAD ARGUMENTS: the rest                                            #
#---------------------------------------------------------------------#
my $probe_max_length = get_arg("pml", 80, \%args);
my $window_size = $probe_max_length * 2;
my $sliding_resolution = get_arg("sr", 1, \%args);
my $value_column = get_arg("vc", 4, \%args);
my $chv_object_type = get_arg("tn", "Type", \%args);
my $verbose = ! get_arg("q", 0, \%args);
my $precision = get_arg("p", 3, \%args);

my $weight_mode = get_arg("weight_mode", "relative2probe", \%args); 
my $function = get_arg("func", "lin", \%args);
my $function_power = get_arg("pow", "", \%args);
my $function_relative_point_by_percent = get_arg("func_rel", 0.5, \%args);
my $function_distance_of_effective_rel_point_from_rel_point = get_arg("func_rel_dist", 0, \%args);

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

($weight_mode eq "ave") or ($weight_mode eq "relative2probe") or ($weight_mode eq "max")
or die("Unknown weight mode (-weight_mode), expect: relative2probe/ave/max, found: $weight_mode.\n");

my @locations_queue = ();
my @window_locations_queue = ();

my $window_chr;
my $window_start;
my $window_end;
my $chv_object_chr = "";
my $chv_object_id = 1;
my $chv_object_signal = "";
my $chv_object_start = "";
my $chv_object_end = "";
my $chv_object_width = 1;
my $chv_object_jump = $sliding_resolution;
my $containing_locations_item; 

#---------------------------------------------------------------------#
# Major loop over "containing locations"                              #
#---------------------------------------------------------------------#
while($containing_locations_item = <$containing_locations_file_ref>)
{
  chomp($containing_locations_item);
  my @containing_location_array = split(/\t/,$containing_locations_item); 
  my $containing_location_chr = $containing_location_array[0];
  my $containing_location_id = $containing_location_array[1]; 
  my $containing_location_start = 
    ($containing_location_array[2] <= $containing_location_array[3]) ? $containing_location_array[2] : 
	$containing_location_array[3]; 
  my $containing_location_end = 
    ($containing_location_array[2] <= $containing_location_array[3]) ? 
      $containing_location_array[3] : 
	$containing_location_array[2]; 
  $window_chr = $containing_location_chr;
  $chv_object_chr = $containing_location_chr;

  #---------------------------------------------------------------------#
  # Traversing the "containing location" at the sliding resolution      #
  #---------------------------------------------------------------------#
  for (my $i = $containing_location_start;
       $i <= $containing_location_end;
       $i += $sliding_resolution)
  {
    $window_start = $i - $probe_max_length;
    $window_end = $window_start + $window_size;

    #---------------------------------------------------------------------#
    # Fill in "@window_locations_queue" with all intersecting probes      #
    #---------------------------------------------------------------------#
    my $window_count = &FindWindowLocations();

    #---------------------------------------------------------------------#
    # Calculate the signal at location $i                                 #
    #---------------------------------------------------------------------#
    my $signal = &CalcSignal($i);


    #---------------------------------------------------------------------#
    # Output mode is CHV,                                                 #
    # thus we concatanate consecutive results before printing them        #
    #---------------------------------------------------------------------#
    if (length($signal) > 0)
    {
      if (length($chv_object_start) > 0)
      {
	$chv_object_end = $i;
	$chv_object_signal = $chv_object_signal . ";" . "$signal";
      }
      else
      {
	$chv_object_start = $i;
	$chv_object_end = $i;
	$chv_object_signal = "$signal";
      }

      if ($i + $sliding_resolution > $containing_location_end)
      {
	# CHV format

	print STDOUT "$chv_object_chr\t$chv_object_id\t$chv_object_start\t$chv_object_end\t";
	print STDOUT "$chv_object_type\t$chv_object_width\t$chv_object_jump\t$chv_object_signal\n";

	$chv_object_id++;
	$chv_object_signal = "";
	$chv_object_start = "";
	$chv_object_end = "";
      }
    }
    elsif (length($chv_object_start) > 0)
    {
      # CHV format

      print STDOUT "$chv_object_chr\t$chv_object_id\t$chv_object_start\t$chv_object_end\t";
      print STDOUT "$chv_object_type\t$chv_object_width\t$chv_object_jump\t$chv_object_signal\n";

      $chv_object_id++;
      $chv_object_signal = "";
      $chv_object_start = "";
      $chv_object_end = "";
    }
  }
}

system "rm -f tmp_probes2signal_$rand tmp1_probes2signal_$rand tmp2_probes2signal_$rand";

#--------------------------#
# SUBROUTINES              #
#--------------------------#

#--------------------------------------------------------------------------------------------------------
# $signal = &CalcSignal($i);
#--------------------------------------------------------------------------------------------------------
sub CalcSignal
{
  my $window_center_location = $_[0];
  my $window_center_raw_value = 0;
  my $window_center_weight = 0;

  for (my $j = 0; $j < @window_locations_queue; $j++)
  {
    my $tmp_new_stat_str = $window_locations_queue[$j];
    my @tmp_new_stat = split(/\t/, $tmp_new_stat_str);
    my $tmp_new_stat_chr = $tmp_new_stat[0];
    my $tmp_new_stat_min = ($tmp_new_stat[2] < $tmp_new_stat[3]) ? $tmp_new_stat[2] : $tmp_new_stat[3];
    my $tmp_new_stat_max = ($tmp_new_stat[2] < $tmp_new_stat[3]) ? $tmp_new_stat[3] : $tmp_new_stat[2];

    my $intersection = &Intersection($tmp_new_stat_min, $tmp_new_stat_max, $window_center_location, $window_center_location);

    if ($intersection > 0)
    {
      my $tmp_new_stat_value = $tmp_new_stat[$value_column];

      if ($weight_mode eq "ave")
      {
	$window_center_raw_value += ($tmp_new_stat_value * $intersection);
	$window_center_weight += $intersection;
      }
      elsif ($weight_mode eq "relative2probe")
      {
	my $weight = &WeightByRelativePositionDecreasedFromRelPosition($tmp_new_stat_min, $tmp_new_stat_max, $window_center_location, $window_center_location);
	
	$window_center_raw_value += ($tmp_new_stat_value * $weight);
	$window_center_weight += $weight;   
      }
      elsif ($weight_mode eq "max")
      {
	$window_center_raw_value = ($window_center_raw_value < $tmp_new_stat_value) ? 
	  $tmp_new_stat_value : 
	    $window_center_raw_value;
	$window_center_weight = 1;
      }
      else
      {
	die("Error: undefined method for computing the signal.\n");
      }
    }
  }

  my $window_center_final_value = 
    ($window_center_weight == 0) ? 
      "" : 
	($window_center_raw_value / $window_center_weight);

  return &format_number($window_center_final_value, $precision);
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

#--------------------------------------------------------------------------------------------------------
# $size_of_window_locations_queue = &FindWindowLocations();
#--------------------------------------------------------------------------------------------------------
sub FindWindowLocations
{
  my $line1;
  my @line1_array;
  my $line1_chr;
  my $line1_start;
  my $line1_end;
  
  my $i=0;
  while ($i < @window_locations_queue)
  {
    $line1 = $window_locations_queue[$i];
    @line1_array = split(/\t/,$line1);
    $line1_chr = $line1_array[0];
    $line1_start = ($line1_array[2] <= $line1_array[3]) ? $line1_array[2] : $line1_array[3];
    $line1_end = ($line1_array[2] <= $line1_array[3]) ? $line1_array[3] : $line1_array[2];

    if (($line1_chr lt $window_chr) 
	or 
	(($line1_chr eq $window_chr) 
	 and
	 ($line1_start < $window_start)))
    {
      shift(@window_locations_queue);
    }
    elsif (($line1_chr gt $window_chr) 
	   or 
	   (($line1_chr eq $window_chr)
	    and
	    ($line1_end > $window_end)))
    {
      die("Error (BUG!!!): shouldn't be here. The queue holds elements located after the window");
    }
    else
    {
      $i++;
    }
  }

  my $not_done = (@locations_queue > 0);

  while ($not_done)
  {
    $line1 = $locations_queue[0];
    @line1_array = split(/\t/,$line1);
    $line1_chr = $line1_array[0];
    $line1_start = ($line1_array[2] <= $line1_array[3]) ? $line1_array[2] : $line1_array[3];
    $line1_end = ($line1_array[2] <= $line1_array[3]) ? $line1_array[3] : $line1_array[2];

    if (($line1_chr gt $window_chr) 
	or 
	(($line1_chr eq $window_chr)
	 and
	 ($line1_end > $window_end)))

    {
      $not_done = ! $not_done;
    }
    elsif (($line1_chr eq $window_chr) 
	   and
	   ($line1_end <= $window_end)
	   and
	   ($line1_start >= $window_start))
    {
      push(@window_locations_queue, $line1);
      shift(@locations_queue);
      $not_done = (@locations_queue > 0);
    }
    else
    {
      shift(@locations_queue);
      $not_done = (@locations_queue > 0);
    }
  }

  if (@locations_queue == 0)
  {
    $not_done = 1;

    while ($not_done)
    {
      $line1 = <$locations_file_ref>;
      if (length($line1) > 0)
      {
	chomp($line1);
	@line1_array = split(/\t/,$line1);
	$line1_chr = $line1_array[0];
	$line1_start = ($line1_array[2] <= $line1_array[3]) ? $line1_array[2] : $line1_array[3];
	$line1_end = ($line1_array[2] <= $line1_array[3]) ? $line1_array[3] : $line1_array[2];

	if (($line1_chr gt $window_chr) 
	    or 
	    (($line1_chr eq $window_chr)
	     and
	     ($line1_end > $window_end)))
	{
	  $not_done = ! $not_done;
	  push(@locations_queue, $line1);
	}
	elsif (($line1_chr eq $window_chr) 
	       and
	       ($line1_end <= $window_end)
	       and 
	       ($line1_start >= $window_start))
	{
	  push(@window_locations_queue, $line1);
	}
      }
      else
      {
	$not_done = ! $not_done;	
      }
    }
  }

  my $res = @window_locations_queue;

  return $res;
}

#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         probes2signal.pl <file.chr>
 
 Description:    Transform probes level signal to a single bp signal, according to various strategies.

 Output:         CHV format

 IMPORTANT!!!    It is assumed that the locations file(s) is sorted by chromosome (lexicographic order), 
                 then by minimum of start and end coordinates (numerical order).

 Flags:

   -f <file.chr>:      A containing locations file, which specifies locations to work on.
                       (parts of the area covered by all probes, optional).

   -pml <int>:         An upper bound on a probe's length (default: 80bp).

   -sr <int>:          The sliding resolution (default: 1bp).

   -vc <int>:          The Value column (zero-based, default: 4).

   -tn <int>:          The Type name  (default: "Type").

   -weight_mode <relative2probe/ave/max>: 
                       The way to compute the signal from the intersecting probes: (default: relative2probe)

                        relative2probe:  by a function on the distance of the intersection relative 
                                         to the probe's length (defined by -func).
                        ave:             the average of intersecting probes.
                        max:             the maximum of intersecting probes.

   -func <function>    The function that gives a weight for a location relative to the probe,
                       which is defined on the distance of the location to the probe's "relative point" ('-func_rel')
                       and on the probe's length.

                       Functions available: (default: sq)

                        lin:                 linear
                        sq:                  square
                        sqrt:                square root
                        delta:               a delta function that is 1 if the intersection is with 
                                             the 'effective relative point' (see '-func_rel' and 
                                             '-func_rel_dist'), and 0 otherwise.
                        delta_weighted_ave3: as the delta function, but giving half the weight to 
                                             adjucent (1bp) locations. (E.g. if the stats' val is v 
                                             and the delta specifies location x, then if the intersection
                                             is at x, the val is v, and at (x-1) or (x+1) the val is v/2)

                        *** you can specify any power function using the '-pow' flag ***

   -pow <num>                 Specify a <num> power function instead of the '-func' flag 
                              (default = "", i.e. define a function according to '-func')

   -func_rel <percent>  The relative point for the function ('-func'), i.e. the function's peak,
                        that is defined by the distance from the start of the statistic by the
                        percent from the length of the statistics.
                        E.g., the start is 0, the center is 0.5, and the end is 1 (default = 0.5)

   -func_rel_dist <int> The effective relative point for the function ('-func') is offseted by <int> 
                        relative to the statistic's start (default: 0).
   
                        E.g., '-func lin -func_rel c -func_rel_dist 2' specify a function peaked 2 bp 
                        from the center of the statistics torwards its end, and that decreases linearly
                        in both directions.

   -p <int>:            Precision for outputted signal (default: 3).

   -q:                  Quiet mode (default is verbose).

  --help:               Print out this help manual (and exit).
