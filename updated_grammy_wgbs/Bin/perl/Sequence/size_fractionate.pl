#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


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
my $min = get_arg("min", 1, \%args);
my $max = get_arg("max", 1000, \%args);
my $std = get_arg("std", 0, \%args);

while (<$file_ref>)
{
	chomp;

	my ($id, $sequence) = split("\t");
	my $length = length ($sequence);
	
	if ($std)
	{
		my $rnum = gaussian_rand()*$std;
		$length += $rnum;
	}
	
	if (($length <= $max) && ($length >= $min))
	{
		print "$id\t$sequence\n";
	}
}

#######
sub gaussian_rand {
    my ($u1, $u2);  # uniformly distributed random numbers
    my $w;          # variance, then a weight
    my ($g1, $g2);  # gaussian-distributed numbers

    do {
        $u1 = 2 * rand() - 1;
        $u2 = 2 * rand() - 1;
        $w = $u1*$u1 + $u2*$u2;
    } while ( $w >= 1 );

    $w = sqrt( (-2 * log($w))  / $w );
    $g2 = $u1 * $w;
    $g1 = $u2 * $w;
    # return both if wanted, else just one
    return wantarray ? ($g1, $g2) : $g1;
}

__DATA__

size_fractionate.pl

	Simulate size fractioning of nucleotide fragments. Any sequence within the given
	size (length) limits will be included in the output STAB.
	
	Gaussian noise can be applied to simulate the inclusion of fragments that are either
	too short or too long, or the exclusion of fragments that should theoretically be
	included.
	
	Parameters:
	              
		-min <num> Probability of base substitution (default: 1).
		-max <num> Probability of base insertion (default: 1000).
		
		-std <num> Standard deviation of the Gaussian noise. (default: 0 -- no noise).
		
