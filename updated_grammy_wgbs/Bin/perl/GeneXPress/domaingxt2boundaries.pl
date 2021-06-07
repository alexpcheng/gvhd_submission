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

my $location_file = get_arg("l", "", \%args);

open(LOCATION_FILE, "<$location_file") or die "Could not open location file $location_file\n";
my $location_file_ref = \*LOCATION_FILE;

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($location_file_ref);
my %sorted_chromosome2locations;
foreach my $chromosome (keys %chromosome2locations)
{
    my @chromosome_locations = &SortLocations($chromosome2locations{$chromosome});
    $sorted_chromosome2locations{$chromosome} = \@chromosome_locations;
}

print "Domain\tOutside left\tLeft boundary\tRight boundary\tOutside right\n";

my $in_domain_gxt = 0;
my $in_reference_data = 0;
my $max_index = 0;
my %chromosome2referencedata;
while(<$file_ref>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/ and /ChromosomeDomainTrack/)
  {
    $in_domain_gxt = 1;
  }
  elsif (/^<ChromosomeReferenceData/)
  {
    $in_reference_data = 1;
  }
  elsif (/^<\/ChromosomeReferenceData/)
  {
    $in_reference_data = 0;
  }
  elsif (/^<\/GeneXPressChromosomeTrack/)
  {
    $in_domain_gxt = 0;
  }
  elsif ($in_reference_data == 1)
  {
    my @row = split(/\t/);

    $chromosome2referencedata{$row[0]} .= "$row[1];$row[2];$row[3]\t";
  }
  elsif ($in_domain_gxt == 1 and $in_reference_data == 0)
  {
    my @row = split(/\t/);

    my $outside_left = "";
    my $left_gene = "";
    my $right_gene = "";
    my $outside_right = "";
    my @referencedata = @{$sorted_chromosome2locations{$row[0]}};

    for (my $i = 0; $i < @referencedata; $i++)
    {
	my @referencedata_row = split(/\t/, $referencedata[$i]);
	if ($referencedata_row[2] >= $row[2] and $referencedata_row[3] <= $row[3])
	{
	   if (length($left_gene) == 0)
	   {
	       $left_gene = $referencedata_row[0];
	   }

	   $right_gene = $referencedata_row[0];
	}

	if ($referencedata_row[2] < $row[2])
	{
	    $outside_left = $referencedata_row[0];
	}

	if ($referencedata_row[2] > $row[3] and length($outside_right) == 0)
	{
	    $outside_right = $referencedata_row[0];
	}
    }

    print "$row[1]\t$outside_left\t$left_gene\t$right_gene\t$outside_right\n";
  }
}

__DATA__

domaingxt2stats.pl <domain gxt file>

   Takes a domain track and a location file and extracts
   the boundary genes of each domain

   -l <str>: Location track file to use

