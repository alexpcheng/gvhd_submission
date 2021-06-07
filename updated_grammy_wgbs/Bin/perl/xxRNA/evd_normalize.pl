#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

#use Statistics::Distributions;

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
my $params_fn = get_arg("f", "", \%args);

if ($params_fn eq "") { die ("Must supply parameters file using the -f flag.\n"); }

open (PARAMFILE, $params_fn) or die ("Could not find params file '$params_fn'.\n");

my $text = <PARAMFILE>; chomp ($text); my @mu    = split ("\t", $text);
   $text = <PARAMFILE>; chomp ($text); my @sigma = split ("\t", $text);

close (PARAMFILE);

print STDERR "Read mu:    $mu[0], $mu[1], $mu[2]\n";
print STDERR "Read sigma: $sigma[0], $sigma[1], $sigma[2]\n";

while (<$file_ref>)
{
	chomp;

	my ($id_1, $id_2, $score, $L_1, $L_2) = split("\t");

	if ($L_1 > $L_2)
	{
		my $tmp = $L_1;
		$L_1 = $L_2;
		$L_2 = $tmp;
	}
	
	my $m = $mu[0] + $mu[1] * $L_1 + $mu[2] * $L_2;
	my $s = $sigma[0] + $sigma[1] * $L_1 + $sigma[2] * $L_2;
	if ($s < 0) {
	  print "$id_1\t$id_2\t0\n";
	  print STDERR "Warning!! negaitve sigma (Sigma=$s, $id_1, $id_2)\n";
	}
	else {
	  my $z = ($score - $m) / $s;
	  #my $cdf = exp(-1*exp(-1*$z));
	  my $cdf = 1 - exp( -exp($z) );

	  print "$id_1\t$id_2\t$cdf\n";
	}
}




__DATA__

evd_normalize.pl <file>

	Takes a list of scores in the format
	<ID1> <ID2> <SCORE> <LENGTH_1> <LENGTH_2>
	
	and output the cdf of each point based on extreme value distribution whose
	parameters are given as a linear formula from the given file (-f flag).
	
	The parameters file contains a line for the mu and sigma parameters in the
	form a0, a1, a2 such that for lengths L1 and L2 (L1<L2) the resulting 
	evd parameters are:
	
	mu = a0 + L1*a1 + L2*a2
	
	-f <str>	File containing the linear fit parameters
