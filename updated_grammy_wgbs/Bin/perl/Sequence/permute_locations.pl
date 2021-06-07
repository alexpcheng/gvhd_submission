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

my $gxt_file = get_arg("gxt", 0, \%args);
my $preserve_spacing = get_arg("preserve_spacing", 0, \%args);
my $random_placing = get_arg("random_placing", 0, \%args);
my $min_spacing = get_arg("min_spacing", 0, \%args);
my $global_start = get_arg("s", "", \%args);
my $start_file = get_arg("sf", "", \%args);
my $global_end = get_arg("e", "", \%args);
my $end_file = get_arg("ef", "", \%args);

my %start_positions;
if (length($start_file) > 0)
{
  open(START_FILE, "<$start_file");
  while(<START_FILE>)
  {
    chomp;

    my @row = split(/\t/);

    $start_positions{$row[0]} = $row[1];
  }
}
my %end_positions;
if (length($end_file) > 0)
{
  open(END_FILE, "<$end_file");
  while(<END_FILE>)
  {
    chomp;

    my @row = split(/\t/);

    $end_positions{$row[0]} = $row[1];
  }
}

my %chromosome2locations = $gxt_file == 1 ? &GetLocationsByChromosome($file_ref) : &GetLocationsByChromosomeFromTabFile($file_ref);
close($file_ref);

foreach my $chromosome (keys %chromosome2locations)
{
  #print STDERR "Processing chromosome $chromosome...\n";

  my @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});

  my $start = length($global_start) > 0 ? $global_start : $start_positions{$chromosome};
  my $end = length($global_end) > 0 ? $global_end : $end_positions{$chromosome};

  if ($random_placing == 1)
  {
    if (length($start) == 0)
    {
      my @location1 = split(/\t/, $chromosome_locations[0], 5);
      $start = $location1[2] < $location1[3] ? $location1[2] : $location1[3];
    }
    if (length($end) == 0)
    {
      my @location1 = split(/\t/, $chromosome_locations[@chromosome_locations - 1], 5);
      $end = $location1[2] > $location1[3] ? $location1[2] : $location1[3];
    }

    #print STDERR "Start=$start End=$end\n";

    for (my $locations_index = 0; $locations_index < @chromosome_locations; $locations_index++)
    {
      my @location = split(/\t/, $chromosome_locations[$locations_index], 5);

      my $new_left = $start + int(rand($end - $start - 1));

      my $left = $location[2] < $location[3] ? $location[2] : $location[3];
      my $right = $location[2] < $location[3] ? $location[3] : $location[2];

      print "$location[1]\t";
      print "$location[0]\t";
      print ($new_left);
      print "\t";
      print ($new_left + $right - $left);
      print "\t";
      print "$location[4]\n";
    }
  }
  else
  {
    my $spacings_size = &GetSpacingsSize(\@chromosome_locations);

    if (length($start) > 0)
    {
      my @location1 = split(/\t/, $chromosome_locations[0], 5);
      my $left = $location1[2] < $location1[3] ? $location1[2] : $location1[3];
      $spacings_size += $left - $start;
    }
    if (length($end) > 0)
    {
      my @location1 = split(/\t/, $chromosome_locations[@chromosome_locations - 1], 5);
      my $right = $location1[2] > $location1[3] ? $location1[2] : $location1[3];
      $spacings_size += $end - $right;
    }

    #print STDERR "spacings size = $spacings_size\n";

    my @spacings;
    my @positive_spacings;
    for (my $i = 0; $i < @chromosome_locations; $i++)
    {
      my @location1 = $i == 0 ? () : split(/\t/, $chromosome_locations[$i - 1], 5);
      my @location2 = split(/\t/, $chromosome_locations[$i], 5);

      my $first_right = $i == 0 ? 0 : ($location1[2] < $location1[3] ? $location1[3] : $location1[2]);
      my $second_left = $location2[2] < $location2[3] ? $location2[2] : $location2[3];

      if ($preserve_spacing == 1)
      {
	push(@spacings, $second_left - $first_right);
      }
      elsif ($second_left > $first_right)
      {
	my $r = int(rand($spacings_size));
	push(@spacings, $r);
	push(@positive_spacings, $r);
      }
      else
      {
	push(@spacings, $second_left - $first_right);
      }
    }

    if ($preserve_spacing == 1)
    {
      #print STDERR "S=@spacings\n";
      for (my $i = 0; $i < 2; $i++)
      {
	my $num_spacings = @spacings;
	for (my $j = 0; $j < @spacings; $j++)
	{
	  my $r = int(rand($num_spacings));
	  my $temp = $spacings[$j];
	  $spacings[$j] = $spacings[$r];
	  $spacings[$r] = $temp;
	}
      }
      #print STDERR "S=@spacings\n";
    }
    else
    {
      @positive_spacings = sort { $a <=> $b } @positive_spacings;
      my $j = 0;
      for (my $i = 0; $i < @spacings; $i++)
      {
	if ($spacings[$i] >= 0)
	{
	  $spacings[$i] = $j == 0 ? $positive_spacings[$j] : ($positive_spacings[$j] - $positive_spacings[$j - 1]);
	  if ($spacings[$i] < $min_spacing) { $spacings[$i] = $min_spacing; }
	  $j++;
	}
      }
    }

    my @row = split(/\t/, $chromosome_locations[0]);
    my $current_left = length($start) > 0 ? $start : ($row[2] < $row[3] ? $row[2] : $row[3]);

    for (my $locations_index = 0; $locations_index < @chromosome_locations; $locations_index++)
    {
      my @location = split(/\t/, $chromosome_locations[$locations_index], 5);

      my $left = $location[2] < $location[3] ? $location[2] : $location[3];
      my $right = $location[2] < $location[3] ? $location[3] : $location[2];

      $current_left += $spacings[$locations_index];

      print "$location[1]\t";
      print "$location[0]\t";
      print ($current_left);
      print "\t";
      print ($current_left + $right - $left);
      print "\t";
      print "$location[4]\n";

      $current_left += $right - $left;
    }
  }
}

__DATA__

permute_locations.pl <file>

   Given a location file in the format <chr><tab><name><tab><start><tab><end><tab>...
   permutes all locations within each chromosome

   -gxt:               File is a gxt file (so preserve first and last rows)

   -preserve_spacing:  Preserve the spacings between consecutive locations (default: randomly select positions)
   -random_placing:    Ignore the spacing between items and just randomly place items in the allotted positions

   -min_spacing <num>: Minimum spacing allowed between elements (default: 0)

   -s <num>:           Global start position
   -sf <str>:          File with start position for each <chr> (format: <chr><tab><start>)

   -e <num>:           Global end position
   -ef <str>:          File with end position for each <chr> (format: <chr><tab><end>)

