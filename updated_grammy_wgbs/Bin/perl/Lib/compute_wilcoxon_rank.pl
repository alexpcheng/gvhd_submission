#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

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

my $column = get_arg("c", 0, \%args);
my $line_mode = get_arg("lines", 0, \%args);
my $oneTailed = get_arg("1", 0, \%args);

if (!$line_mode)
{
	while (<$file_ref>)
	{
		chomp;	
		my @row = split(/\t/);
	
		my $result;

		if (!$oneTailed)
		{
			$result = ComputeWilcoxonSumRankTest ($row[$column], $row[$column+1], $row[$column+3]);
		}
		else
		{
			$result = ComputeWilcoxonSumRankTestOneTailed ($row[$column], $row[$column+1], $row[$column+3]);		
		}
		
		print join ("\t", @row) . "\t$result\n";
	}
}
else 
{
	while (<$file_ref>)
	{
		chomp;	
		my @row = split(/\t/);
	
		my $n1=0;
		my $n2=0;
		my $total1 = 0;
		my $total2 = 0;
		
		my $linelen = @row;
		
		for (my $i = 1; $i < $linelen; $i++)
		{
			my $item = $row[$i];
						
			if ($item eq "1")
			{
				$n1++;
				$total1 += $i;
			}
			else
			{
				if ($item eq "0")
				{
					$n2++;
					$total2 += $i;
				}
				else
				{
					print STDERR "compute_wilcoxon_rank: Could not recognize item \"$item\". The two classes should be \"1\" and \"0\".\n";
					exit;
				}
			}
		}

		my $result;
		
		if ( ($n1==0) || ($n2==0) )
		{
			$result = 1;
		}
		else
		{
			if (!$oneTailed)
			{
				$result = ComputeWilcoxonSumRankTest ($n1, $n2, $total2);
			}
			else
			{
				$result = ComputeWilcoxonSumRankTestOneTailed ($n1, $n2, $total2);		
			}
		}
		print "$row[0]\t$n1\t$n2\t$total1\t$total2\t$result\n";
	}
}



__DATA__

compute_wilcoxon_rank.pl <file>

	Compute the Wilcoxon-Mann-Whitney Rank Test for the values given in
	four columns of the file. The result is added as the last column.
	
	Columns are number of items in sample 1, number of items in sample 2,
	total ranks for items in sample 1 and total ranks for items in sample 2.
	
	-c <num>       Number of first column where the data is found (default: 0)
	
	-lines         If specified, then each line is assumed to include the actual
	               ordered elements of the two samples. The script then calculates
	               their number, their ranks and prints the number of items in sample 1,
	               number of items in sample 2, total ranks of items in sample 1 and
	               total ranks for items in sample 2 followed by the resulting p-value.
	               
	               The line contains an ID followed by the actual items separated by tabs.
	               
	 -1            One-tailed test (default: 2-tailed)
	 
	 

