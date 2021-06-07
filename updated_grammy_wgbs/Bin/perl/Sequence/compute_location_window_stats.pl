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

my $containing_locations_file = get_arg("f", "", \%args);;
open(CONTAINING_LOCATIONS_FILE, $containing_locations_file) or die("Could not open the containing locations file '$containing_locations_file'.\n");
my $containing_locations_file_ref = \*CONTAINING_LOCATIONS_FILE;

my $window_size = get_arg("window", 157, \%args);
my $sliding_resolution = get_arg("sr", 1, \%args);
my $value_column = get_arg("vc", 4, \%args);
my $max_length_to_use_linear_extension_at_window_ends = get_arg("ex", "50", \%args);
my $min_count_to_print_stats = get_arg("mcount", 2, \%args);

my $stats_str = get_arg("stats", "count,mean,std,sym_err", \%args); 
my @stats = split(/\,/,$stats_str);
my $stats_count = 0;
my $stats_mean = 0;
my $stats_std = 0;
my $stats_sym_err = 0;

for (my $i=0; $i < @stats; $i++)
{
  $stats_count = ($stats[$i] eq "count") ? 1 : $stats_count;
  $stats_mean = ($stats[$i] eq "mean") ? 1 : $stats_mean;
  $stats_std = ($stats[$i] eq "std") ? 1 : $stats_std;
  $stats_sym_err = ($stats[$i] eq "sym_err") ? 1 : $stats_sym_err;
}

my $print_window_values_str = get_arg("prnt_w", 0, \%args); 
my $print_window_values_locations = (($print_window_values_str == 1) 
				     or 
				     ($print_window_values_str == 3));
my $print_window_values_extended_locations = (($print_window_values_str == 2) 
					      or 
					      ($print_window_values_str == 3));

my $verbose = ! get_arg("q", 0, \%args);
my $precision = get_arg("p", 3, \%args);

my @locations_queue = ();
my @window_locations_queue = ();
my @extended_window_queue = ();
my $window_previous_location = "";
my $window_next_location = "";
my ($containing_locations_item, $window_chr, $window_start, $window_end);

print STDOUT "Window_chr\tWindow_id\tWindow_start\tWindow_end\tContaining_location_id";

if ($stats_count)
{
  print STDOUT "\tWindow_count";
}
if ($stats_mean)
{
  print STDOUT "\tWindow_mean";
}
if ($stats_std)
{
  print STDOUT "\tWindow_std";
}
if ($stats_sym_err)
{
  print STDOUT "\tWindow_sym_err";
}

if ($print_window_values_locations)
{
  print STDOUT "\tWindow_vals_locations";
}
if ($print_window_values_extended_locations)
{
  print STDOUT "\tWindow_vals_ext_locations";
}

print STDOUT "\n";

