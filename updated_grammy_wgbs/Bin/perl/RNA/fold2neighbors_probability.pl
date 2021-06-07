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
my $pc = get_arg("pc", 0.2, \%args);
my $pw = get_arg("pw", 0, \%args);

my $pns = $pc * $pw;
my @total_term = ();

while (<$file_ref>)
{
	chomp;

	my ($id, $fold) = split("\t");
	my $length = length ($fold);
	
	print STDERR "Processing $id ... ";

	print "$id\t$id\t1\t";
	print $length;
	print "\tneighbors\t1\t1\t";
		
	for (my $i=0; $i<$length; $i++)
	{
		if (substr ($fold, $i, 1) eq ".")
		{
			$total_term[$i] = -1;
			next;
		}
		
		$total_term[$i] = calc_term ($fold, $i, $min, $max, $pc, $pns, 1) + calc_term ($fold, $i, $min, $max, $pc, $pns, -1);

		#print STDERR "Total term for $i = $total_term[$i]\n";		
	}

	
	for (my $dump=0; $dump<$length-1; $dump++)
	{
		print $total_term[$dump];
		print ";";
	}
	
	print $total_term[$length-1];
	print "\n";

	print STDERR "   OK.\n";
}	


######
sub calc_term 
{
	my ($fold, $i, $min, $max, $pc, $pns, $direction) = @_;
	
	my $total_term = 0;
	
	for (my $j=$min; $j<=$max; $j++)
	{
	
		#if ( (($direction == 1) && ($i+$j > length ($fold))) || (($direction == -1) && ($i<$j)) )
		#{
	#		next;
	#	}
		
		my $term = 1;
		
		# All bases to j must be uncleaved
		for (my $k=1; $k<$j; $k++)
		{
			if (substr ($fold, $i+($k * $direction), 1) ne ".")
			{
				$term *= (1-$pc);
			}
			else
			{
				$term *= (1-$pns);
			}
		}
		
		# Base j must be cleaved
		if (substr ($fold, $i+($j * $direction), 1) ne ".")
		{
			$term *= $pc;
		}
		else
		{
			$term *= $pns;
		}
		
		#print STDERR "Term for $j = $term; ";
		$total_term += $term;
		
	}
	
	return $total_term;
}

__DATA__

fold2neighbors_count.pl

	Given a file of the format <ID> <Fold_string> where fold_string is the parentheses folding
	representation, outputs a chv at a one-bp resolution representing for each base the number
	of bases at distance min-max which are double-stranded.
	
	parameters:
	
	-min <num>    Minimal distance (default: 17)
	-max <num>    Maximal distance (default: 35)
