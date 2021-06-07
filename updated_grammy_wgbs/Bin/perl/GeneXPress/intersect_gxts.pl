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
my $files_str = get_arg("f", 0, \%args);
my $max_allowed_distance = get_arg("d", 0, \%args);
my $tab_files = get_arg("t", 0, \%args);
my $sorted = get_arg("s", 0, \%args);
my $print_intersection_size = get_arg("pi", 0, \%args);
my $print_intersection = get_arg("p", 0, \%args);
my $ignore_identical_location_names = get_arg("i", 0, \%args);
my $modify_other_upstream = get_arg("add_up", 0, \%args);
my $modify_other_downstream = get_arg("add_down", 0, \%args);
my $match = get_arg("match", 0, \%args);

if ($sorted == 1 and $tab_files == 0)
{
   print STDERR "Error: -s can be used only in -t mode.\n";
   exit 1;
}

my @files = split(/\,/, $files_str);
my $location_index = 0;
my @chromosome_locations;

my %chromosome2locations = $tab_files == 0 ? &GetLocationsByChromosome($file_ref) : &GetLocationsByChromosomeFromTabFile($file_ref);
close($file_ref);

foreach my $file (@files)
{
   $file =~ /([^\s]+)/;
   $file = $1;

   if (-s $file or $file eq "-")
   {
      #print STDERR "Intersecting $file...\n";
 my $other_file_ref;
     if ($file ne "-")
	{ 
      open(INTERSECTION_FILE, "<$file");
      $other_file_ref = \*INTERSECTION_FILE;
	}	
	else
	{
	$other_file_ref = \*STDIN;
	}

      my %other_chromosome2locations;
      if ($sorted == 0)
      {
		%other_chromosome2locations = $tab_files == 0 ? &GetLocationsByChromosome($other_file_ref) : &GetLocationsByChromosomeFromTabFile($other_file_ref);
		close($other_file_ref);
      } 
      else 
      {
		$other_chromosome2locations{"dummy"} = 1;
      }

      my $prev_chromosome;
     
      foreach my $chromosome (keys %other_chromosome2locations)
      {
	  #print STDERR "cccc\n";
	 if ($sorted == 1)
	 {
	    while (<$other_file_ref>)
	    {
	       chop;
	       my @row = split (/\t/, $_, 5);
	       if ($row[0] ne $prev_chromosome)
	       {
		  $prev_chromosome = $row[0];
		   #print STDERR "   Chromosome $row[0] ...\n";
		  @chromosome_locations = &SortLocations($chromosome2locations{$row[0]});
		  $location_index = 0;
	       }
	
	       my $extension = length($row[4]) > 0 ? "\t$row[4]" : "";
	       &AnalyzeLocation ("$row[1]\t$row[0]\t$row[2]\t$row[3]$extension");
	    }
	 }
	 else
	 {
	    #print STDERR "   Chromosome $chromosome...\n";
	    
	    @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});
	    my @other_chromosome_locations = &SortLocations($other_chromosome2locations{$chromosome});
	    
	    $location_index = 0;
	    
	    for (my $i = 0; $i < @other_chromosome_locations; $i++)
	    {
	       &AnalyzeLocation ($other_chromosome_locations[$i]);
	    }
	 }
	 
      }
   }
}

