#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
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

my $comparison_location_file = get_arg("f", "", \%args);
my $print_extra_columns_in_comparison_locations = get_arg("e", 0, \%args);
my $print_extra_columns_in_input_locations = get_arg("ie", 0, \%args);
my $max_proximal_distance = get_arg("maxd", -1, \%args);

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);
close($file_ref);

open(COMPARISON_FILE, "<$comparison_location_file") or die "Could not open comparison location file $comparison_location_file\n";
my $other_file_ref = \*COMPARISON_FILE;
my %other_chromosome2locations = &GetLocationsByChromosomeFromTabFile($other_file_ref);
close($other_file_ref);

my @chromosome_locations;
my @other_chromosome_locations;

foreach my $chromosome (keys %chromosome2locations)
{
    print STDERR "Processing chromosome $chromosome...\n";

    @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});
    @other_chromosome_locations = &SortLocations($other_chromosome2locations{$chromosome});

    my $location_index = 0;
    my $other_location_min_index = 0;

    while($location_index < @chromosome_locations)
    {
	my @location = split(/\t/, $chromosome_locations[$location_index], 5);

	my $left = $location[2] < $location[3] ? $location[2] : $location[3];
	my $right = $location[2] < $location[3] ? $location[3] : $location[2];

	my $best_closest_distance = -1;
	my $best_closest_distance_index = -1;
	my $best_relationship;

	for (my $i = $other_location_min_index; $i < @other_chromosome_locations; $i++)
	{
	    my @other_location = split(/\t/, $other_chromosome_locations[$i], 5);

	    my $other_left = $other_location[2] < $other_location[3] ? $other_location[2] : $other_location[3];
	    my $other_right = $other_location[2] < $other_location[3] ? $other_location[3] : $other_location[2];

	    my $min_distance = &Min4($left - $other_left, $left - $other_right, $right - $other_left, $right - $other_right); 

	    if ($left > $other_right)
	    {
		$other_location_min_index = $i;
	    }

	    if ($left >= $other_left and $right <= $other_right)
	    {
		print "Contained\t$min_distance";
		&PrintLocation($location_index);
		&PrintOtherLocation($i);
		$best_closest_distance_index = -1;
		last;
	    }
	    elsif ($other_left >= $left and $other_right <= $right)
	    {
		print "Containing\t$min_distance";
		&PrintLocation($location_index);
		&PrintOtherLocation($i);
		$best_closest_distance_index = -1;
		last;
	    }
	    elsif ($left <= $other_right and $right >= $other_left)
	    {
		print "Intersects\t$min_distance";
		&PrintLocation($location_index);
		&PrintOtherLocation($i);
		$best_closest_distance_index = -1;
		last;
	    }
	    elsif ($left > $other_right)
	    {
		if ($best_closest_distance == -1 or $min_distance < $best_closest_distance)
		{
		    $best_closest_distance = $min_distance;
		    $best_closest_distance_index = $i;
		    $best_relationship = $other_location[2] < $other_location[3] ? "Outside 3p" : "Outside 5p";
		}
	    }
	    elsif ($right < $other_left)
	    {
		if ($best_closest_distance == -1 or $min_distance < $best_closest_distance)
		{
		    $best_closest_distance = $min_distance;
		    $best_closest_distance_index = $i;
		    $best_relationship = $other_location[2] < $other_location[3] ? "Outside 5p" : "Outside 3p";
		}
		last;
	    }
	}

	if ($best_closest_distance_index != -1 and ($max_proximal_distance == -1 or $best_closest_distance <= $max_proximal_distance))
	{
	    print "$best_relationship\t$best_closest_distance";
	    &PrintLocation($location_index);
	    &PrintOtherLocation($best_closest_distance_index);
	}

	$location_index++;
    }
}

sub PrintOtherLocation
{
    my ($other_location_index) = @_;

    my @other_location = split(/\t/, $other_chromosome_locations[$other_location_index], 5);

    print "\t$other_location[1]";
    print "\t$other_location[0]";
    print "\t$other_location[2]";
    print "\t$other_location[3]";

    if ($print_extra_columns_in_comparison_locations == 1 and length($other_location[4]) > 0)
    {
	print "\t$other_location[4]";
    }

    print "\n";
}

sub PrintLocation
{
    my ($location_index) = @_;

    my @location = split(/\t/, $chromosome_locations[$location_index], 5);

    print "\t$location[1]";
    print "\t$location[0]";
    print "\t$location[2]";
    print "\t$location[3]";

    if ($print_extra_columns_in_input_locations == 1 and length($location[4]) > 0)
    {
	print "\t$location[4]";
    }
}

sub Min2
{
    my ($num1, $num2) = @_;

    return $num1 < $num2 ? $num1 : $num2;
}

sub Min4
{
    my ($num1, $num2, $num3, $num4) = @_;

    if ($num1 < 0) { $num1 = -$num1; }
    if ($num2 < 0) { $num2 = -$num2; }
    if ($num3 < 0) { $num3 = -$num3; }
    if ($num4 < 0) { $num4 = -$num4; }

    return &Min2(&Min2($num1, $num2), &Min2($num3, $num4));
}

__DATA__

find_closest_locations.pl <file>

   Given a location file in the format <chr><tab><name><tab><start><tab><end><tab>...
   and a comparison location file in the same format, finds the closest location 
   from the second file to each location in the first file 

   -f <str>:    Location file in which to search for closest correspondences

   -e:          Print the extra columns in the comparison locations
   -ie:         Print the extra columns in the input locations

   -maxd <num>: Maximum distance still considered as close (default: no max distance)

    NOTE: Contained, Contains, or Intersects relationships are considered 
          closest and the first which is found of these will be printed

