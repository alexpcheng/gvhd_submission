#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";

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
my $ignore_last = get_arg("i", 0, \%args);

my @STOP_CODONS = ("TAA","TAG","TGA");

while(<$file_ref>)
{
  chop;

  my @r = split(/\t/);

  my %idx;

  for my $stop (@STOP_CODONS)
  {
     for (my $i = 0; $i < length($r[1]); )
     {
	my $curr= index($r[1], $stop, $i);
#	print "curr = $curr\n";
	if ($curr >= 0 and $curr < length($r[1]) - $ignore_last)
	{
	   $idx{$curr % 3} = 1;
	   $i = $curr + 1;
	}
	else
	{
	   last;
	}
     }
  }

  if ($idx{'0'} == 1)
  {
     if ($idx{'1'} == 1)
     {
	if ($idx{'2'} != 1)
	{
	   print "$r[0]\t".substr($r[1], 2) . "\n";
	}
     }
     else
     {
	print "$r[0]\t".substr($r[1], 1) . "\n";
     }
  }
  else
  {
     print "$_\n";
  }
}

__DATA__

align_by_stop_codon.pl <stab file>

   Searches for stop codons on the input stab file and outputs the sequence with the minimal shift by which the sequence has no stop codons

   -i <num>:  Ignore last <num> basepairs
