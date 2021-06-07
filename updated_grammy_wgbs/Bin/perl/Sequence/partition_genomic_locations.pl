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

my $distance_interval = get_arg("int", 10, \%args);
my $max_distance = get_arg("max", 500, \%args);
my $chr_column = get_arg("c", 0, \%args);
my $key_column = get_arg("k", 1, \%args);
my $start_column = get_arg("s", 2, \%args);
my $end_column = get_arg("e", 3, \%args);

my @all_start_locations;

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    my $other_features = "";
    for (my $i = 0; $i < @row; $i++)
    {
	if ($i != $chr_column and $i != $key_column and $i != $start_column and $i != $end_column)
	{
	    $other_features .= "\t$row[$i]";
	}
    }

    push(@all_start_locations, "$row[$chr_column]\t$row[$key_column]\t$row[$start_column]\t$row[$end_column]$other_features");
}

@all_start_locations = sort { my @aa = split(/\t/,$a); my @bb = split(/\t/,$b); $aa[2] <=> $bb[2]; } @all_start_locations;

foreach my $location (@all_start_locations)
{
    my @row = split(/\t/, $location, 5);

    my $start_location = $row[2];
    my $end_location = $row[3];

    if (length($row[4]) > 0) { $row[4] = "\t$row[4]"; }

    if ($start_location > $end_location)
    {
	for (my $i = -$max_distance; $i <= $max_distance; $i += $distance_interval)
	{
	    my $start = $start_location - $i;
	    my $end = $start_location - $i - $distance_interval;
	    if ($end > 0)
	    {
		my $start_description = "[" . &ToDescription($i) . "," . &ToDescription($i + $distance_interval) . "]";
		print "$row[0]\t$row[1]\t$start\t$end\tStart $start_description$row[4]\n";
	    }
	}
    }
    else
    {
	for (my $i = -$max_distance; $i <= $max_distance; $i += $distance_interval)
	{
	    my $start = $start_location + $i;
	    my $end = $start_location + $i + $distance_interval;
	    if ($start > 0)
	    {
		my $start_description = "[" . &ToDescription($i) . "," . &ToDescription($i + $distance_interval) . "]";
		print "$row[0]\t$row[1]\t$start\t$end\tStart $start_description$row[4]\n";
	    }
	}
    }
}

sub ToDescription
{
    my ($location) = @_;

    return $location == 0 ? 0 : ($location < 0 ? $location : "+$location");
}

__DATA__

partition_genomic_locations.pl <file>

   Given a file of locations with a key, start, end, partitions the 
   genomic locations into regions according to their distance from
   the given locations

   -int <num>: Interval lengths to extract (default: 20)
   -max <num>: Max distance to extract (default: 500)

   -c <num>: Column for chromosome name (default: 0)
   -k <num>: Column for the key (default: 1)
   -s <num>: Column for the start location (default: 2)
   -e <num>: Column for the end location (default: 3)

