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

my $start_distances = get_arg("s", 0, \%args);
my $center_distances = get_arg("c", 0, \%args);
my $end_distances = get_arg("e", 0, \%args);

my @prev_location;
my $counter = 0;
while(<$file_ref>)
{
  chop;

  $counter++;
  if ($counter % 100000 == 0)
  {
    print STDERR ".";
  }

  #print STDERR "REFERENCE\t$_\n";

  my @location = split(/\t/, $_, 5);

  my $location_left = $location[2] < $location[3] ? $location[2] : $location[3];
  my $location_right = $location[2] > $location[3] ? $location[2] : $location[3];
  my $location_reverse = $location[2] <= $location[3] ? 0 : 1;

  if ($prev_location[0] eq $location[0])
  {
    if ($center_distances == 1)
    {
      print int((($location[2] + $location[3]) - ($prev_location[2] + $prev_location[3])) / 2);
      print "\t$_\n";
    }
    elsif ($start_distances == 1)
    {
      print int($location[2] - $prev_location[2]);
      print "\t$_\n";
    }
    elsif ($end_distances == 1)
    {
      print int($location[3] - $prev_location[3]);
      print "\t$_\n";
    }
  }

  @prev_location = @location;
}

__DATA__

chr_consecutive_distances.pl <file>

   For each location, prints its distance to the next consecutive location

   NOTE: the chr is assumed to already be sorted!

   -s: Compute the distances between start positions of consecutive locations
   -c: Compute the distances between center positions of consecutive locations
   -e: Compute the distances between the end positions of consecutive locations

