#!/usr/bin/perl

use strict;
use Switch;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $RNA_length = get_arg("l", 1000, \%args);
my $pulls = get_arg("n", 2000, \%args);
my $runs = get_arg("runs", 1000, \%args);

my @RNA;
my @hit_stats = ();
my $total_hits;

for (my $cur_run = 0; $cur_run < $runs; $cur_run++)
{
	@RNA = ();
	$total_hits = 0;
	
	for (my $cur_pull = 0; $cur_pull < $pulls; $cur_pull++)
	{
		# First evidence
		
		my $hit_base = rand ($RNA_length-1);
		if (not $RNA[$hit_base])
		{
			$RNA[$hit_base] = 1;
			$total_hits++;
		}

		# Second evidence
		
		my $hit_base = rand ($RNA_length-1);
		if (not $RNA[$hit_base])
		{
			$RNA[$hit_base] = 1;
			$total_hits++;
		}
	
		$hit_stats[$cur_pull] += $total_hits;
	}
}

# Print results
for (my $i = 0; $i < $pulls; $i++)
{
	print ($i+1);
	print "\t";
	print ($hit_stats[$i] / ($RNA_length * $runs));
	print "\n";
}

__DATA__

RNA_evidence_coverage.pl



