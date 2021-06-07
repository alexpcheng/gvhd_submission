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

#my $subsequences_file = get_arg("s", "", \%args);

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);
close($file_ref);

foreach my $chromosome (keys %chromosome2locations)
{
    print STDERR "   Chromosome $chromosome...\n";

    my @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});

    for (my $j = 0; $j < @chromosome_locations; $j++)
    {
	my @location = split(/\t/, $chromosome_locations[$j], 5);
	my $name = $location[0];
	my $promoter_on_left = $location[2] < $location[3] ? 1 : 0;

	if ($promoter_on_left == 1)
	{
	    if ($j == 0)
	    {
		print "$location[0]\tUnique\n";
	    }
	    else
	    {
		my @prev_location = split(/\t/, $chromosome_locations[$j - 1], 5);
		if ($prev_location[2] < $prev_location[3])
		{
		    print "$location[0]\tUnique\n";
		}
		else
		{
		    print "$location[0]\tDivergent\n";
		}
	    }
	}
	else
	{
	    if ($j == @chromosome_locations - 1)
	    {
		print "$location[0]\tUnique\n";
	    }
	    else
	    {
		my @next_location = split(/\t/, $chromosome_locations[$j + 1], 5);
		if ($next_location[2] < $next_location[3])
		{
		    print "$location[0]\tDivergent\n";
		}
		else
		{
		    print "$location[0]\tUnique\n";
		}
	    }
	}
    }
}

__DATA__

locations2promoter_type.pl <file>

   Determines the promoter type for each location (Divergent/Unique)
   NOTE: Input is assumed to be in the format <chr><tab><name><tab><start><tab><end>

