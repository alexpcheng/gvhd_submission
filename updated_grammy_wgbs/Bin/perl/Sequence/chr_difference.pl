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
my $comparison_files_str = get_arg("f", "", \%args);
my $max_allowed_overlap = get_arg("o", 0, \%args);
my $print_overlap_size = get_arg("po", 0, \%args);
my $print_comparison_differences = get_arg("r", 0, \%args);

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);
close($file_ref);

my @comparison_files = split(/\,/, $comparison_files_str);

my %overlapping_locations;

foreach my $comparison_file (@comparison_files)
{
  $comparison_file =~ /([^\s]+)/;
  $comparison_file = $1;

  if (-s $comparison_file)
  {
    print STDERR "Intersecting $comparison_file...\n";

    open(INTERSECTION_FILE, "<$comparison_file");
    my $other_file_ref = \*INTERSECTION_FILE;
    my %other_chromosome2locations = &GetLocationsByChromosomeFromTabFile($other_file_ref);
    close($other_file_ref);

    foreach my $chromosome (keys %other_chromosome2locations)
    {
      print STDERR "   Chromosome $chromosome...\n";

      my @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});
      my @other_chromosome_locations = &SortLocations($other_chromosome2locations{$chromosome});

      my $location_index = 0;
      
      for (my $i = 0; $i < @other_chromosome_locations; $i++)
      {
	my @other_location = split(/\t/, $other_chromosome_locations[$i], 5);
	my $other_start = $other_location[2];
	my $other_end = $other_location[3];
	my $other_left = $other_start < $other_end ? $other_start : $other_end;
	my $other_right = $other_start < $other_end ? $other_end : $other_start;
	my $other_name = $other_location[0];
	
	for (my $j = $location_index; $j < @chromosome_locations; $j++)
	{
	  my @location = split(/\t/, $chromosome_locations[$j], 5);
	  my $start = $location[2];
	  my $end = $location[3];
	  my $left = $start < $end ? $start : $end;
	  my $right = $start < $end ? $end : $start;
	  my $name = $location[0];

	  if ($left > $other_right)
	  {
	    last;
	  }
	  elsif ($other_left > $right)
	  {
	    $location_index = $j;
	  }
	  else
	  {
	    if (($left >= $other_left and $left <= $other_right) or ($other_left >= $left and $other_left <= $right))
	    {
	      my $overlap_size;
	      if ($left >= $other_left and $right <= $other_right)
	      {
		$overlap_size = $right - $left + 1;
	      }
	      elsif ($other_left >= $left and $other_right <= $right)
	      {
		$overlap_size = $other_right - $other_left + 1;
	      }
	      else
	      {
		  my $max_left = $other_left > $left ? $other_left : $left;
		  my $min_right = $other_right < $right ? $other_right : $right;
		  $overlap_size = $min_right - $max_left + 1;
	      }

	      my $str;
	      if ($print_comparison_differences == 1)
	      {
		$str = "$other_location[1]\t$other_name\t$other_start\t$other_end";
	      }
	      else
	      {
		$str = "$location[1]\t$name\t$start\t$end";
	      }

	      my $previous_overlap = $overlapping_locations{$str};
	      if (length($previous_overlap) == 0 or $previous_overlap < $overlap_size)
	      {
		$overlapping_locations{$str} = $overlap_size;
		#print STDERR "Adding overlap overlapping_locations{$str} = $overlap_size\n";
	      }
	    }
	  }
	}
      }
    }
  }
}

if ($print_comparison_differences == 1)
{
  foreach my $comparison_file (@comparison_files)
  {
    $comparison_file =~ /([^\s]+)/;
    $comparison_file = $1;

    if (-s $comparison_file)
    {
      open(INTERSECTION_FILE, "<$comparison_file");
      my $other_file_ref = \*INTERSECTION_FILE;
      my %other_chromosome2locations = &GetLocationsByChromosomeFromTabFile($other_file_ref);
      close($other_file_ref);

      foreach my $chromosome (keys %other_chromosome2locations)
      {
	print STDERR "Printing Chromosome $chromosome...\n";

	my @other_chromosome_locations = &SortLocations($other_chromosome2locations{$chromosome});

	for (my $i = 0; $i < @other_chromosome_locations; $i++)
	{
	  my @other_location = split(/\t/, $other_chromosome_locations[$i], 5);
	  my $other_start = $other_location[2];
	  my $other_end = $other_location[3];
	  my $other_name = $other_location[0];
	
	  my $str = "$other_location[1]\t$other_name\t$other_start\t$other_end";

	  my $overlap = $overlapping_locations{$str};
	  if (length($overlap) == 0) { $overlap = 0; }
	  if ($overlap <= $max_allowed_overlap)
	  {
	    print "$str";
	    if (length($other_location[4]) > 0)
	    {
	      print "\t$other_location[4]";
	    }
	    if ($print_overlap_size == 1)
	    {
	      print "\t$overlap";
	    }
	    print "\n";
	  }
	}
      }
    }
  }
}
else
{
  foreach my $chromosome (keys %chromosome2locations)
  {
    print STDERR "Printing Chromosome $chromosome...\n";

    my @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});

    for (my $i = 0; $i < @chromosome_locations; $i++)
    {
      my @location = split(/\t/, $chromosome_locations[$i], 5);
      my $start = $location[2];
      my $end = $location[3];
      my $name = $location[0];
	
      my $str = "$location[1]\t$name\t$start\t$end";

      my $overlap = $overlapping_locations{$str};
      if (length($overlap) == 0) { $overlap = 0; }
      if ($overlap <= $max_allowed_overlap)
      {
	print "$str";
	if (length($location[4]) > 0)
	{
	  print "\t$location[4]";
	}
	if ($print_overlap_size == 1)
	{
	  print "\t$overlap";
	}
	print "\n";
      }
    }
  }
}

__DATA__

chr_difference.pl <chr file>

   Extracts the locations from the input chr file that do not overlap with
   more than a specified bp with any location in a comparison location file

   -f <str>: Track files to compare with (multiple files allowed, separated by commas)

   -o <num>: Maximum overlap (in bp) between a location in the input file and the comparison file (default: 0)

   -po:      Print the size of the overlap

   -r:       Reverse: print locations from the comparison files that do not overlap

