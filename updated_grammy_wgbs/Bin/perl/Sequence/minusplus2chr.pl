#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
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

my $minus_plus_column = get_arg("m", 4, \%args);
my $start_column = get_arg("s", 2, \%args);
my $end_column = get_arg("e", 3, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  if ($row[$minus_plus_column] eq "-")
  {
    my $tmp = $row[$start_column];
    $row[$start_column] = $row[$end_column];
    $row[$end_column] = $tmp;
  }

  my $first = 1;
  for (my $i = 0; $i < @row; $i++)
  {
    if ($i != $minus_plus_column)
    {
      if ($first == 0) { print "\t"; }

      print "$row[$i]"; 
      $first = 0;
    }
  }

  print "\n";
}

__DATA__

minusplus2chr.pl <file>

   Converts a minus/plus location format into chr format
   (+ remain the same, - are printed from end to start)

   -m <num>: Column of minus/plus (default: 4)
   -s <num>: Column of start location (default: 2)
   -e <num>: Column of end location (default: 3)

