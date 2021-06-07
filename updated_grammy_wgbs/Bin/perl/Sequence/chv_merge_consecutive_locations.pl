#!/usr/bin/perl

use strict;
use POSIX;

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


my $counter = 0;
my $id = 0;

my $prev_chr = "";
my $prev_end = -1;
my $feature_start = -1;
my $feature_values = "";

my $next_line = "";
my $next_chr = "";
my $next_left = -1;
my $next_right = -1;
my $next_values = "";

my $curr_start = 0;
my $curr_end = 0;

my @location;
my $location_chr = "";
my $location_left = -1;
my $location_right = -1;
my $location_values = "";

my $last_iter = 0;
my $finished = 0;

while($finished == 0)
{
  $counter++;
  if ($counter % 10000 == 0)
  {
    print STDERR ".";
  }

  if ($last_iter == 1)
  {
     $finished = 1;
  }

  $prev_end = $location_right;
  $prev_chr = $location_chr;

  if (length($next_chr) != 0)
  {
     $location_chr = $next_chr;
     $location_left = $next_left;
     $location_right = $next_right;
     $location_values = $next_values;
  }
  else
  {
     $next_line = <$file_ref>;
     chop $next_line;

     if (length($next_line) > 0)
     {
	@location = split(/\t/, $next_line, 8);
	$location_chr = $location[0];
	$location_left = $location[2];
	$location_right = $location[3];
	$location_values = $location[7];
	
	if ($location[5] != 1 or $location[6] != 1)
	{
	   print STDERR "Error: only supprting chv's with per bp features\n";
	   exit 1;
	}
     }
     else
     {
	last;
     }
  }

  if ($location_chr eq $prev_chr and $location_left < $prev_end)
  {
     $curr_start = ceil(($prev_end + 1 - $location_left) / 2);
  }
  else
  {
     $curr_start = 0;
     $feature_start = $location_left;
     $feature_values = "";
  }

  # Read next feature
  $next_line = <$file_ref>;
  chop $next_line;
  if (length($next_line) > 0)
  {
     @location = split(/\t/, $next_line, 8);
     $next_chr = $location[0];
     $next_left = $location[2];
     $next_right = $location[3];
     $next_values = $location[7];
     
     if ($location[5] != 1 or $location[6] != 1)
     {
	print STDERR "Error: only supprting chv's with per bp features\n";
	exit 1;
     }
  }
  else
  {
     $last_iter = 1;
     $next_left = $location_right + 10;
  }

  if ($finished == 0 and $location_chr eq $next_chr and $next_left < $location_right)
  {
     $curr_end = $location_right - $location_left - ceil(($location_right - $next_left)/2);
  }
  else
  {
     $curr_end = $location_right - $location_left;
  }

  $feature_values .=  &get_values($location_values, $curr_start, $curr_end) . ";";

  if ((($finished == 1) or ($location_chr ne $next_chr) or ($location_right < $next_left)) and length($feature_values) > 1)
  {
     $id++;
     print "$location_chr\t$id\t$feature_start\t$location_right\t1\t1\t1\t$feature_values\n";
  }
}

sub get_values
{
   my ($values, $start, $end) = @_;

   my $start_idx = 0;
   my $end_idx = 0;

   for (my $i = 0; $i < $start; $i++)
   {
      $start_idx = index ($values, ";", $start_idx);
      $start_idx++;
   }

   $end_idx = $start_idx > 0 ? $start_idx - 1 : 0;

   for (my $i = $start; $i <= $end; $i++)
   {
      $end_idx = index ($values, ";", $end_idx + 1);
   }
   $end_idx = $end_idx == -1 ? length($values) : $end_idx;
   
   return substr ($values, $start_idx, $end_idx - $start_idx);
}

__DATA__

chv_merge_consecutive_locations.pl <file>

   Merges consecutive locations of a chv into longer locations - if there is an overlap of size 2X between locations, 
   the first X bps will be taken from the first location, and the last X bps from the second one.

   NOTE 1: Assumes that the file has been sorted by chromosome and then start, supprts only per bp chvs with all the features on the forward strand.

   Used by ~/Data/Chromatin/Predictions/Model_0308/... to create nucleosomes predictions.

