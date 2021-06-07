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

my $in_domain_gxt = 0;
my $in_reference_data = 0;
my $max_index = 0;
my %chromosome2referencedata;
my %experimentid2name;
my %data;
my @experiments;
my @genes;
my %genes_hash;
while(<$file_ref>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/ and /ChromosomeDomainTrack/)
  {
    $in_domain_gxt = 1;

    /ExperimentNameMap=[\"]([^\"]+)[\"]/;

    my @row = split(/\;/, $1);
    print "Gene";
    for (my $i = 0; $i < @row; $i += 2)
    {
      print "\t";
      print ($row[$i + 1]);
      $experimentid2name{$row[$i]} = $row[$i + 1];
      push(@experiments, $row[$i + 1]);
    }
    print "\n";
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

    my @domain_genes;
    my @referencedata = split(/\t/, $chromosome2referencedata{$row[0]});
    for (my $i = 0; $i < @referencedata; $i++)
    {
	my @referencedata_row = split(/\;/, $referencedata[$i]);
	if ($referencedata_row[1] >= $row[2] and $referencedata_row[2] <= $row[3])
	{
	    push(@domain_genes, $referencedata_row[0]);

	    if (length($genes_hash{$referencedata_row[0]}) == 0)
	    {
	      $genes_hash{$referencedata_row[0]} = "1";
	      push(@genes, $referencedata_row[0]);
	    }
	}
    }

    my @domain_experiments;
    for (my $i = 6; $i < @row; $i++)
    {
      my @line = split(/\;/, $row[$i]);

      if ($line[1] >= $max_index)
      {
	$max_index = $line[1];
      }

      my $data_item;
      if ($line[1] == 0) { $data_item = 2; }
      elsif ($line[1] == 1) { $data_item = 0; }

      my $experiment_name = $experimentid2name{$line[0]};
      for (my $i = 0; $i < @domain_genes; $i++)
      {
	$data{$domain_genes[$i]}{$experiment_name} = $data_item;
      }
    }
  }
}

for (my $i = 0; $i < @genes; $i++)
{
  print "$genes[$i]";

  for (my $j = 0; $j < @experiments; $j++)
  {
    print "\t";

    if (length($data{$genes[$i]}{$experiments[$j]}) == 0)
    {
      print "1";
    }
    else
    {
      print "$data{$genes[$i]}{$experiments[$j]}";
    }
  }

  print "\n";
}

__DATA__

domaingxt2stats.pl <domain gxt file>

   Takes a domain track and output the track as a data matrix

