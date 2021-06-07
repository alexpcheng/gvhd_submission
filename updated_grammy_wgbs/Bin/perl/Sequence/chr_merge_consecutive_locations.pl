#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
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

my $merge_same_name_locations = get_arg("mi", 0, \%args);
my $merge_same_type_locations = get_arg("by_types", 0, \%args);
my $merge_by_values = get_arg("by_values", "", \%args);
my $maximum_gap_size = get_arg("mg", 1, \%args);
my $no_merge_max = get_arg("no_merge_max", 0, \%args);
my $average_values = get_arg("avg_values", 0, \%args);
my $sum_values = get_arg("sum_values", 0, \%args);
my $max_values = get_arg("max_values", 0, \%args);
my $minimum_location_size = get_arg("ms", 10, \%args);

my @prev_location;
my @prev_location_bp_merges;
my @prev_location_num_merges;
my @prev_location_total_bp;
my @prev_location_total_value;
my @prev_location_max_value;
my %types2index;
my $num_types = 0;
my $counter = 0;
while(<$file_ref>)
{
  chop;

  $counter++;
  if ($counter % 10000 == 0)
  {
    print STDERR ".";
  }

  #print STDERR "REFERENCE\t$_\n";

  my @location = split(/\t/, $_, 7);

  my $location_left = $location[2] < $location[3] ? $location[2] : $location[3];
  my $location_right = $location[2] > $location[3] ? $location[2] : $location[3];
  my $location_reverse = $location[2] <= $location[3] ? 0 : 1;
  my $location_size = $location_right - $location_left + 1;
  my $type;
  if ($merge_same_type_locations == 1)
  {
    $type =  $types2index{$location[4]};
    if (length($type) == 0)
    {
      $type = $num_types;
      $types2index{$location[4]} = $num_types;
      $num_types++;
    }
  }
  else
  {
    $type = 0;
    $num_types = 1;
  }

  my $prev_location_left = $prev_location[2][$type] < $prev_location[3][$type] ? $prev_location[2][$type] : $prev_location[3][$type];
  my $prev_location_right = $prev_location[2][$type] > $prev_location[3][$type] ? $prev_location[2][$type] : $prev_location[3][$type];
  my $prev_location_reverse = $prev_location[2][$type] <= $prev_location[3][$type] ? 0 : 1;
  my $prev_location_size = $prev_location_right - $prev_location_left + 1;

  if ($location[0] ne $prev_location[0][$type] or
      $location_left - $prev_location_right > $maximum_gap_size or
      $location_size < $minimum_location_size or 
      $prev_location_size < $minimum_location_size or 
      ($merge_same_name_locations == 1 and $location[1] ne $prev_location[1][$type]) or 
      (length($merge_by_values) > 0 and abs($location[5] - $prev_location[5][$type]) > $merge_by_values))
  {
    #print STDERR "Start\n";
    #print STDERR "$location[0]\n";
    #print STDERR "$prev_location[0][$type]\n";
    #print STDERR "$location_left\n";
    #print STDERR "$location_right\n";
    #print STDERR "$prev_location_left\n";
    #print STDERR "$prev_location_right\n";
    #print STDERR "V=$location[5]\n";
    #print STDERR "V=$prev_location[5][$type]\n";
    #print STDERR "$maximum_gap_size\n";
    #print STDERR "$minimum_location_size\n";
    if (length($prev_location[0][$type]) > 0)
    {
      print "$prev_location[0][$type]\t$prev_location[1][$type]\t$prev_location[2][$type]\t$prev_location[3][$type]";
      if (length($prev_location[4][$type]) > 0) { print "\t$prev_location[4][$type]"; }

      if (length($prev_location[5][$type]) > 0)
      {
	if ($average_values == 1)
	{
	  print "\t";
	  print &format_number($prev_location_total_value[$type] / $prev_location_total_bp[$type], 3);
	}
	elsif ($sum_values == 1)
	{
	  print "\t";
	  print &format_number($prev_location_total_value[$type], 3);
	}
	elsif ($max_values == 1)
	{
	  print "\t";
	  print &format_number($prev_location_max_value[$type], 3);
	}
	else
	{
	  print "\t$prev_location[5][$type]";
	}
      }

      if (length($prev_location[6][$type]) > 0) { print "\t$prev_location[6][$type]"; }
      print "\t$prev_location_num_merges[$type]\t$prev_location_bp_merges[$type]\n";
    }

    $prev_location_bp_merges[$type] = 0;
    $prev_location_num_merges[$type] = 0;

    for (my $i = 0; $i < @location; $i++)
    {
      $prev_location[$i][$type] = @location[$i];
    }

	if ($max_values == 1)
	{
      $prev_location_max_value[$type] = $location[5];
	}
	
    if ($sum_values == 1)
    {
      $prev_location_total_value[$type] = $location[5];
    }
    else
    {
      $prev_location_total_bp[$type] = $location_right - $location_left + 1;
      $prev_location_total_value[$type] = ($location_right - $location_left + 1) * $location[5];
    }
  }
  else
  {
    $prev_location_num_merges[$type]++;
    if ($location_left - $prev_location_right - 1 > 0)
    {
      $prev_location_bp_merges[$type] += $location_left - $prev_location_right - 1;
    }

    if ($no_merge_max == 1)
    {
      if (($sum_values == 1 and $location[5] > $prev_location_total_value[$type]) or 
	  (($location_right - $location_left + 1) * $location[5] > $prev_location_total_value[$type]))
      {
	for (my $i = 0; $i < @location; $i++)
	{
	  $prev_location[$i][$type] = @location[$i];
	}

	if ($sum_values == 1)
	{
	  $prev_location_total_value[$type] = $location[5];
	}
	else
	{
	  $prev_location_total_bp[$type] = $location_right - $location_left + 1;
	  $prev_location_total_value[$type] = ($location_right - $location_left + 1) * $location[5];
	}
      }
    }
    else
    {
      my $right = $location_right > $prev_location_right ? $location_right : $prev_location_right;
      my $left = $location_left < $prev_location_left ? $location_left : $prev_location_left;

      if ($prev_location_reverse == 0)
      {
	$prev_location[2][$type] = $left;
	$prev_location[3][$type] = $right;
      }
      else
      {
	$prev_location[3][$type] = $left;
	$prev_location[2][$type] = $right;
      }

	  if (($max_values == 1) and ($prev_location_max_value[$type] < $location[5]))
	  {
	  	$prev_location_max_value[$type] = $location[5];
	  }
	  
      if ($sum_values == 1)
      {
	$prev_location_total_value[$type] += $location[5];
      }
      else
      {
	$prev_location_total_bp[$type] += $location_right - $location_left + 1;
	$prev_location_total_value[$type] += ($location_right - $location_left + 1) * $location[5];
      }
    }
  }
}

