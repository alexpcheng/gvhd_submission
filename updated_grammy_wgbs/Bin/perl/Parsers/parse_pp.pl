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
my $location_type = get_arg("t", "Type", \%args);

my $chromosome = "";
my $start;
my $values;
my $length = 1;
my $jump;
my $counter = 0;
my $line_counter = 1;

while(<$file_ref>)
{
  chop;

  if (/fixedStep chrom=([^ ]+) start=([^ ]+) step=([^ ]+)/)
  {
    print STDERR "Working on region: $_\n";
    my $next_chromosome = $1;
    my $next_start = $2;
    my $next_jump = $3;

    if (length($chromosome) > 0)
    {
      my $end = $start + $counter - 1;
      print "$chromosome\t$line_counter\t$start\t$end\t$location_type\t1\t$jump\t$values\n";
    }

    $chromosome = $next_chromosome;
    $start = $next_start;
    $jump = $next_jump;
    $values = "";
    $line_counter++;
    $counter = 0;
  }
  else
  {
    if (length($values) > 0)
    {
      $values .= ";";
    }

    $values .= $_;

    $counter++;
  }
}

if (length($chromosome) > 0)
{
  my $end = $start + $counter - 1;
  print "$chromosome\t$line_counter\t$start\t$end\t$location_type\t1\t$jump\t$values\n";
}


__DATA__

parse_pp.pl <file>

   Parse a UCSC pp file format into a chv file

   -t <str>: Adds <str> as the type of each row in the resulting chv file (default: Type)