sub AnalyzeLocation ($)
{
   my @other_location = split(/\t/, $_[0], 5);   
   my $other_start = $other_location[2];
   my $other_end = $other_location[3];
   my $other_left = $other_start < $other_end ? $other_start - $modify_other_upstream: $other_end - $modify_other_downstream;
   my $other_right = $other_start < $other_end ? $other_end + $modify_other_downstream: $other_start + $modify_other_upstream;
   my $other_name = $other_location[0];
   
   for (my $j = $location_index; $j < @chromosome_locations; $j++)
   {
      my @location = split(/\t/, $chromosome_locations[$j], 5);
      my $start = $location[2];
      my $end = $location[3];
      my $left = $start < $end ? $start : $end;
      my $right = $start < $end ? $end : $start;
      my $name = $location[0];
      
      if ($left > $other_right + $max_allowed_distance)
      {
	 last;
      } 
      elsif ($other_left > $right + $max_allowed_distance)
      {
	 for (my $k = $j; $k > $location_index; $k--)
	 {
	    $chromosome_locations[$k] = $chromosome_locations[$k - 1];
	 }
	 
	 $location_index++;
	 my @location = split(/\t/, $chromosome_locations[$location_index]);
	 
	 #$location_index = $j;
      } 
      elsif ($ignore_identical_location_names == 0 or $name ne $other_name)
      {
	 
	 if (($left >= $other_left and $left <= $other_right) or ($other_left >= $left and $other_left <= $right))
	 {
	    print "$name\t$location[1]\t$start\t$end\t";
	    print "$other_name\t$other_location[1]\t$other_start\t$other_end\t";
	    print "0\t";
	    
	    if ($match == 1 and abs($left - $other_left) <= $max_allowed_distance and abs($right - $other_right) <= $max_allowed_distance)
	    {
	       print "Match\t";
	    }
	    elsif ($left >= $other_left and $right <= $other_right)
	    {
	       print "Contained\t";
	       if ($print_intersection_size == 1)
	       {
		  print ($right - $left + 1); print "\t";
	       }
	       if ($print_intersection == 1)
		 {
		   print "$start\t$end\t";
		 }
	     }
	    elsif ($other_left >= $left and $other_right <= $right)
	    {
	       print "Contains\t";
	       if ($print_intersection_size == 1)
		 {
		   print ($other_right - $other_left + 1); print "\t";
		 }
	       if ($print_intersection == 1)
		 {
		   if ($start<$end){ print "$other_left\t$other_right\t" }
		   else{ print "$other_right\t$other_left\t" }
		 }
	     } 
	    else 
	    {
	      print "Intersects\t";
	      my $max_left = $other_left > $left ? $other_left : $left;
	      my $min_right = $other_right < $right ? $other_right : $right;
	      if ($print_intersection_size == 1)
		{
		  print ($min_right - $max_left + 1);
		  print "\t";
		}
	      if ($print_intersection == 1)
		{
		  if ($start<$end){ print "$max_left\t$min_right\t" }
		  else { print "$min_right\t$max_left\t" }
		}
	     }
	    
	    print "$location[4]\t$other_location[4]\n";
	 } 
	 elsif ($left > $other_right and $left - $other_right <= $max_allowed_distance)
	 {
	    print "$name\t$location[1]\t$start\t$end\t";
	    print "$other_name\t$other_location[1]\t$other_start\t$other_end\t";
	    print ($left - $other_right);
	    print "\t";
	    print "Right\t";
	    if ($print_intersection_size == 1)
	    {
	       print "0\t";
	    }
	    if ($print_intersection == 1)
	    {
	       print "-\t-\t";
	    }
	    print "$location[4]\t$other_location[4]\n";
	 } 
	 elsif ($other_left > $right and $other_left - $right <= $max_allowed_distance)
	 {
	    print "$name\t$location[1]\t$start\t$end\t";
	    print "$other_name\t$other_location[1]\t$other_start\t$other_end\t";
	    print ($other_left - $right);
	    print "\t";
	    print "Left\t";
	    if ($print_intersection_size == 1)
	    {
	       print "0\t";
	    }
	    if ($print_intersection == 1)
	    {
	       print "-\t-\t";
	    }
	    print "$location[4]\t$other_location[4]\n";
	 }
      }
   }
}

__DATA__

intersect_gxts.pl <domain gxt file>

Takes a chromosome track and outputs all locations that intersect 
with another set of tracks

-f <files>: List of track files to intersect with (comma separated)

-d <num>:   Max. distance between the endpoints of locations for calling intersection (default: 0)

-t:         Input files are tab-files and not genomica track files (such as chr files)
-s:         Input file are already sorted (by position, only when -t is specified). This allows not to load the input files into memory.

-pi:        Print the size of the intersection
-p:         Print the coordinates of the intersection

-i:         Do not intersect two locations with the same name (default: do intersect them)

-match:     Print only locations that match (start point are below -d bp and same for end points)

-add_up <num>:    Add <num> upstream of -f files (num may be negative: '"num"')
-add_down <num>:  Add <num> downstream of -f files (num may be negative: '"num"')
