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
my $window = get_arg("w", 100, \%args);
my $na_string = get_arg("na", "-1000", \%args);
my $report_all = get_arg("all", 0, \%args);


my $n;
my @lines;

while(<STDIN>){
	chomp;
	
	$lines[$n++] = $_;
}


for (my $start=0; $start < ($n - $window + 1); $start++)
{
	my $mean_a;
	my $mean_b;
	my $sum_sq_a;
	my $sum_sq_b;
	my $sum_coproduct;

	my $i;
	
	# print STDERR "\nWindow start=$start\n";
	
	for ($i=0; $i < $window; )
	{
		my @line=split /\t/, $lines[$start+$i];

		#print STDERR "\t$i\t$line[$colA]\t$line[$colB]\n";
		
		if($i == 0){
			$mean_a=$line[$colA];
			$mean_b=$line[$colB];
			$i=1;
			$sum_sq_a=0;
			$sum_sq_b=0;
			$sum_coproduct=0;
		}
		else
		{
			$i++;
			my $sweep=($i-1)/$i;
			my $delta_a=$line[$colA]-$mean_a;
			my $delta_b=$line[$colB]-$mean_b;
			$sum_sq_a+=$delta_a*$delta_a*$sweep;
			$sum_sq_b+=$delta_b*$delta_b*$sweep;
			$sum_coproduct+=$delta_a*$delta_b*$sweep;
			$mean_a+=$delta_a/$i;
			$mean_b+=$delta_b/$i;
		}	
	}
	
	if ($sum_sq_a * $sum_sq_b == 0)
	{
		if ($report_all)
		{
			print $lines[$start] . "\t$na_string\n";
		}
	}
	else
	{
		print $lines[$start] . "\t" . (($sum_coproduct/$i)/(sqrt($sum_sq_a/$i)*sqrt($sum_sq_b/$i))) . "\n";
	}
}



__DATA__

compute_local_correlation.pl


  -A <num>:      column of first series (zero-based) (default: 0)
  -B <num>:      column of second series (zero-based) (default: 1)

  -all    :      Report all results, even those which are non-computable
                 (sum of squared values is zero)

  -na     :      String to print out when non-computable value is met
                 (default: -1000)

