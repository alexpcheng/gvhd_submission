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

my $matrices_file = get_arg("m", "", \%args);
my $sequences_file = get_arg("s", "", \%args);
my $sequences_list = get_arg("l", "", \%args);
my $background_order = get_arg("b", 0, \%args);

my $positions_str = `gxw2stats.pl -m $matrices_file -s $sequences_file -l $sequences_list -b $background_order -t WeightMatrixPositions`;
my @positions = split(/\n/, $positions_str);
my $prev_key = "";
my $sequence_num = 1;
foreach my $position (@positions)
{
    my @row = split(/\t/, $position);

    my $key = "$row[0] $row[1]";

    if ($key ne $prev_key)
    {
	$sequence_num = 1;
    }

    print "$row[1]\t$row[0] $sequence_num\t$row[2]\t$row[3]\t$row[0]\t$row[4]\n";

    $prev_key = $key;
    $sequence_num++;
}

__DATA__

gxw2position_feature_gxt.pl <gxw file>

   Takes a gxw file and a sequence fasta file and finds
   all positions of the matrices above the background
   Output is a feature gxt file

   NOTE: Provides the tab delimited data for a feature gxt
         but you still need to run tab2feature_gxt.pl to get 
         a Genomica track file

   -m <str>: matrices file (gxw format)
   -s <str>: sequences file (fasta format)
   -l <str>: use only these sequences from the file <str> (default: use all sequences in fasta file)
   -b <num>: background order (default: 0)