for (my $type = 0; $type < $num_types; $type++)
{
  if (length($prev_location[0][$type]) > 0)
  {
    print "$prev_location[0][$type]\t$prev_location[1][$type]\t$prev_location[2][$type]\t$prev_location[3][$type]";
    if (length($prev_location[4][$type]) > 0) { print "\t$prev_location[4][$type]"; }

    if (length($prev_location[5][$type]) > 0)
    {
      if ($average_values == 1)
      {
	print "\t";
	print &format_number($prev_location_total_value[$type] / $prev_location_total_bp[$type], 3);
      }
      elsif ($sum_values == 1)
      {
	print "\t";
	print &format_number($prev_location_total_value[$type], 3);
      }
      elsif ($max_values == 1)
      {
	print "\t";
	print &format_number($prev_location_max_value[$type], 3);
      }
      else
      {
	print "\t$prev_location[5][$type]";
      }
    }

    if (length($prev_location[6][$type]) > 0) { print "\t$prev_location[6][$type]"; }
    print "\t$prev_location_num_merges[$type]\t$prev_location_bp_merges[$type]\n";
  }
}

__DATA__

chr_merge_consecutive_locations.pl <file>

   Merges consecutive locations into longer locations

   NOTE 1: Assumes that the file has been sorted by chromosome and then min(start,end)

   -mi:              Merge only locations that have the same name

   -by_types:        Merge only locations that have the same type (column 5)

   -by_values <num>: Merge only locations whose values are within <num> of each other

   -no_merge_max:    Rather than merging locations that pass the merging criteria, take the location with the max value in the 6th column

   -avg_values:      Average values in the 6th column when merging locations
   -sum_values:      Sum values in the 6th column when merging locations
   -max_values:      Print the maximal value in the 6th column when merging locations

   -mg <num>:        Maximum size of the gap allowed between two consecutive locations for merging (default: 1)
   -ms <num>:        Minimum size that a location must have in order to be merged (default: 10)

