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
my $reverse = get_arg("r", 0, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/, $_, 5);

  print "$row[0]\t$row[1]\t";

  if ($reverse == 0)
  {
    print ($row[2] + 1);
    print "\t";
    print ($row[3] + 1);

    if (length($row[4]) > 0)
    {
      print "\t$row[4]";
    }
  }
  else
  {
    print ($row[2] - 1);
    print "\t";
    print ($row[3] - 1);

    if (length($row[4]) > 0)
    {
      print "\t$row[4]";
    }
  }
    
  print "\n";
}

__DATA__

chr_zero2one.pl <file>

   Converts a chr file from zero based to one based coordinates

   -r: reverse, convert from one based to zero based coordinates

