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

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $cycles = &ComputeSynthesisCycles($row[1]);

  print "$row[0]\t$cycles\n";
}

__DATA__

compute_synthesis_cycles.pl <stab file>

   Compute the number of synthesis cycles based on the rule of synthesizing 3'->5' in A,C,G,T cycles

