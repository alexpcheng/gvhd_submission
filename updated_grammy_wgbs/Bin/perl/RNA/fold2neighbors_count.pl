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
my $min = get_arg("min", 17, \%args);
my $max = get_arg("max", 35, \%args);

while (<$file_ref>)
{
	chomp;

	my ($id, $fold) = split("\t");
	my $length = length ($fold);
	my @counts = ();
	
	print STDERR "Processing $id ... ";

	print "$id\t$id\t1\t";
	print $length;
	print "\tneighbors\t1\t1\t";
	
	$fold = $fold . $max x ".";

	for (my $i=0; $i<$length; $i++)
	{
		if (substr ($fold, $i, 1) eq ".")
		{
			$counts[$i] = -1;
			next;
		}
		
		for (my $j=$min; $j<=$max; $j++)
		{
			if (substr ($fold, $i+$j, 1) ne ".")
			{
				$counts[$i]++;
				$counts[$i+$j]++;
			}
		}
	}
	
	for (my $dump=0; $dump<$length-1; $dump++)
	{
		print int ($counts[$dump]) . ";";
	}
	
	print int ($counts[$length-1]) . "\n";

	print STDERR "   OK.\n";
}	


__DATA__

fold2neighbors_count.pl

	Given a file of the format <ID> <Fold_string> where fold_string is the parentheses folding
	representation, outputs a chv at a one-bp resolution representing for each base the number
	of bases at distance min-max which are double-stranded.
	
	parameters:
	
	-min <num>    Minimal distance (default: 17)
	-max <num>    Maximal distance (default: 35)
