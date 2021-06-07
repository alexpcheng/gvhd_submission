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

my $kmer_length = get_arg("k", 1, \%args);
my $print_fraction = get_arg("f", 0, \%args);
my $sequence_weight_file = get_arg("wf", "", \%args);
my $ignore_characters_str = get_arg("i", "", \%args);
my $print_length = get_arg("l", 0, \%args);
my $print_sum = get_arg("sum", 0, \%args);
my $precision = get_arg("p", 3, \%args);
my $reverse_complement = get_arg("rc", 0, \%args);

my %sequence_weights;
if (length($sequence_weight_file) > 0)
{
  open(SEQUENCE_WEIGHTS, "<$sequence_weight_file") or die "Could not open weights file $sequence_weight_file\n";
  while(<SEQUENCE_WEIGHTS>)
  {
    chomp;

    my @row = split(/\t/);

    $sequence_weights{$row[0]} = $row[1];
  }
}

my @ignore_characters_array = split(/\;/, $ignore_characters_str);
my %ignore_characters;
for (my $i = 0; $i < @ignore_characters_array; $i++)
{
  $ignore_characters{$ignore_characters_array[$i]} = "1";
}

my @kmers;
my %kmershash;
my %kmers2count;
my @sequence_names;

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  push(@sequence_names, $row[0]);

  my $str_length = length($row[1]);

  for (my $i = 0; $i <= $str_length - $kmer_length; $i++)
  {
    my $kmer = substr($row[1], $i, $kmer_length);
    &AddKmer($kmer, $row[0]);

    if ($reverse_complement == 1)
    {
      &AddKmer(&ReverseComplement($kmer), $row[0]);
    }
  }
}

@kmers = sort { $a cmp $b } @kmers;

print "Sequence";
foreach my $kmer (@kmers)
{
    print "\t$kmer";
}
if ($print_length == 1) { print "\tLength"; }
print "\n";

if ($print_sum == 0)
{
  foreach my $sequence_name (@sequence_names)
  {
    &PrintCounts($sequence_name);
  }
}
else
{
  &PrintCounts("Total");
}

sub AddKmer
{
  my ($kmer, $sequence_name) = @_;

  if (length($kmer) > 0)
  {
    if ($ignore_characters{$kmer} ne "1")
    {
      if (length($kmershash{$kmer}) == 0)
      {
	push(@kmers, $kmer);
	$kmershash{$kmer} = "1";
      }
    }

    if ($print_sum == 0)
    {
      $kmers2count{$kmer}{$sequence_name}++;
    }
    else
    {
      my $weight = length($sequence_weight_file) > 0 ? $sequence_weights{$sequence_name} : 1;

      $kmers2count{$kmer}{"Total"} += $weight;
    }
  }
}

sub PrintCounts
{
  my ($sequence_name) = @_;

  print "$sequence_name";

  my $sum = 0;
  foreach my $kmer (@kmers)
  {
    if (length($kmers2count{$kmer}{$sequence_name}) > 0)
    {
      $sum += $kmers2count{$kmer}{$sequence_name};
    }
  }

  foreach my $kmer (@kmers)
  {
    print "\t";

    if (length($kmers2count{$kmer}{$sequence_name}) == 0)
    {
      print "0";
    }
    else
    {
      if ($print_fraction == 1)
      {
	print &format_number($kmers2count{$kmer}{$sequence_name} / $sum, $precision);
      }
      else
      {
	print $kmers2count{$kmer}{$sequence_name};
      }
    }
  }

  if ($print_length == 1)
  {
    print "\t$sum";
  }

  print "\n";
}

__DATA__

stab2sequence_counts.pl <file>

   Given a stab file, counts the number of different kmers in each sequence

   -k <num>:  The kmers to count (default: 1)

   -f:        Print the fraction rather than the counts
   -p <num>:  Precision (default: 3)

   -i <str>:  Set of characters to ignore, ";" between multiple characters (e.g., AA;TT)

   -l:        Print the length of the sequence

   -wf <str>: Weight file for sequences (use with the -sum option).
              Format: <seq name><tab><seq weight>

   -sum:      Print the total results rather than the results per sequence
   -rc:       Count each kmer towards its reverse complement as well

