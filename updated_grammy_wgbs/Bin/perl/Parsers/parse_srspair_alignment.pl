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

my $counter = 1;
my @sequences;
my @sequences_short;
my $status = "";
my $start = 0;
my $global_start = 0;
while(<$file_ref>)
{
  chop;

  if (/[\#] Aligned_sequences: ([0-9]+)/)
  {
    my $num_sequences = $1;
    for (my $i = 0; $i < $num_sequences; $i++)
    {
      my $line = <$file_ref>;
      chop $line;

      $line =~ /: (.*)/;

      print STDERR "$1\n";
      my $seq = $1;
      push(@sequences, $seq);

      if (length($seq) > 13)
      {
	push(@sequences_short, substr($seq, 0, 13));
      }
      else
      {
	push(@sequences_short, $seq);
      }
      
      #print STDERR "@sequences_short\n";
    }
  }
  #elsif (length($sequences[0]) > 0 and /^$sequences_short[0]/)
  elsif (length($sequences[0]) > 0 and substr($_, 0, length($sequences_short[0])) eq $sequences_short[0])
  {
    my @row1 = split(/\ +/);

    my $line = <$file_ref>;

    $line = <$file_ref>;
    chop $line;
    my @row2 = split(/\ +/, $line);

    #print STDERR "$row1[0]\t$row1[2]\n";
    #print STDERR "$row2[0]\t$row2[2]\n\n";

    for (my $i = 0; $i < length($row1[2]); $i++, $global_start++)
    {
      my $char1 = substr($row1[2], $i, 1);
      my $char2 = substr($row2[2], $i, 1);

      if ($char1 eq "-")
      {
	if (length($status) > 0 and $status ne "Deletion1")
	{
	  &Print($global_start - 1);
	  $start = $global_start;
	}

	$status = "Deletion1";
      }
      elsif ($char2 eq "-")
      {
	if (length($status) > 0 and $status ne "Deletion2")
	{
	  &Print($global_start - 1);
	  $start = $global_start;
	}

	$status = "Deletion2";
      }
      elsif ($char1 eq $char2)
      {
	if (length($status) > 0 and $status ne "Match")
	{
	  &Print($global_start - 1);
	  $start = $global_start;
	}

	$status = "Match";
      }
      else
      {
	if (length($status) > 0 and $status ne "Mismatch")
	{
	  &Print($global_start - 1);
	  $start = $global_start;
	}

	$status = "Mismatch";
      }
    }
  }
}

if (length($status) > 0)
{
  &Print($global_start);
}

sub Print
{
  my ($end) = @_;

  my $status1 = $status eq "Deletion1" ? "Deletion" : ($status eq "Deletion2" ? "Insertion" : $status);
  print "$sequences[0]\t";
  print "$counter\t";
  print "$start\t";
  print "$end\t";
  print "$status1\t";
  print "1\n";
  $counter++;

  my $status2 = $status eq "Deletion1" ? "Insertion" : ($status eq "Deletion2" ? "Deletion" : $status);
  print "$sequences[1]\t";
  print "$counter\t";
  print "$start\t";
  print "$end\t";
  print "$status2\t";
  print "1\n";
  $counter++;
}

__DATA__

parse_srspair_alignment.pl <file>

   Parses a paired sequence alignment into a chr file of
   insertions/deletions/matches/mismatches

