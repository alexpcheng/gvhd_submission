#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

my $remove_chromosome_arms = get_arg("remove_arms", 0, \%args);
my $reference_data_gxt = get_arg("ref", "", \%args);

my $reference_data_str = "";
if (length($reference_data_gxt) > 0)
{
    open(REFERENCE, "<$reference_data_gxt") or die "Could not open chromosome reference data $reference_data_gxt\n";
    my $in_reference_data = 0;
    $reference_data_str = "<ChromosomeReferenceData>\n";
    while(<REFERENCE>)
    {
	chop;

	if (/^<ChromosomeReferenceData/)
	{
	    $in_reference_data = 1;
	}
	elsif (/^<\/ChromosomeReferenceData/)
	{
	    $in_reference_data = 0;
	}
	elsif ($in_reference_data == 1)
	{
	    $reference_data_str .= "$_\n";
	}
    }
    $reference_data_str .= "</ChromosomeReferenceData>\n";
}

while(<$file_ref>)
{
  chop;

  if (/GeneXPressChromosomeTrack/)
  {
    print "$_\n";

    if (/^<GeneXPressChromosomeTrack/)
    {
	print "$reference_data_str";
    }
  }
  else 
  {
    if ($remove_chromosome_arms == 1)
    {
      my @row = split(/\t/, $_, 2);
      
      if ($row[0]=~/([0-9]+)L/ or $row[0]=~/([0-9]+)R/)
      {
	print"$1\t$row[1]\n";
      }
      else
      {
	print"$_\n";
      }
    }
    else
    {
      print "$_\n";
    }
  }
}

__DATA__

gxt_modify.pl <file> 

    Modifies a gxt file

    -remove_arms:  Removes the identity of left/right chromosome arms
                   (e.g., changes 1L --> 1 for chromosome 1)

    -ref <str>:    Add reference data from the gxt in the file <str>

