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

my $location_track_file = get_arg("l", "", \%args);
my $location_key_file = get_arg("k", "", \%args);
my $min_experiment_per_location = get_arg("min", 1, \%args);
my $do_not_print_locations = get_arg("sp", 0, \%args);
my $print_summary = get_arg("s", 0, \%args);

my %allowed_locations;
if (length($location_key_file) > 0)
{
    open(KEY_FILE, "<$location_key_file") or die "Could not open location key file $location_key_file\n";
    while(<KEY_FILE>)
    {
	chop;

	my @row = split(/\t/);

	$allowed_locations{$row[0]} = "1";
    }
}

my $in_domain_gxt = 0;
my $in_reference_data = 0;
my %chromosome2domains;
my %domains2startlocations;
my %domains2endlocations;
my %domains2experiments;
my $num_domains = 0;
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
  elsif ($in_domain_gxt == 1 and $in_reference_data == 0)
  {
    my @row = split(/\t/, $_, 7);

    $chromosome2domains{$row[0]} .= "$row[1]\t";
    $domains2startlocations{$row[1]} = $row[2];
    $domains2endlocations{$row[1]} = $row[3];
    $domains2experiments{$row[1]} = $row[6];
    $num_domains++;
    #print STDERR "$row[1]\t$row[2]\t$row[3]\t$row[6]\n";
  }
}

if ($do_not_print_locations == 0)
{
    print "Gene\tNum Experiments\tNum Domains\n";
}

open(LOCATION_FILE, "<$location_track_file") or die "Could not open reference location file $location_track_file\n";
my $in_gxt = 0;
my $total_counts = 0;
my $num_locations = 0;
my $num_printed_locations = 0;
my $num_experiments = 0;
while(<LOCATION_FILE>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/)
  {
    $in_gxt = 1;

    /ExperimentNameMap=[\"]([^\"]+)[\"]/;

    my @row = split(/\;/, $1);

    $num_experiments = @row;
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
    $in_gxt = 0;
  }
  elsif ($in_gxt == 1 and $in_reference_data == 0)
  {
    my @row = split(/\t/, $_, 5);

    my $start_location = $row[2] < $row[3] ? $row[2] : $row[3];
    my $end_location = $row[2] < $row[3] ? $row[3] : $row[2];

    my $domain_counter = 0;
    my @domains = split(/\t/, $chromosome2domains{$row[0]});
    my $experiments_str = "";
    foreach my $domain (@domains)
    {
      if ($start_location >= $domains2startlocations{$domain} and $end_location <= $domains2endlocations{$domain})
      {
	$experiments_str .= "$domains2experiments{$domain}\t";
	$domain_counter++;
      }
    }

    my %experiments_hash;
    my @experiments = split(/\t/, $experiments_str);
    foreach my $experiment (@experiments)
    {
      my @domain_experiment = split(/\;/, $experiment, 2);
      $experiments_hash{$domain_experiment[0]} = "1";
    }

    my $experiment_counter = 0;
    foreach my $experiment (keys %experiments_hash)
    {
      $experiment_counter++;
    }
    $total_counts += $experiment_counter;

    if ($experiment_counter >= $min_experiment_per_location)
    {
	if ($do_not_print_locations == 0)
	{
	    print "$row[1]\t$experiment_counter\t$domain_counter\n";
	}
	$num_printed_locations++;
    }

    $num_locations++;
  }
}

if ($print_summary == 1)
{
    print "Number domains\t$num_domains\n";

    my $percent_locations = $num_locations > 0 ? &format_number(100 * $num_printed_locations / $num_locations, 1) : 0;
    print "Number printed locations\t$num_printed_locations\t$num_locations\t$percent_locations\n";

    my $num_data_points = $num_experiments * $num_locations;
    my $percent_data_points = $num_data_points > 0 ? &format_number(100 * $total_counts / $num_data_points, 1) : 0;
    print "Number data points in domains\t$total_counts\t$num_data_points\t$percent_data_points\n";
}

__DATA__

domaingxt2locations.pl <domain gxt file>

   Takes a domain track and a location track and outputs the number of experiments
   that each location is associated with.

   -l <file>:  The location track
   -k <file>:  If specified, consider only locations that appear in the first column of <file>

   -min <num>: Minimum number of experiments in order to print a location (default: 1)

   -sp:        Surpress printing of individual locations
   -s:         Print summary

