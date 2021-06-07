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

print "Domain\tChromosome\tStart\tEnd\tLength\tGenes\tGene names\tExperiments\n";

my $in_domain_gxt = 0;
my $in_reference_data = 0;
my $max_index = 0;
my %chromosome2referencedata;
my %experimentid2name;
while(<$file_ref>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/ and /ChromosomeDomainTrack/)
  {
    $in_domain_gxt = 1;

    /ExperimentNameMap=[\"]([^\"]+)[\"]/;

    my @row = split(/\;/, $1);
    for (my $i = 0; $i < @row; $i += 2)
    {
	$experimentid2name{$row[$i]} = $row[$i + 1];
    }
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

    my $gene_counts = 0;
    my $domain_genes = "";
    my @referencedata = split(/\t/, $chromosome2referencedata{$row[0]});
    for (my $i = 0; $i < @referencedata; $i++)
    {
	my @referencedata_row = split(/\;/, $referencedata[$i]);
	if ($referencedata_row[1] >= $row[2] and $referencedata_row[2] <= $row[3])
	{
	    $gene_counts++;
	    if (length($domain_genes) > 0) { $domain_genes .= ";" }
	    $domain_genes .= "$referencedata_row[0]";
	}
    }

    my @counts;
    my @domain_experiments;
    for (my $i = 6; $i < @row; $i++)
    {
      my @line = split(/\;/, $row[$i]);

      $counts[$line[1]]++;
      if ($line[1] >= $max_index)
      {
	$max_index = $line[1];
      }

      if (length($domain_experiments[$line[1]]) > 0) { $domain_experiments[$line[1]] .= ";" }
      $domain_experiments[$line[1]] .= "$experimentid2name{$line[0]}";
    }

    my $length = $row[3] - $row[2] + 1;
    print "$row[1]\t$row[0]\t$row[2]\t$row[3]\t$length\t$gene_counts\t$domain_genes\t";

    my $sum = 0;
    for (my $i = 0; $i <= $max_index; $i++)
    {
      $sum += $counts[$i];
    }
    print "$sum";

    for (my $i = 0; $i <= $max_index; $i++)
    {
      if (length($counts[$i]) > 0)
      {
	print "\t$counts[$i]";
	print "\t$domain_experiments[$i]";
      }
      else
      {
	print "\t0";
	print "\t";
      }
    }
    print "\n";
  }
}

__DATA__

domaingxt2stats.pl <domain gxt file>

   Takes a domain track and computes general statistics on it

