#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/format_number.pl";
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

my $alignment_file = get_arg("f", "", \%args);
my $upstream_bp = get_arg("u", 100, \%args);
my $downstream_bp = get_arg("d", 100, \%args);
my $default_value = get_arg("v", 0, \%args);
my $rev =  get_arg("r", 0, \%args);
my $orientation =  get_arg("o", 0, \%args);
my $chr_format = get_arg("chr", 0, \%args);
my $header_num = get_arg("h", 0, \%args);

my %chromosome2locations;

if (!$chr_format) {
    %chromosome2locations = &GetLocationsByChromosome($file_ref);
}
else{
    for (my $i=1;$i<=$header_num;$i++){ <$file_ref> }
    %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);
}
close($file_ref);

open(ALIGNMENT_FILE, "<$alignment_file") or die "Could not open alignment file $alignment_file\n";
my %alignment_chromosome2locations;
while(<ALIGNMENT_FILE>)
{
    chop;

    my @row = split(/\t/);

    $alignment_chromosome2locations{$row[0]} .= "$row[1]\t$row[0]\t$row[2]\t$row[3]\t$row[4]\n";

    #print STDERR "alignment_chromosome2locations{$row[0]} .= $row[1]\t$row[0]\t$row[2]\t$row[3]\t$row[4]\n";
}
close(ALIGNMENT_FILE);

print "Name";
for (my $i = -$upstream_bp; $i <= $downstream_bp; $i++)
{
    if ($rev){
	print "\t".(-$i);
    }
    else {
	print "\t$i";
    }
}
print "\n";

foreach my $chromosome (keys %alignment_chromosome2locations)
{
    print STDERR "   Chromosome $chromosome...\n";

    my @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});
    my @alignment_chromosome_locations = &SortLocations($alignment_chromosome2locations{$chromosome});

    my $start_index = 0;

    for (my $i = 0; $i < @alignment_chromosome_locations; $i++)
    {
	my @alignment_location = split(/\t/, $alignment_chromosome_locations[$i]);
	my $alignment_name = "$alignment_location[1]:$alignment_location[0]";
	my $alignment_center = $alignment_location[2] < $alignment_location[3] ? $alignment_location[2] : $alignment_location[3];
	if ($orientation){
	    $alignment_center = $alignment_location[2];
	}
	my $alignment_left = $alignment_center - $upstream_bp;
	my $alignment_right = $alignment_center + $downstream_bp;
	my $reverse = $alignment_location[2] < $alignment_location[3] ? 1 : 0;
	my @matrix;
	my $current_alignment_index = $alignment_left;

	#print STDERR "     alignment is $alignment_name:[$alignment_left..$alignment_right]\n";
	
	for (my $j = $start_index; $j < @chromosome_locations; $j++)
	{
	    my @location = split(/\t/, $chromosome_locations[$j]);
	    my $start = $location[2] < $location[3] ? $location[2] : $location[3];
	    my $end = $location[2] < $location[3] ? $location[3] : $location[2];
	    my $value = &format_number($location[5], 3);

	    #print STDERR "       examining $location[1]:$location[0]:[$start..$end] current=$current_alignment_index value=$value\n";

	    if ($end < $alignment_left)
	    {
		$start_index = $j + 1;
	    }
	    elsif ($start <= $alignment_right)
	    {
		#print STDERR "       intersecting $location[1]:$location[0]:[$start..$end] current=$current_alignment_index value=$value\n";

		for (; $current_alignment_index < $start; $current_alignment_index++)
		{
		    $matrix[$current_alignment_index - $alignment_left] = $default_value;
		}

		for (; $current_alignment_index <= $end and $current_alignment_index <= $alignment_right; $current_alignment_index++)
		{
		    $matrix[$current_alignment_index - $alignment_left] = $value;
		}
	    }
	    else
	    {
		#print STDERR "       completing [$current_alignment_index..$alignment_right] value=$default_value\n";

		for (; $current_alignment_index <= $alignment_right; $current_alignment_index++)
		{
		    $matrix[$current_alignment_index - $alignment_left] = $default_value;
		}

		last;
	    }
	}
	
	#print STDERR "       finishing [$current_alignment_index..$alignment_right] value=$default_value\n";
	for (; $current_alignment_index <= $alignment_right; $current_alignment_index++)
	{
	    $matrix[$current_alignment_index - $alignment_left] = $default_value;
	}

	print "$alignment_name";
	if ($reverse == 0)
	{
	    for (my $j = 0; $j < @matrix; $j++) { print "\t$matrix[$j]"; }
	}
	else
	{
	    for (my $j = @matrix - 1; $j >= 0; $j--) { print "\t$matrix[$j]"; }
	}
	print "\n";
    }
}

__DATA__

locations2score_tab.pl <file>

   Given a feature gxt file in the format <chr><tab><name><tab><start><tab><end><tab><feature><tab><value>
   and a location file in the format <chr><tab><name><tab><start><tab><end><tab>
   outputs a matrix of scores relative to each location in the second file

   NOTE: the only purpose of the end location in the location file is to specify the 
         orientation with which to extract values from the main location value file.

   -f <str>: location file with which to align the scores
   -u <num>: number of bp to print upstream of the location (default: 100)
   -d <num>: number of bp to print downstream of the location (default: 100)

   -v <num>: default value to fill in case of no overlap (default: 0)
   -r:       reverse upstream/downstream
   -o:       always use start of location (3rd column) as center of alignment.
   -chr:     use chr format instead of gxt for feature file (same format as location file)
   -h:       number of headers lines in feature file (relevant only for chr format)


