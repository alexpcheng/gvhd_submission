#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

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

my $size1 = get_arg("size1", 0, \%args);
my $size2 = get_arg("size2", 0, \%args);
my $res_d_stat = get_arg("max_diff", -1, \%args);
my $precision = get_arg("p", 4, \%args);

if ($size1 == 0 or $size2 == 0 or $res_d_stat < 0)
{
   print STDERR "Error: wrong parameters\n";
   exit 1;
}

my $res = KolmogorovSmirnovProbability($size1, $size2, $res_d_stat);

print format_number($res, $precision)."\n";

__DATA__

compute_kolmogorov_smirnov_probability.pl <file>

     -size1 <num>   :  Size of first distribution set
     -size2 <num>   :  Size of second distribution set
     -max_diff <num>:  Maximal difference between the two sets cumulative distribution in a certain point.

     -p <num>       :  Precision (number of digits after decimal point) for printouts (default: 4)
 
 
