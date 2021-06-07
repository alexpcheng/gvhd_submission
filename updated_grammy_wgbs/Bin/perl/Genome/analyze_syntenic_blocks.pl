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

my $min_genes_per_id = get_arg("min", 3, \%args);

my %id2order;
my %id2count;
while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    $id2order{$row[0]} .= "$row[6]\t$row[7]\t";
    $id2count{$row[0]}++;
}

foreach my $id (keys %id2count)
{
    #print STDERR "Processing id=$id count=$id2count{$id}\n";

    my @row = split(/\t/, $id2order{$id});

    if ($id2count{$id} >= $min_genes_per_id)
    {
	my %chromosomes_counts;
	my $max_chromosome_counts = 0;
	my $max_chromosome;
	for (my $i = 0; $i < @row; $i+=2)
	{
	    $chromosomes_counts{$row[$i]}++;
	    if ($chromosomes_counts{$row[$i]} > $max_chromosome_counts)
	    {
		$max_chromosome_counts = $chromosomes_counts{$row[$i]};
		$max_chromosome = $row[$i];
	    }
	}

	my $prev_location = "";
	my $num_increasing = 0;
	my $num_decreasing = 0;
	for (my $i = 0; $i < @row; $i+=2)
	{
	    if ($row[$i] eq $max_chromosome)
	    {
		if (length($prev_location) > 0)
		{
		    if ($row[$i + 1] > $prev_location)
		    {
			$num_increasing++;
		    }
		    else
		    {
			$num_decreasing++;
		    }
		}

		$prev_location = $row[$i + 1];
	    }
	}

	my $sum = $num_increasing + $num_decreasing;
	if ($sum >= $min_genes_per_id)
	{
	    print "$id\t";
	    my $increasing = $num_increasing / $sum;
	    my $decreasing = $num_decreasing / $sum;
	    print ($increasing > $decreasing ? &format_number($increasing, 2) : &format_number($decreasing, 2));
	    print "\t";
	    print "$num_increasing\t" . &format_number($increasing, 2) . "\t";
	    print "$num_decreasing\t" . &format_number($decreasing, 2) . "\t$sum\n";
	}
    }
}

__DATA__

analyze_syntenic_blocks.pl <file>

   Takes in as input a file with consecutive genes (e.g., from human) and
   the matching genes from another organisms (e.g., mouse) and analyzes 
   the sequence of genes from the other organism for whether they are from
   the same chromosome, and whether there were rearrangements.

   Column 1:    block id
   Columns 2-5: gene name, chr, chr start, chr end, from the first organism
   Columns 6-9: gene name, chr, chr start, chr end, from the second organism

   -min <num>:  Minimum number of genes per id to analyze (default: 3)

