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

my $in_hmm_gxt = 0;
my @experiments;
my $num_experiments;
my $previous_chromosome = "";
my $previous_location = "";
my @previous_data;
while(<$file_ref>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/ and /ChromosomeHmmTrack/)
  {
    $in_hmm_gxt = 1;

    /ExperimentNameMap=[\"]([^\"]+)[\"]/;

    my @row = split(/\;/, $1);
    $num_experiments = 0;
    for (my $i = 1; $i < @row; $i += 2)
    {
	$experiments[$i] = $row[$i];
	$num_experiments++;
    }
  }
  elsif (/^<\/GeneXPressChromosomeTrack/)
  {
    $in_hmm_gxt = 0;
  }
  elsif ($in_hmm_gxt == 1)
  {
    my @row = split(/\t/);

    my @current_data;

    for (my $i = 4; $i < @row; $i++)
    {
	my @row1 = split(/\;/, $row[$i]);
	if ($row1[1] == 0) { $current_data[$row1[0]] = 2; }
	elsif ($row1[1] == 1) { $current_data[$row1[0]] = 0; }
	#print STDERR "@row1  --- current_data[$row1[1]] = $current_data[$row1[$i]]\n";
    }
    for (my $i = 0; $i < $num_experiments; $i++)
    {
	if (length($current_data[$i]) == 0) { $current_data[$i] = 1; }
    }

    #print STDERR "$previous_location";
    #for (my $i = 0; $i < $num_experiments; $i++)
    #{
	#print STDERR "\t$previous_data[$i]";
    #}
    #print STDERR "\n";
    #print STDERR "$row[1]";
    #for (my $i = 0; $i < $num_experiments; $i++)
    #{
    #    print STDERR "\t$current_data[$i]";
    #}
    #print STDERR "\n";

    if ($row[0] eq $previous_chromosome)
    {
	my @joint_data;
	for (my $i = 0; $i < $num_experiments; $i++)
	{
	    $joint_data[$current_data[$i]][$previous_data[$i]]++;
	}

	print "$row[1]\t$previous_location";
	for (my $i = 0; $i < 3; $i++)
	{
	    for (my $j = 0; $j < 3; $j++)
	    {
		if (length($joint_data[$i][$j]) == 0) { $joint_data[$i][$j] = 0; }
		print "\t$joint_data[$i][$j]";
	    }
	}
	print "\n";
    }

    @previous_data = @current_data;
    $previous_chromosome = $row[0];
    $previous_location = $row[1];
  }

}

print "$experiments[5]\n";

__DATA__

hmmgxt2counts.pl <hmm gxt file>

   Takes an HMM track and outputs cpd counts for pairs of neighboring genes

