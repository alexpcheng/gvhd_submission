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
my $print_seq = get_arg("s", 0, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $cycles = &ComputeNimblegenCycles($row[1]);

  if ($print_seq > 0)
  {
     print "$row[0]\t$row[1]\t$cycles\n";
  }
  else
  {
     print "$row[0]\t$cycles\n";
  }
}

__DATA__

stab2nimblegen_cycles.pl <stab file>

   Compute the number of cycles required for a sequence based on nimblegen rule.

   -s      : Print also the sequence