while($containing_locations_item = <$containing_locations_file_ref>)
{
  chomp($containing_locations_item);
  my @containing_location_array = split(/\t/,$containing_locations_item); 
  my $containing_location_chr = $containing_location_array[0];
  my $containing_location_id = $containing_location_array[1]; 
  my $containing_location_start = ($containing_location_array[2] <= $containing_location_array[3]) ? $containing_location_array[2] : $containing_location_array[3]; 
  my $containing_location_end = ($containing_location_array[2] <= $containing_location_array[3]) ? $containing_location_array[3] : $containing_location_array[2]; 

  $window_chr = $containing_location_chr;

  for ($window_start = $containing_location_start;
       $window_start + $window_size < $containing_location_end;
       $window_start += $sliding_resolution)
  {
    $window_end = $window_start + $window_size - 1;

    my $window_count = &FindWindowLocations();

    if ($window_count >= $min_count_to_print_stats)
    {
      # compute the "extended window" (extend to a single base resolution by linear extension)

      &ExtendWindowLocations();

      # calc and print all window statistics

      my $window_id = "Window:$window_chr:$window_start:$window_end:$containing_location_id";

      print STDOUT "$window_chr\t$window_id\t$window_start\t$window_end\t$containing_location_id";

      if ($stats_count)
      {
	print STDOUT "\t$window_count";
      }

      my $window_stat_mean;
      my $window_stat_std;

      if ($stats_mean or $stats_std)
      {
	my $window_stat_mean_and_std_str = &CalcWindowStatMeanAndStd();
	my @window_stat_mean_and_std = split(/\t/,$window_stat_mean_and_std_str);
	$window_stat_mean = $window_stat_mean_and_std[0];
	$window_stat_std = $window_stat_mean_and_std[1];
      }
      if ($stats_mean)
      {
	print STDOUT "\t$window_stat_mean";
      }
      if ($stats_std)
      {
	print STDOUT "\t$window_stat_std";
      }
      if ($stats_sym_err)
      {
	my $window_stat_symmetry_error = &CalcWindowStatSymmetryError();

	print STDOUT "\t$window_stat_symmetry_error";
      }

      if ($print_window_values_locations)
      {
	&PrintWindowValuesLocations();
      }
      if ($print_window_values_extended_locations)
      {
	&PrintWindowValuesExtendedLocations();
      }
      print STDOUT "\n";
    }
  }
}

#--------------------------#
# SUBROUTINES              #
#--------------------------#

#--------------------------------------------------------------------------------------------------------
# &PrintWindowValuesLocations();
#--------------------------------------------------------------------------------------------------------
sub PrintWindowValuesLocations
{
  my $line1 = $window_locations_queue[0];
  my @line1_array = split(/\t/,$line1);
  my $line1_value = $line1_array[$value_column];

  print STDOUT "\t$line1_value";

  for (my $i=1; $i < @window_locations_queue; $i++)
  {
    $line1 = $window_locations_queue[$i];
    @line1_array = split(/\t/,$line1);
    $line1_value = $line1_array[$value_column];

    print STDOUT ";$line1_value";
  }
}

#--------------------------------------------------------------------------------------------------------
# &PrintWindowValuesExtendedLocations();
#--------------------------------------------------------------------------------------------------------
sub PrintWindowValuesExtendedLocations
{
  my $line1_value = $extended_window_queue[0];
  print STDOUT "\t$line1_value";

  for (my $i=1; $i < @extended_window_queue; $i++)
  {
    $line1_value = $extended_window_queue[$i];

    print STDOUT ";$line1_value";
  }
}
      
