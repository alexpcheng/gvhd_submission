#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/GeneXPress/gxt_helpers.pl";

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
my $window_size = get_arg("w", 500, \%args);
my $window2window_distance = get_arg("d", 10, \%args);
my $min_window_weight =  get_arg("minw", 1, \%args);
my $stats_to_compute = get_arg("s", "Mean", \%args);
my $stats_file_sorted = get_arg("sorted", 0, \%args);
my $compute_stats_by_type = get_arg("by_type", 0, \%args);
my $distance_shape = get_arg("c", "Square", \%args);
my $center_coord = get_arg("rcc", 0, \%args);

my $LOG_BASE = log(2);

my $counter = 1;

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);

my $window_stats_array_size = $window2window_distance < $window_size ? int($window_size / $window2window_distance) : 1;
my $window_stats_half_array_size = $window_stats_array_size / 2;
my $window_bp_per_array_entry = $window2window_distance < $window_size ? $window2window_distance : $window_size;
$min_window_weight *= $window_size;

if ($window2window_distance < $window_size and $window_size % $window2window_distance != 0)
{
  print STDERR "Window size must be full increments of distance\n";
  print STDERR "\n";
}

my %type2index;
my @index2type;
my $num_types = 0;
foreach my $chromosome (keys %chromosome2locations)
{
  my @chromosome_locations;
  if ($stats_file_sorted == 0)
  {
    @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});
  }
  else
  {
    @chromosome_locations = split(/\n/, $chromosome2locations{$chromosome});
  }

  my @window_stats;
  my @window_stats_weight;
  my @window_total_stats;
  my @window_total_stats_weight;
  my $window_stats_index = 0;

  my $window_start = -100000000;
  my $window_end = -100000000;

  my $location_index = 0;
  while ($location_index < @chromosome_locations)
  {
    if ($window_start == -100000000)
    {
      my @location = split(/\t/, $chromosome_locations[$location_index]);
      my $left = $location[2] < $location[3] ? $location[2] : $location[3];
      my $right = $location[2] < $location[3] ? $location[3] : $location[2];

      $window_start = $left - $window_size + $window_bp_per_array_entry;
      $window_end = $left + $window_bp_per_array_entry - 1;
    }

    my $window_array_entry_start = $window_end - $window_bp_per_array_entry + 1;
    my $had_overlap = 0;

    my $had_overlap = 0;

    for (my $i = $location_index; $i < @chromosome_locations; $i++)
    {
      my @location = split(/\t/, $chromosome_locations[$i]);
      my $left = $location[2] < $location[3] ? $location[2] : $location[3];
      my $right = $location[2] < $location[3] ? $location[3] : $location[2];

      if ($left > $window_end)
      {
	last;
      }
      elsif ($right < $window_start)
      {
	for (my $j = $i; $j > $location_index; $j--)
	{
	  $chromosome_locations[$j] = $chromosome_locations[$j - 1];
	}

	$location_index++;
      }
      else
      {
	$had_overlap = 1;

	my $intersection_right = $right < $window_end ? $right : $window_end;
	my $intersection_left = $left > $window_array_entry_start ? $left : $window_array_entry_start;
	my $intersection_size = $intersection_right - $intersection_left + 1;

	if ($intersection_size > 0)
	{
	  my $type_index;
	  if ($compute_stats_by_type == 1)
	  {
	    $type_index = $type2index{$location[4]};

	    if (length($type_index) == 0)
	    {
	      $type2index{$location[4]} = $num_types;
	      $type_index = $num_types;
	      push(@index2type, $location[4]);
	      $num_types++;
	    }
	  }
	  else
	  {
	    $type_index = 0;
	    $index2type[0] = $location[4];
	    $type2index{$location[4]} = 0;
	  }

	  #print STDERR "Type: $location[4] index=$type_index index2type=$index2type[$type_index]\n";

	  if ($stats_to_compute eq "Mean" or $stats_to_compute eq "Sum")
	  {
	    #print STDERR "StatsIndex=$window_stats_index Intersection=$intersection_size Value=$location[5]\n";

	    $window_stats[$window_stats_index][$type_index] += $location[5] * $intersection_size;
	    $window_stats_weight[$window_stats_index][$type_index] += $intersection_size;

	    $window_total_stats[$type_index] += $location[5] * $intersection_size;
	    $window_total_stats_weight[$type_index] += $intersection_size;
	  }
	  elsif ($stats_to_compute eq "MeanOfLogs")
	  {
	    $window_stats[$window_stats_index][$type_index] += log($location[5]) / $LOG_BASE * $intersection_size;
	    $window_stats_weight[$window_stats_index][$type_index] += $intersection_size;

	    $window_total_stats[$type_index] += log($location[5]) / $LOG_BASE * $intersection_size;
	    $window_total_stats_weight[$type_index] += $intersection_size;
	  }
	}
      }
    }

    $window_stats_index = ($window_stats_index + 1) % $window_stats_array_size;
    for (my $i = 0; $i < @index2type; $i++)
    {
      if ($window_total_stats_weight[$i] > 0)
      {
	my $stats = 0;
	if ($distance_shape eq "Square")
	{
	  $stats = $window_total_stats[$i];
	}
	elsif ($distance_shape eq "Triangle")
	{
	  my $total_weight = 0;
	  for (my $j = 0; $j < $window_stats_array_size; $j++)
	  {
	    my $weight = $j < $window_stats_half_array_size ? $window_stats_half_array_size - ($j + 0.5) : ($j + 0.5 - $window_stats_half_array_size);
	    $weight = 1 - ($weight / $window_stats_half_array_size);

	    my $index = ($j + $window_stats_index) % $window_stats_array_size;

	    $stats += $weight * $window_stats[$index][$i];
	    $total_weight += $window_stats_weight[$index][$i];

	    #print STDERR "w=$weight total=$total_weight ws=$window_stats_weight[$index][$i] s=$window_stats[$index][$i]\n";
	  }
	}

	if ($stats_to_compute eq "Mean" or $stats_to_compute eq "MeanOfLogs")
	{
	  $stats = $stats / $window_total_stats_weight[$i];
	}

	$stats = &format_number($stats, 3);

	#my $s = $window_total_stats[$i] / $window_total_stats_weight[$i];
	#print "$chromosome\t$counter\t$window_start\t$window_end\t$index2type[$i]\t$s\n";

	if ($window_total_stats_weight[$i] >= $min_window_weight)
	{
	
	  print "$chromosome\t$counter\t";
	  
	  if ($center_coord)
	  {
		my $window_center = abs (int (($window_start + $window_end) / 2));
		print "$window_center\t$window_center\t";
	  }
	  else
	  {
	    print "$window_start\t$window_end\t";
	  }
	  
	  print "$index2type[$i]\t$stats\n";
	  $counter++;
	}

	#print STDERR "total=$window_total_stats[$i] removing=$window_stats[$window_stats_index][$i] w=$window_stats_weight[$window_stats_index][$i] type=$index2type[$i]\n";

	$window_total_stats[$i] -= $window_stats[$window_stats_index][$i];
	$window_total_stats_weight[$i] -= $window_stats_weight[$window_stats_index][$i];
	$window_stats[$window_stats_index][$i] = 0;
	$window_stats_weight[$window_stats_index][$i] = 0;
      }
    }

    if ($had_overlap == 1)
    {
      $window_start += $window2window_distance;
      $window_end += $window2window_distance;
    }
    elsif ($had_overlap == 0)
    {
      my @location = split(/\t/, $chromosome_locations[$location_index]);
      my $left = $location[2] < $location[3] ? $location[2] : $location[3];
      my $right = $location[2] < $location[3] ? $location[3] : $location[2];

      @window_stats = ();
      @window_stats_weight = ();
      @window_total_stats = ();
      @window_total_stats_weight = ();
      $window_stats_index = 0;

      $window_start = $left - $window_size + $window_bp_per_array_entry;
      $window_end = $left + $window_bp_per_array_entry - 1;
    }
  }
}

__DATA__

sliding_window_location_stats.pl <location file>

   Takes a location stats file and computes statistics for it using a sliding
   window with defined resolution and offset

   -w <num>:    Window size (default: 500)
   -d <num>:    Distance between two neighboring windows (default: 10)

   -minw <num>: Minimum weight of stats file above which the window is considered
                Given in units of window size (default: 1), i.e., for a 500bp window 
                '2' means that the TOTAL number of bp from the location stats that 
                need to intersect for the window to be printed is 1000

   -s <str>:    Statistic to compute (Mean/MeanOfLogs/Sum) (default: Mean)

   -sorted:     Input location stats are already sorted (default: assumes no sorting)

   -by_type:    Compute results separately for each type (type is given in fifth column)

   -c <str>:    Distance function from center to deconvolve the data with (default: Square)
                Square   --- square function over the window
                Triangle --- triangle centered at the middle basepair

   -rcc:        Report center coordinate of window as both start and end instead of actual
                start and end of the area taken into account.
            
