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

my $precision = get_arg("p", 2, \%args);
my $unique_key = get_arg("k", 4, \%args);

if ($unique_key == 0) { $unique_key = 1; }
elsif ($unique_key == 1) { $unique_key = 0; }

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);
close($file_ref);

foreach my $chromosome (keys %chromosome2locations)
{
    print STDERR "Processing chromosome $chromosome...\n";

    my @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});

    my @features;
    my %features2names;
    my %features2starts;
    my %features2ends;
    my %features2single_length;
    my %features2consecutive_distance;
    my %features2values;

    for (my $i = 0; $i < @chromosome_locations; $i++)
    {
	my @location = split(/\t/, $chromosome_locations[$i]);

	my $key = $location[$unique_key];
	if (length($features2starts{$key}) == 0)
	{
	    push(@features, $key);
	    $features2names{$key} = $location[0];
	    $features2starts{$key} = $location[2];
	    $features2ends{$key} = $location[3];
	    $features2single_length{$key} = $location[3] - $location[2] > 0 ? ($location[3] - $location[2]) : 1;
	    $features2consecutive_distance{$key} = 0;
	    $features2values{$key} = &format_number($location[5], $precision);
	}
	else
	{
	    $features2consecutive_distance{$key} = $location[3] - $features2ends{$key};
	    $features2ends{$key} = $location[3];
	    $features2values{$key} .= ";";
	    $features2values{$key} .= &format_number($location[5], $precision);
	}
    }

    foreach my $feature (@features)
    {
	print "$chromosome\t";
	print "$features2names{$feature}\t";
	print "$features2starts{$feature}\t";
	print "$features2ends{$feature}\t";
	print "$feature\t";
	print "$features2single_length{$feature}\t";
	print "$features2consecutive_distance{$feature}\t";
	print "$features2values{$feature}\n";
    }
}

__DATA__

locations2locationsvector.pl <file> 

    Converts a tab location file in the format
    <chr><tab><name><tab><start><tab><end><tab><feature><tab><value>
    into a tab location vector file where rows of the same feature
    are merged with a delimiter

    -p <num>: Precision of numbers printed out (default: 2 digits)

    -k <num>: Column that defines the entries that will be merged into one vector

