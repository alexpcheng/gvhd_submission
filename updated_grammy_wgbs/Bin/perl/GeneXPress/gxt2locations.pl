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

my $location_key_file = get_arg("k", "", \%args);

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

my $in_gxt = 0;
my $in_reference_data = 0;
while(<$file_ref>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/)
  {
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

    if (length($location_key_file) == 0 || length($allowed_locations{$row[1]}) > 0)
    {
	print "$row[1]\t$row[0]\t$row[2]\t$row[3]\n";
    }
  }
}

__DATA__

gxt2locations.pl <domain gxt file>

   Takes a chromosome track and outputs its location names

   -k <file>:  If specified, consider only locations that appear in the first column of <file>

