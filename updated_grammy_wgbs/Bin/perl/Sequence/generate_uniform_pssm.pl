#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $name = get_arg("n", "Background", \%args);
my $num_pos = get_arg("l", 1, \%args);


print "<WeightMatrices>\n";
print "<WeightMatrix Name=\"$name\" Type=\"PositionSpecific\" Order=\"0\">\n";
for (my $i = 1; $i <= $num_pos; $i++)
{
  print "\t<Position Weights=\"0.25;0.25;0.25;0.25\"></Position>\n";
}
print "</WeightMatrix>\n";
print "</WeightMatrices>\n";

__DATA__

generate_uniform_pssm.pl <file>

   Generates uniform PSSM of a given length

   -n <str>:     (Name default Background)
   -l <num>:     Length = num of positions (default: 1)
