#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $colA = get_arg("A", 0, \%args);
my $colB = get_arg("B", 1, \%args);

my $n = 0;
my $sum_a = 0;
my $sum_b = 0;
my $sum_sq_a = 0;
my $sum_sq_b = 0;

my @a;
my @b;

my @lines;

my $sum_coproduct = 0;

while(<STDIN>)
{
	chomp;
	$lines[$n] = $_; 
	
	my @line=split /\t/;

	$a[$n] = $line[$colA];
	$b[$n] = $line[$colB];
	
	$sum_a+=$a[$n];
	$sum_b+=$b[$n];

	$sum_sq_a+=($a[$n]*$a[$n]);
	$sum_sq_b+=($b[$n]*$b[$n]);
	
	$n++;
}

my $mean_a = $sum_a / $n;
my $mean_b = $sum_b / $n;

my $stddev_a = sqrt($sum_sq_a/$n - $mean_a*$mean_a);
my $stddev_b = sqrt($sum_sq_b/$n - $mean_b*$mean_b);

# print STDERR "sum_a = $sum_a; sum_b = $sum_b\n";
# print STDERR "sum_sq_a = $sum_sq_a; sum_sq_b = $sum_sq_b\n";
# print STDERR "std_a = $stddev_a; std_b=$stddev_b\n";

my $total_dp = 0;

for (my $i=0; $i<$n; $i++)
{
	my $z_a = ($a[$i] - $mean_a) / $stddev_a;
	my $z_b = ($b[$i] - $mean_b) / $stddev_b;

	my $dotprod = $z_a * $z_b;

	$total_dp += $dotprod;
	
	print "$lines[$i]\t$dotprod\n";
}


# print STDERR "Average: " . ($total_dp / $n) . "\n";

__DATA__

local_pearson.pl

Compute the "local" Pearson correlation between two series of numbers. The script normalizes both
vectors and then outputs the dot-product between the two normalized vectors for each position of
the vector.

  -A <num>:    column of first series (zero-based) (default: 0)
  -B <num>:    column of second series (zero-based) (default: 1)
  


