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

my $oligo_concentration = get_arg("o", 0.25, \%args);
my $salt_concentration = get_arg("s", 50, \%args);
my $TMMethod = get_arg("tm", "Nimblegen", \%args);

$oligo_concentration *= 1e-6;
$salt_concentration *= 1e-3;

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  my $melting_temperature = &ComputeMeltingTemperature($row[1], $TMMethod, $salt_concentration, $oligo_concentration);

  print "$row[0]\t$melting_temperature\n";
}

__DATA__

stab2length.pl <file>

   Given a stab file, output the TM of each sequence

   -o:        Oligo concentration in micrograms (default: 0.25ug)
   -s:        Salt concentration in milli-molar (default: 50mM)

   -tm <str>: TM Method to use (IDTDNA/SIGMA/Nimblegen) (default: Nimblegen)

