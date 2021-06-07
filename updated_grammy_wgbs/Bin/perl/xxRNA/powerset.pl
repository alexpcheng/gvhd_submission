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

my $delim = get_arg("delim", "\t", \%args);

my @elements;

while (<$file_ref>)
{
	chomp;
	
	push @elements, $_;
}

print STDERR "Found " . scalar (@elements) . " elements.\n";


my @ps = powerset(@elements);
my $id = 0;

foreach my $aref (@ps) {
	foreach my $aref2 (@$aref)
	{
		my $found = 0;
		
		foreach my $elem (@$aref2)
		{
			if ($elem ne "")
			{
				if ($found)
				{
					print "$delim$elem";
				}
				else
				{
					print "$id\t$elem";
					$found = 1;
				}
			}
	    }
	    if ($found)
	    {
	    	print "\n";
	    }
	    $id++;
	}
} 


sub powerset {
  return [[]] if @_ == 0;
  my $first = shift;
  my $pow = &powerset;
  [ map { [$first, @$_ ], [ @$_] } @$pow ];
}



__DATA__

powerset.pl <file>

	Takes a list of elements (each element in its own line) and creates
	the powerset (all possible combinations of elements). The empty set
	is omitted.
	
	Each set is given an ID (counter) followed by the elements (separated
	by the delimiter).

	-delim <str>	Use delimiter (default: tab)