#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
 print STDOUT <DATA>;
 exit;
}

my %args = load_args(\@ARGV);

my $start = get_arg("s", 1, \%args);
my $end = get_arg("e", 100, \%args);
my $step = get_arg("step", 1, \%args);
my $amount_of_numbers = get_arg("n", "", \%args);
my $pad_zeros = get_arg("z", "", \%args);

my $sign=1;
if ($step<0) { $sign=-1 }

if ($amount_of_numbers ne ""){
  $end=$start+$step*($amount_of_numbers-1);
}

for (my $i = $start; $sign*$i <= $sign*$end; $i += $step)
{
  if ($pad_zeros eq ""){
      print "$i\n";
  }
  else{
    print sprintf("%.".$pad_zeros."d",$i),"\n";
  }
}

__DATA__

numgen.pl <file>

   Generates a set of numbers

   -s <num>:    Start number to generate (default: 1)
   -e <num>:    End number to generate (default: 100)
   -step <num>: Step (default: 1)
   -n <num>:    Amount of numbers to generate (instead of specifying end number)
   -z <num>:    Pad with zeros so number has at least this amount of digits.
                (used only with positive integers)
