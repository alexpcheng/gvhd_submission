#!/usr/bin/perl

use strict;
use File::Basename;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $n = get_arg("n", "10", \%args);
my $r = get_arg("r", "1", \%args);


system ("hostname");

my $start_time = time;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($start_time);
printf "\nJob starting at %02d:%02d:%02d.\n",$hour,$min,$sec;

for (my $i = 3; $i < $n; $i++)
{
	my $isprime = 1;
	for (my $j = 2; $j < $i; $j++)
	{
		if (($i % $j) == 0)
		{
			report ("$i is not prime, as it divides by $j.\n");
			$isprime = 0;
		}
	}

	if ($isprime)
	{
		report ("$i is prime!!!\n");
	}
}

my $end_time = time;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($end_time);
printf "\nJob ended at %02d:%02d:%02d.\n",$hour,$min,$sec;

print "Total execution time " . ($end_time - $start_time) . " seconds.\n";


sub report 
{
	if ($r)
	{
		print $_[0];
	}
}


#-----------------------------------------------------------------------------------------
# --help 
#-----------------------------------------------------------------------------------------

__DATA__

 Syntax:         load_test.pl
 