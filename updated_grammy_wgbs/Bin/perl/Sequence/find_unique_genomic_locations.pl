#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

my $consider_types = get_arg("by_types", 0, \%args);
my $maximum_intersection = get_arg("mi", 0, \%args);
my $sorted = get_arg("sorted", 0, \%args);

my $chromosome_counter = 0;
my %chromosome2id;
my @all_location_counts_by_chromosome;
my @all_location_starts;
my @all_location_ends;
my @all_location_types;

my $global_counter = 0;
while(<$file_ref>)
{
  chop;

  $global_counter++;
  if ($global_counter % 10000 == 0) { print STDERR "."; }

  my @row = split(/\t/);

  my $start = $row[2] < $row[3] ? $row[2] : $row[3];
  my $end = $row[2] < $row[3] ? $row[3] : $row[2];

  if (&Intersects($row[0], $start, $end, $row[4]) == 0)
  {
    print "$_\n";

    my $chromosome_id = $chromosome2id{$row[0]};
    if (length($chromosome_id) == 0)
    {
      $chromosome_id = $chromosome_counter;
      $chromosome2id{$row[0]} = $chromosome_id;
      $all_location_counts_by_chromosome[$chromosome_id] = 0;
      $chromosome_counter++;
    }

    my $num_locations = $all_location_counts_by_chromosome[$chromosome_id];
    $all_location_starts[$chromosome_id][$num_locations] = $start;
    $all_location_ends[$chromosome_id][$num_locations] = $end;
    $all_location_types[$chromosome_id][$num_locations] = $row[4];
    $all_location_counts_by_chromosome[$chromosome_id]++;
  }
}

print STDERR "Done.\n";

sub Intersects
{
  my ($chromosome, $start, $end, $type) = @_;

  my $res = 0;

  my $chromosome_id = $chromosome2id{$chromosome};
  if (length($chromosome_id) > 0)
  {
    my $num_locations = $all_location_counts_by_chromosome[$chromosome_id];

    for (my $i = 0; $i < $num_locations; $i++)
    {
      my $start_intersection = $start < $all_location_starts[$chromosome_id][$i] ? $all_location_starts[$chromosome_id][$i] : $start;
      my $end_intersection = $end < $all_location_ends[$chromosome_id][$i] ? $end : $all_location_ends[$chromosome_id][$i];
      my $intersection_size = $end_intersection - $start_intersection + 1;
      
      if ($intersection_size > $maximum_intersection and ($consider_types == 0 or $all_location_types[$chromosome_id][$i] eq $type))
      {
	$res = 1;
	
	last;
      }
    }
  }

  return $res;
}

__DATA__

find_unique_genomic_locations.pl <file>

   Given a location file in the format <chr><tab><name><tab><start><tab><end><tab>...
   takes the first set of locations that have no overlap with any other locations.

   Useful for example, as a greedy approach to look at competition between binding sites.

   -by_types: Allow overlap between different types (type is in column 5)

   -mi <num>: Max intersection allowed between locations (default: 0)
   
