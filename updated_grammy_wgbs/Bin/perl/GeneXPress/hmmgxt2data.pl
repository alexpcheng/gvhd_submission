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
while(<$file_ref>)
{
  chop;

  if (/^<GeneXPressChromosomeTrack/ and /ChromosomeHmmTrack/)
  {
    $in_hmm_gxt = 1;

    /ExperimentNameMap=[\"]([^\"]+)[\"]/;

    my @row = split(/\;/, $1);
    $num_experiments = 0;
    print "Gene";
    for (my $i = 1; $i < @row; $i += 2)
    {
      print "\t$row[$i]";
      $experiments[$i] = $row[$i];
      $num_experiments++;
    }
    print "\n";
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

    print "$row[1]";
    for (my $i = 0; $i < $num_experiments; $i++)
    {
      print "\t";
      if (length($current_data[$i]) == 0)
      {
	print "1";
      }
      else
      {
	print "$current_data[$i]";
      }
    }
    print "\n";
  }

}

print "$experiments[5]\n";

__DATA__

hmmgxt2data.pl <hmm gxt file>

   Takes an HMM track and outputs track as a data matrix