#--------------------------------------------------------------------------------------------------------
# &ExtendWindowLocations();
#--------------------------------------------------------------------------------------------------------
sub ExtendWindowLocations
{
  @extended_window_queue = ();
  my $tmp_value;
  my $line1;
  my @line1_array;
  my $line1_chr;
  my $line1_start;
  my $line1_value;
  my $line2;
  my @line2_array;
  my $line2_chr;
  my $line2_start;
  my $line2_value;
  my $do_linear_extension = 0;
  my $delta_y;
  my $delta_x;
  my $increament;

  if (length($window_previous_location) > 0)
  {
    $line1 = $window_previous_location;
    @line1_array = split(/\t/,$line1);
    $line1_chr = $line1_array[0];
    $line1_start = $line1_array[2];
    $line1_value = $line1_array[$value_column];

    if (($line1_chr eq $window_chr) 
	and 
	(abs($line1_start - $window_start) <= $max_length_to_use_linear_extension_at_window_ends))
    {
      $do_linear_extension = 1;
    }
  }

  $line2 = $window_locations_queue[0];
  @line2_array = split(/\t/,$line2);
  $line2_start = $line2_array[2];
  $line2_value = $line2_array[$value_column];

  if ($do_linear_extension)
  {
    $delta_y = $line2_value - $line1_value;
    $delta_x = $line2_start - $line1_start;

    for (my $k = $window_start; $k < $line2_start; $k++)
    {
      my $l = $k - $line1_start;
      $tmp_value = $line1_value + ($l * $increament);
      push(@extended_window_queue, $tmp_value);
    }
  }
  else
  {
    for (my $k=$window_start; $k < $line2_start; $k++)
    {
      push(@extended_window_queue, $line2_value);    
    }
  }

  for (my $k=0; $k < @window_locations_queue; $k++)
  {
    $line1 = $window_locations_queue[$k];
    @line1_array = split(/\t/,$line1);
    $line1_start = $line1_array[2];
    $line1_value = $line1_array[$value_column];

    push(@extended_window_queue, $line1_value);

    if ($k+1 < @window_locations_queue)
    {
      $line2 = $window_locations_queue[$k+1];
      @line2_array = split(/\t/,$line2);
      $line2_start = $line2_array[2];
      $line2_value = $line2_array[$value_column];
      $delta_y = $line2_value - $line1_value;
      $delta_x = $line2_start - $line1_start;
      $increament = $delta_y / $delta_x;

      for (my $l = 1; $l < $delta_x; $l++)
      {
	$tmp_value = $line1_value + ($l * $increament);
	push(@extended_window_queue, $tmp_value);
      }
    }
  }

  $do_linear_extension = 0;

  if (length($window_next_location) > 0)
  {
    $line2 = $window_next_location;
    @line2_array = split(/\t/,$line2);
    $line2_chr = $line2_array[0];
    $line2_start = $line2_array[2];
    $line2_value = $line2_array[$value_column];

    if (($line2_chr eq $window_chr) 
	and 
	(abs($line2_start - $window_end) <= $max_length_to_use_linear_extension_at_window_ends))
    {
      $do_linear_extension = 1;
    }
  }

  $line1 = $window_locations_queue[@window_locations_queue - 1];
  @line1_array = split(/\t/,$line1);
  $line1_start = $line1_array[2];
  $line1_value = $line1_array[$value_column];

  if ($do_linear_extension)
  {
    $delta_y = $line2_value - $line1_value;
    $delta_x = $line2_start - $line1_start;

    for (my $k = $line1_start + 1; $k <= $window_end; $k++)
    {
      my $l = $k - $line1_start;
      $tmp_value = $line1_value + ($l * $increament);
      push(@extended_window_queue, $tmp_value);
    }
  }
  else
  {
    for (my $k = $line1_start + 1; $k <= $window_end; $k++)
    {
      push(@extended_window_queue, $line1_value);    
    }
  }
}

#--------------------------------------------------------------------------------------------------------
# $window_stat_mean = &CalcWindowStatMean();
#--------------------------------------------------------------------------------------------------------
sub CalcWindowStatMean
{
  my $line1 = $window_locations_queue[0];
  my @line1_array = split(/\t/,$line1);
  my $line1_value = $line1_array[$value_column];
  my $mean = $line1_value;
  my $N = @window_locations_queue;
  my ($sweep,$delta,$i);

  for (my $k=1; $k < $N; $k++)
  {
    $line1 = $window_locations_queue[$k];
    @line1_array = split(/\t/,$line1);
    $line1_value = $line1_array[$value_column];
    $i = $k + 1;
    $sweep = ($i - 1.0) / $i;
    $delta = $line1_value - $mean;
    $mean += $delta / $i;
  }

  return &format_number($mean, $precision);
}

