#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $colA = get_arg("A", 0, \%args);
my $colB = get_arg("B", 1, \%args);
my $coltype = get_arg("type", '', \%args);
my $undef = get_arg("undef", 0, \%args);
my $pval = get_arg("p", 0, \%args);
my $echon = get_arg("n", 0, \%args);

my %i;
my %mean_a;
my %mean_b;
my %sum_sq_a;
my %sum_sq_b;
my %sum_coproduct;

while(<STDIN>){
  chomp;
  my @line=split /\t/;
  my $type=$line[$coltype];
  if ($coltype eq ""){
    $type=1;
  }
  if($line[$colA] ne "" and $line[$colB] ne ""){
    if(not exists $i{$type}){
      $mean_a{$type}=$line[$colA];
      $mean_b{$type}=$line[$colB];
      $i{$type}=1;
      $sum_sq_a{$type}=0;
      $sum_sq_b{$type}=0;
      $sum_coproduct{$type}=0;
    }
    else{
      $i{$type}++;
      my $sweep=($i{$type}-1)/$i{$type};
      my $delta_a=$line[$colA]-$mean_a{$type};
      my $delta_b=$line[$colB]-$mean_b{$type};
      $sum_sq_a{$type}+=$delta_a*$delta_a*$sweep;
      $sum_sq_b{$type}+=$delta_b*$delta_b*$sweep;
      $sum_coproduct{$type}+=$delta_a*$delta_b*$sweep;
      $mean_a{$type}+=$delta_a/$i{$type};
      $mean_b{$type}+=$delta_b/$i{$type};
    }
  }
}

my $r = 0;

for my $t (keys %i){
  if ($coltype ne ""){
    print "$t\t";
  }
  if (($sum_sq_a{$t} == 0) or ($sum_sq_b{$t} == 0))
  {
  	print $undef;
  }
  else
  {
  	$r = (($sum_coproduct{$t}/$i{$t})/(sqrt($sum_sq_a{$t}/$i{$t})*sqrt($sum_sq_b{$t}/$i{$t})));
  	print $r;
  }
  
  if ($pval)
  {
  	if ( ($r == 0) || ($r == 1) || ($r == -1) || ($i{$t}<3) ) 
  	{
  		print "\t0";
  	}
  	else
  	{
		my $rpos = abs ($r);
		print STDERR "r is $r\nRPOS is $rpos\n";
		
		my $f;
		my $z;
		my $p;
		
		eval 
		{
			$f = 0.5*(log((1+$rpos)/(1-$rpos)));
			$z = sqrt($i{$t}-3)*$f;
			
			$p = NormalStd2Pvalue ($z);
		};
		
		if ($@)
		{
			$p = 0;
		}
		
		print "\t$p";
	}
  }
  
  if ($echon)
  {
  	print "\t$i{$t}";
  }
  
  print "\n";
}


__DATA__

compute_correlation.pl

compute pearson correlation between two series of numbers with a single pass i.e O(n) time and O(1) memory.

  -A <num>:      column of first series (zero-based) (default: 0)
  -B <num>:      column of second series (zero-based) (default: 1)
  -type <num>:   series are divided into different types, given in column <num>.
                 correlation for each type is computed separately.

  -undef <str>:  string to print in case correlation is undefined (variance of one of the vector is zero).
                 (defualt: 0).
               
  -p:            Add a column denoting the p-value (one tailed) of the reported result.

  -n:			 Echo number of elements which went into the statistic
