#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";
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

my $statistics_file = get_arg("s", "", \%args);
my $key_column = get_arg("k", "0", \%args);
my $data_columns = get_arg ("c", "", \%args);
my $pvalue = get_arg ("p", 0, \%args);

my $two_sided = get_arg ("two_sided", "", \%args);

my @columns_list = split(/\,/, $data_columns);

my %mean;
my %stddev;

my $nokey = 0;

open(INPUT_FILE, "<$statistics_file");
while(<INPUT_FILE>)
{
	chomp;
	
	my @row = split(/\t/);
	
	if ($row[2] eq 0)
	{
		print STDERR "compute_z_scores.pl: Key $row[0] has stddev of zero. Ignoring key.\n";
	}
	else
	{
		$mean{$row[0]} = $row[1];
		$stddev{$row[0]} = $row[2];
	}
}

print STDERR "Read " . keys (%mean) . " keys from file: ";
for my $key ( keys %mean )
{
	print STDERR "$key, ";
}

while(<$file_ref>)
{
	chomp;
	
	my @row = split(/\t/);
	
	if (exists ($mean{$row[$key_column]}))
	{
		foreach my $column (@columns_list)
		{
			my $data = $row[$column];
			$data = ($data - $mean{$row[$key_column]}) / $stddev{$row[$key_column]};
			
			if ($pvalue)
			{
			  $row[$column] = NormalStd2Pvalue($two_sided?abs($data):$data);
			}
			else
			{
			  $row[$column] = $data;
			}
		}
		
		print join ("\t", @row);
		print "\n";
	}
	else
	{
		$nokey++;
	}
}

if ($nokey)
{
	print STDERR "Warning: $nokey lines ommited, as key was not matched to statistics file.\n";
}

__DATA__

compute_z_score.pl <file>

   Takes in a file of keys and their associated means and standard deviations,
   and transfers the values in the input file to z-scores.

   Options:
     -s <str>     The file containing the statistics, in the format
                  <key> <mean> <stddev>

     -k <num>     The column where the keys are found in the input file (zero-based)


     -c <num>     Column number containing the data to be z-scored in the input file
                  (zero-based).

     -p           Print as output the pvalue of the z-score.
     -two_sided   Two-sided p-value calculation (default: one-sided)

