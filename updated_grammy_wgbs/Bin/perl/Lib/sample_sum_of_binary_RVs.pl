#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $col = get_arg("c", 0, \%args);
my $n = get_arg("n", 1000000, \%args);#number of samples
my $cumulative = get_arg("oc", "", \%args);#number of samples

my @prob;
while(<STDIN>){
  chomp;
  my @a=split/\t/;
  push @prob,$a[$col];
}


my $psize=scalar(@prob);

my @dist;
for (my $j=0;$j<=$psize;$j++){
  $dist[$j]=0;
}

for (my $i=0;$i<$n;$i++){
  my $sum=0;
  for (my $j=0;$j<$psize;$j++){
    if(rand()<$prob[$j]){
      $sum++;
    }
  }
  $dist[$sum]++;
}


if ($cumulative){
  my $probsum=0;
  for (my $j=$psize-1;$j>=0;$j--){
    $dist[$j]+=$probsum;
    $probsum=$dist[$j];
  }
}

for (my $j=0;$j<=$psize;$j++){
    print "$j\t",$dist[$j]/$n,"\n";
}


__DATA__


sample_sum_of_binary_RVs.pl

given a list of probabilities (parameters for independent binary RVs), sample
instances from the distribution of their sum.
note: for large numbers you might wish to use Hoeffding/Chernoff bounds instead
of random sampling.

  -n <num>:      number of random instances generate (default 1000000)
  -c <num>:      column in which the probabilities appear in the input file (default 0)
  -oc:           output cumulative distribution