#--------------------------------------------------------------------------------------------------------
# $window_stat_mean:$window_stat_std = &CalcWindowStatMeanAndStd();
#--------------------------------------------------------------------------------------------------------
sub CalcWindowStatMeanAndStd
{
  my $line1 = $window_locations_queue[0];
  my @line1_array = split(/\t/,$line1);
  my $line1_value = $line1_array[$value_column];
  my $mean = $line1_value;
  my $N = @window_locations_queue;
  my $res = &format_number($mean, $precision) . "\t" . "Null";

  if ($N >= 2)
  {
    my ($sweep,$delta,$i);
    my $sum_sq = 0;

    for (my $k=1; $k < $N; $k++)
    {
      $line1 = $window_locations_queue[$k];
      @line1_array = split(/\t/,$line1);
      $line1_value = $line1_array[$value_column];
      $i = $k + 1;
      $sweep = ($i - 1.0) / $i;
      $delta = $line1_value - $mean;
      $sum_sq += $delta * $delta * $sweep;
      $mean += $delta / $i;
    }

    my $std = sqrt( $sum_sq / ($N - 1) );
    $res = &format_number($mean, $precision) . "\t" . &format_number($std, $precision);
  }

  return $res;
}

#--------------------------------------------------------------------------------------------------------
# $window_stat_symmetry_error = &CalcWindowStatSymmetryError();
#--------------------------------------------------------------------------------------------------------
sub CalcWindowStatSymmetryError
{
  my $sum_err = 0;

  for (my $k=0; $k < floor(@extended_window_queue / 2); $k++)
  {
    $sum_err += abs($extended_window_queue[$k] - $extended_window_queue[@extended_window_queue - $k]); 
  }

  my $res = $sum_err / @extended_window_queue;

  return &format_number($res, $precision);
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
      $window_previous_location = $line1;
      shift(@window_locations_queue);
    }
    elsif (($line1_chr gt $window_chr) 
	   or 
	   (($line1_chr eq $window_chr)
	    and
	    ($line1_end > $window_end)))
    {
      die("Error (BUG!!!): whouldn't be here. The queue holds elements located after the window");
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
      $window_next_location = $line1;
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
      $window_previous_location = $line1;
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
	  $window_next_location = $line1;
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
	else
	{
	  $window_previous_location = $line1;
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

 Syntax:         compute_location_window_stats.pl <file.chr>
 
 Description:    Computes the window statistics of all windows of a certain length, including count, 
                 average, std, "symmetry error" (area between the linear extension of the first half
                 window size and the reverse of the other half (after a linear extension of locations 
                 to entier window at a single base resolution. Need to restrict the windows to be 
                 contained with in other locations file, passed as an argument.
                 *** assumes that the locations file is of unique single base locations ***


 Output:         <window_chr><\t><window_number><\t><window_start><\t><window_end><\t><containing_location>
                 <\t><count><\t><mean><\t><std><\t><symmetry_error>
                 <\t><window values seperated by \;><\t><extended window values seperated by \;>

 IMPORTANT!!!    It is assumed that the locations file(s) is sorted by chromosome 
                 (lexicographic order), then by start (=end) coordinate (numerical order)

 Flags:

   -f <file.chr>:     The containing locations file.

   -window <int>:     The window size (default: 157bp).

   -sr <int>:         The sliding resolution (default: 1bp).

   -vc <int>:         The Value column (zero-based, default: 4).

   -ex <int>:         The max gap between locations to a window's end that we use the linear extension 
                      (for the window's ends). If actual gap is larger, then the first value cotained 
                      in the window is replicated for the previous unknown window values, and if the 
                      actual gap is smaller or equal, then we do the linear extension.
                      The same goes for the end of a window (default: 10 bp).

   -stats <st1,...>   The statistics (default: all): 

                          count (locations) /
                          mean (locations) / 
                          std (locations) / 
                          sym_err (symmetry error, extended locations)

   -prnt_w <0/1/2/3>: Print the values (separated by \;) of: 

                          0 (nothing = default) /
                          1 (window locations) /
                          2 (window extended locations) /
                          3 (both 1&2)

   -mcount <int>:     The minimum locations count in a window needed to print statistics (defaul: 2).

   -p <int>:          Precision for outputted statistics (default: 3 numbers after the digit).

   -q:                Quiet mode (default is verbose).

  --help:             Print out this help manual (and exit).
