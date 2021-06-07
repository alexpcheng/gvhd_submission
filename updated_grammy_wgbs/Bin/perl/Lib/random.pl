#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $max_failures = 1000;

my %args = load_args(\@ARGV);

my $user = get_arg("u", `whoami`, \%args);
chomp($user);

my $number = get_arg("n", 1, \%args);
my $integer = get_arg("i", 0, \%args);
my $seed_in = get_arg("d", "", \%args);
my $min_d = get_arg("min_d", "", \%args);

my $seed = $seed_in ne "" ? $seed_in : time()^($$+($$<<15));
srand($seed);

my @chosen=();
my $fail = 0;

for (my $i = 1; $i <= $number;)
{
	my $r = rand();
	my $too_close = 0;
	
	if($integer > 0)
	{
		$r = int($r * $integer) + 1;
	}

	if ($min_d ne "")
	{	
		my $chosen_size = @chosen;
		for (my $j = 0; $j < $chosen_size; $j++)
		{
			if (abs ($chosen[$j] - $r) <= $min_d)
			{
				$too_close = 1;
				$fail++;
				
				if ($fail++ > $max_failures)
				{
					print STDERR "Too many attempts to choose at distance $min_d.\nQuitting.\n";
					exit (0);
				}
				last;
			}
		}
	}
	
	if (!$too_close)
	{
		print "$r\n";
		$i++;
		$fail = 0;
		if ($min_d ne "")
		{
			push (@chosen, $r);
		}
	}
}


exit(0);


__DATA__
syntax: random.pl [OPTIONS]

Produce a list of random numbers

-d <seed>:      Make random numbers deterministic (default is non-deterministic).  For every
                value of SEED, the same random numbers will be returned.

-n <num>:       Print <num> random numbers to standard output (default is 1).

-i <num>:       Produce random number(s) between 1 and <num> inclusive (default produces
                reals between 0 and 1, non-inclusive).

-min_d <dist>:  Make sure the numbers are at least <dist> apart. Use -min_d 0 to 
                generate unique numbers.
                
                Warning: very inefficient when min_d or n are high.
                
            