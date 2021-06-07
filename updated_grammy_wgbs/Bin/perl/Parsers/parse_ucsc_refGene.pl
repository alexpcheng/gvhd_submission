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

my $without_intergenic = get_arg("without_intergenic", 0, \%args);

my %chromosome2locations = &GetLocationsByChromosomeFromTabFile($file_ref);
close($file_ref);

foreach my $chromosome (keys %chromosome2locations)
{
    print STDERR "Chromosome $chromosome...\n";

    my @chromosome_locations = &SortLocationsByName($chromosome2locations{$chromosome});

    my $locations_for_intergenic = "";

    for (my $i = 0; $i < @chromosome_locations; $i++)
    {
	my @location = split(/\t/, $chromosome_locations[$i]);
	my $name = $location[0];
	my $promoter_on_left = $location[4] eq "+" ? 1 : 0;

	my @exon_starts = split(/\,/, $location[7]);
	my @exon_ends = split(/\,/, $location[8]);
	my %exon_starts_hash;
	for (my $j = 0; $j < @exon_starts; $j++) { $exon_starts_hash{$exon_starts[$j]} = $j; }
	my %exon_ends_hash;
	for (my $j = 0; $j < @exon_ends; $j++) { $exon_ends_hash{$exon_ends[$j]} = $j; }

	my $done_merging = 0;
	while ($done_merging == 0)
	{
	  $done_merging = 1;
	  if (length($chromosome_locations[$i + 1]) > 0)
	  {
	    my @merge_location = split(/\t/, $chromosome_locations[$i + 1]);
	    if ($merge_location[0] eq $name)
	    {
	      $done_merging = 0;
	      $i++;

	      if ($merge_location[2] < $location[2]) { $location[2] = $merge_location[2]; }
	      if ($merge_location[3] > $location[3]) { $location[3] = $merge_location[3]; }
	      if ($merge_location[5] < $location[5]) { $location[5] = $merge_location[5]; }
	      if ($merge_location[6] > $location[6]) { $location[6] = $merge_location[6]; }

	      my @merge_exon_starts = split(/\,/, $merge_location[7]);
	      my @merge_exon_ends = split(/\,/, $merge_location[8]);
	      for (my $j = 0; $j < @merge_exon_starts; $j++)
	      {
		my $merge_exon = 1;

		my $existing_start_idx = $exon_starts_hash{$merge_exon_starts[$j]};
		if (length($existing_start_idx) > 0)
		{
		  $merge_exon = 0;
		  if ($exon_ends[$existing_start_idx] < $merge_exon_ends[$j])
		  {
		    $exon_ends_hash{$exon_ends[$existing_start_idx]} = "";
		    $exon_ends[$existing_start_idx] = $merge_exon_ends[$j];
		    $exon_ends_hash{$merge_exon_ends[$j]} = $existing_start_idx;
		  }
		}

		my $existing_end_idx = $exon_ends_hash{$merge_exon_ends[$j]};
		if (length($existing_end_idx) > 0)
		{
		  $merge_exon = 0;
		  if ($exon_starts[$existing_end_idx] > $merge_exon_starts[$j])
		  {
		    $exon_starts_hash{$exon_starts[$existing_end_idx]} = "";
		    $exon_starts[$existing_end_idx] = $merge_exon_starts[$j];
		    $exon_starts_hash{$merge_exon_starts[$j]} = $existing_end_idx;
		  }
		}

		if ($merge_exon == 1)
		{
		  push(@exon_starts, $merge_exon_starts[$j]);
		  push(@exon_ends, $merge_exon_ends[$j]);
		  my $exon_starts_last_idx = @exon_starts - 1;
		  my $exon_ends_last_idx = @exon_ends - 1;
		  $exon_starts_hash{$merge_exon_starts[$j]} = $exon_starts_last_idx;
		  $exon_ends_hash{$merge_exon_ends[$j]} = $exon_ends_last_idx;
		}
	      }
	    }
	  }
	}

	#------------------------------------------------------------
        # Bubble sort the exon starts and ends together
        #------------------------------------------------------------
	for (my $j = 0; $j < @exon_starts - 1; $j++)
	{
	  for (my $k = 0; $k < @exon_starts - 1 - $j; $k++)
	  {
	    if ($exon_starts[$k + 1] < $exon_starts[$k])
	    {
	      my $tmp = $exon_starts[$k];
	      $exon_starts[$k] = $exon_starts[$k + 1];
	      $exon_starts[$k + 1] = $tmp;
	      my $tmp = $exon_ends[$k];
	      $exon_ends[$k] = $exon_ends[$k + 1];
	      $exon_ends[$k + 1] = $tmp;
	    }
	  }
	}

	#------------------------------------------------------------
        # Examine consecutive exons and merge overlapping ones
        #------------------------------------------------------------
	my @new_exon_starts;
	my @new_exon_ends;
	push(@new_exon_starts, $exon_starts[0]);
	push(@new_exon_ends, $exon_ends[0]);
	my $prev_new_exon_index = 0;
	for (my $j = 0; $j < @exon_starts; $j++)
	{
	  if ($exon_starts[$j] <= $new_exon_starts[$prev_new_exon_index] and $exon_ends[$j] >= $new_exon_ends[$prev_new_exon_index])
	  {
	    $new_exon_starts[$prev_new_exon_index] = $exon_starts[$j];
	    $new_exon_ends[$prev_new_exon_index] = $exon_ends[$j];
	  }
	  elsif ($exon_starts[$j] <= $new_exon_starts[$prev_new_exon_index] and $exon_ends[$j] >= $new_exon_starts[$prev_new_exon_index])
	  {
	    $new_exon_starts[$prev_new_exon_index] = $exon_starts[$j];
	  }
	  elsif ($exon_starts[$j] > $new_exon_starts[$prev_new_exon_index] and $exon_starts[$j] <= $new_exon_ends[$prev_new_exon_index])
	  {
	    $new_exon_ends[$prev_new_exon_index] = $exon_ends[$j];
	  }
	  else
	  {
	    push(@new_exon_starts, $exon_starts[$j]);
	    push(@new_exon_ends, $exon_ends[$j]);
	    $prev_new_exon_index++;
	  }
	}
	@exon_starts = @new_exon_starts;
	@exon_ends = @new_exon_ends;

	#------------------------------------------------------------
        # Transcript
        #------------------------------------------------------------
	if ($promoter_on_left == 1)
	{
	    print "$location[1]\t$location[0]\t$location[2]\t$location[3]\tTranscript\n";
	}
	else
	{
	    print "$location[1]\t$location[0]\t$location[3]\t$location[2]\tTranscript\n";
	}

	#------------------------------------------------------------
        # Coding region
        #------------------------------------------------------------
	if ($promoter_on_left == 1)
	{
	    print "$location[1]\t$location[0] coding\t$location[5]\t$location[6]\tCoding\n";
	}
	else
	{
	    print "$location[1]\t$location[0] coding\t$location[6]\t$location[5]\tCoding\n";
	}

	#------------------------------------------------------------
        # UTRs
        #------------------------------------------------------------
	if ($promoter_on_left == 1)
	{
	  if ($location[2] < $location[5])
	  {
	    print "$location[1]\t$location[0] 5utr\t$location[2]\t$location[5]\t5UTR\n";
	  }
	  if ($location[6] < $location[3] - 3)
	  {
	    print "$location[1]\t$location[0] 3utr\t";
	    print ($location[6] + 3);
	    print "\t$location[3]\t3UTR\n";
	  }
	}
	else
	{
	  if ($location[6] < $location[3])
	  {
	    print "$location[1]\t$location[0] 5utr\t$location[3]\t$location[6]\t5UTR\n";
	  }
	  if ($location[2] < $location[5] - 3)
	  {
	    print "$location[1]\t$location[0] 3utr\t";
	    print ($location[5] - 3);
	    print "\t$location[2]\t3UTR\n";
	  }
	}

	#------------------------------------------------------------
        # Exons/Introns
        #------------------------------------------------------------
	my $intron_counter = 1;
	for (my $j = 0; $j < @exon_starts; $j++)
	{
	    if ($j > 0 and $exon_ends[$j - 1] < $exon_starts[$j])
	    {
		print "$location[1]\t$location[0] intron $intron_counter\t" . ($exon_ends[$j - 1] + 1) . "\t" . ($exon_starts[$j] - 1) . "\tIntron\n";
		$intron_counter++;
	    }

	    if ($promoter_on_left == 1)
	    {
		print "$location[1]\t$location[0] exon " . ($j + 1) . "\t$exon_starts[$j]\t$exon_ends[$j]\tExon\n";
	    }
	    else
	    {
		print "$location[1]\t$location[0] exon " . ($j + 1) . "\t$exon_ends[$j]\t$exon_starts[$j]\tExon\n";
	    }
	}

	$locations_for_intergenic .= "$location[0]\t$location[1]\t$location[2]\t$location[3]\t$location[4]\n";
    }

    #------------------------------------------------------------
    # Intergenic
    #------------------------------------------------------------
    if ($without_intergenic == 0)
    {
      @chromosome_locations = &SortLocations($locations_for_intergenic);
      for (my $i = 0; $i < @chromosome_locations; $i++)
      {
	my @location = split(/\t/, $chromosome_locations[$i]);
	my $name = $location[0];
	my $promoter_on_left = $location[4] eq "+" ? 1 : 0;

	if ($promoter_on_left == 1)
	{
	  if ($i == 0)
	  {
	    print "$location[1]\t$location[0] Upstream\t0\t" . ($location[2] - 1) . "\tUnique promoter\n";
	  }
	  else
	  {
	    my @prev_location = split(/\t/, $chromosome_locations[$i - 1]);
	    if ($prev_location[4] eq "+")
	    {
	      print "$location[1]\t$location[0] Upstream\t" . ($prev_location[3] + 1) . "\t" . ($location[2] - 1) . "\tUnique promoter\n";
	    }
	    else
	    {
	      print "$location[1]\t$prev_location[0] $location[0] Upstream\t" . ($prev_location[3] + 1) . "\t" . ($location[2] - 1) . "\tDivergent promoter\n";
	    }
	  }
	}
	else
	{
	  if ($i == @chromosome_locations - 1)
	  {
	    print "$location[1]\t$location[0] Upstream\t" . ($location[3] + 1) . "\t" . ($location[3] + 1) . "\tUnique promoter\n";
	  }
	  else
	  {
	    my @next_location = split(/\t/, $chromosome_locations[$i + 1]);
	    if ($next_location[4] eq "-")
	    {
	      print "$location[1]\t$location[0] Upstream\t" . ($location[3] + 1) . "\t" . ($next_location[2] - 1) . "\tUnique promoter\n";
	    }

	    my @prev_location = split(/\t/, $chromosome_locations[$i - 1]);
	    if ($prev_location[4] eq "+")
	    {
	      print "$location[1]\t$prev_location[0] $location[0] Downstream\t" . ($prev_location[3] + 1) . "\t" . ($location[2] - 1) . "\tIntergenic\n";
	    }
	  }
	}
      }
    }
}

__DATA__

parse_ucsc_refGene.pl <file>

   Parse a UCSC refGene file into transcripts, exons introns, and
   intergenic regions (by type of intergenic regions)

   -without_intergenic: Do not print intergenic regions and promoters

