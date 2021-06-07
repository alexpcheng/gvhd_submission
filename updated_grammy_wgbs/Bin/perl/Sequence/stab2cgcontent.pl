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

my $window_size = get_arg("w", 100, \%args);
my $window_jump = get_arg("j", 50, \%args);
my $all_sequence = get_arg("all", 0, \%args);

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  my $sequence_length = length($row[1]);

  if ($all_sequence == 1)
  {
    print "$row[0]\t$row[0]\t0\t";
    print ($sequence_length - 1);
    print "\tGC\t$sequence_length\t1\t";
    print &ComputeGCFraction($row[1], 0);
  }
  else
  {
    my $end = $window_jump * int(($sequence_length - $window_size) / $window_jump) + $window_size - 1;
    print "$row[0]\t$row[0]\t0\t$end\tGC\t$window_size\t$window_jump\t";

    my $prev_window_start = -1;
    my $prev_gc_count = 0;
    for (my $i = 0; $i <= $sequence_length - $window_size; $i += $window_jump)
    {
      my $gc_count;
      my $overlap = $prev_window_start + $window_size - $i;
      if ($prev_window_start >= 0 and $overlap > 0)
      {
	$gc_count = $prev_gc_count - &ComputeGCFraction(substr($row[1], $prev_window_start, $window_size - $overlap), 1);
	$gc_count += &ComputeGCFraction(substr($row[1], $i + $overlap, $window_size - $overlap), 1);
      }
      else
      {
	$gc_count = &ComputeGCFraction(substr($row[1], $i, $window_size), 1);
      }

      if ($i > 0) { print ";"; }
      print &format_number($gc_count / $window_size, 3);

      $prev_window_start = $i;
      $prev_gc_count = $gc_count;
    }
  }

  print "\n";
}

__DATA__

stab2cgcontent.pl <file>

   Computes the C/G content of each sequence at a specified window
   Output is a chv file (one row per sequence)

   -w <num>: Window width (default: 100)
   -j <num>: Window jump (distance between windows, default: 50)

   -all:     Do not go by windows, simply print the C/G content of each entire sequence

