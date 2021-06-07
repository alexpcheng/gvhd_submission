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

#my $location_key_file = get_arg("k", "", \%args);

my $in_gxt = 0;
my $in_reference_data = 0;
my @feature_types;
while(<$file_ref>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/)
  {
      /FeatureTypes=[\"]([^\"]+)[\"]/;

      @feature_types = split(/\;/, $1);

      $in_gxt = 1;
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
    my @row = split(/\t/);

    print "$row[1]\t$row[0]\t$row[2]\t$row[3]\t$feature_types[$row[4]]\t$row[5]\n";
  }
}

__DATA__

featuregxt_locations2features.pl <domain gxt file>

   Takes a Feature chromosome track and outputs a mapping between locations and feature names

