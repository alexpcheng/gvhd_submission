#!/usr/bin/perl

use strict;
use Math::Complex;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $cvmatrix = get_arg("cvmatrix", "", \%args);
my $expnum = get_arg("expnum",  0, \%args);
my $z_val = get_arg("z_val", 2, \%args);

my $avergaed_cv_values = `cat $cvmatrix | compute_column_stats.pl -m | tail -n 1 | cut.pl -f 2-`;

chomp($avergaed_cv_values);

my @averaged_cv = split(/\t/,$avergaed_cv_values);

my @averaged_distinguishing_ability;
for (my $i=0; $i < scalar(@averaged_cv); $i++)
{
    $averaged_distinguishing_ability[$i] = 2*$z_val / (sqrt($expnum)*$averaged_cv[$i]) ;
}

print "@averaged_distinguishing_ability\n";


__DATA__

compute_averaged_distinguishing_ability.pl

Given Z-value a cv (coefficient of variation) matrix and number of experimental repeats outputs the mean of mean differences between promoters required at each timepoint, to be able to distinguish between them with probability corresponding to the given z-value

-cvmatrix:      cv matrix
-expnum:        number of experimental repeats
-z_val:         required z_value

