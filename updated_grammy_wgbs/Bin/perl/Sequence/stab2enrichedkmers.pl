#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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

my $kmer_baseline = get_arg("kb", 1, \%args);
my $kmer = get_arg("k", 2, \%args);
my $ignore_characters_str = get_arg("i", "", \%args);
my $precision = get_arg("p", 3, \%args);
my $reverse_complement = get_arg("rc", 0, \%args);

my $r = int(rand(1000000));

open(OUTFILE, ">tmp_$r");
while(<$file_ref>)
{
  chomp;

  print OUTFILE "$_\n";
}
close(OUTFILE);

my %low_counts = &Count($kmer_baseline);
my %high_counts = &Count($kmer);

my @kmers;
foreach my $k (keys %high_counts)
{
  push(@kmers, $k);

  #print STDERR "K=$k\n";
}
@kmers = sort { $a cmp $b } @kmers;

foreach my $k (@kmers)
{
  my $first_lower_k = substr($k, 0, $kmer_baseline);
  my $expected_prob = $low_counts{$first_lower_k};
  if (length($low_counts{$first_lower_k}) == 0) { die "Could not find lower order counts for kmer '$first_lower_k'\n"; }

  for (my $i = 1; $i <= $kmer - $kmer_baseline; $i++)
  {
    my $second_lower_k_given = substr($k, $i, $kmer_baseline - 1);
    my $second_lower_k_var = substr($k, $i + $kmer_baseline - 1, 1);

    my $given = 0;
    $given += $low_counts{"${second_lower_k_given}A"};
    $given += $low_counts{"${second_lower_k_given}C"};
    $given += $low_counts{"${second_lower_k_given}G"};
    $given += $low_counts{"${second_lower_k_given}T"};
    my $given_prob = $low_counts{"${second_lower_k_given}$second_lower_k_var"} / $given;
    $expected_prob *= $given_prob;
  }

  my $ratio = &format_number($high_counts{$k} / $expected_prob, $precision);

  #print STDERR "k=$k first=$first_lower_k second_given=$second_lower_k_given second=$second_lower_k_var first_prob=$low_counts{$first_lower_k} given=$given given_prob=$given_prob exp=$expected_prob ratio=$ratio\n";

  print "$k\t$ratio\n";
}

`rm -f tmp_$r`;

#-----------------------------------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------------------------------
sub Count
{
  my ($kmer) = @_;

  my $counts_str = `stab2sequence_counts.pl tmp_$r -sum -k $kmer -f -rc $reverse_complement -p 10 | cut -f2- | transpose.pl`;
  my @counts_array = split(/\n/, $counts_str);
  my %counts;
  foreach my $count (@counts_array)
  {
    my @row = split(/\t/, $count);

    $counts{$row[0]} = $row[1];

    #print STDERR "counts{$row[0]} = $row[1]\n";
  }

  return %counts;
}

__DATA__

stab2enrichedkmers.pl <file>

   Given a stab file, finds kmers that are enriched over/below expected
   by the distribution of lower order kmers

   -kb <num>: The kmer baseline (default: 1)
   -k <num>:  The kmer to end at (default: 2)

   -p <num>:  Precision (default: 3)

   -i <str>:  Set of characters to ignore, ";" between multiple characters (e.g., AA;TT)

   -rc:       Count each kmer towards its reverse complement as well

