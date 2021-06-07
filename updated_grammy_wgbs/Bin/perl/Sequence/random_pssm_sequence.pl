#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $num_sequences = get_arg("n", 10, \%args);
my $id = get_arg("id", "", \%args);
my $alphabet = get_arg("a", "ACGT", \%args);

if (length($alphabet) ne 4)
{
	print STDERR "Alphabet must be of length 4\n";
	exit;
}

my @pssm;
my @lendist;

while(<$file_ref>)
{
	chomp;
	my @row = split(/\t/);
	
	my $pos = $row[0] - 1;
	
	$pssm[$pos][0] = $row[1];
	$pssm[$pos][1] = $row[2];
	$pssm[$pos][2] = $row[3];
	$pssm[$pos][3] = $row[4];
	
	$lendist[$pos] = $row[5];
}		


for (my $i = 1; $i <= $num_sequences; $i++)
{
    print $id . $i . "\t";

	my $sequence_length = weighted_random (@lendist);
	
    for (my $j = 0; $j < $sequence_length; $j++)
    {
		my $r = weighted_random (@{$pssm[$j]});
		print substr($alphabet, $r, 1);
    }

    print "\n";
}

###############################

sub weighted_random 
{
	my @weights = @_;
	my @cumsum;
	
	# print STDERR "Weights=" . join (",", @weights) . "\n";
	my $total = 0;
	my $bins = @weights;

	# print STDERR "Bins=$bins\n";

	for (my $i=0; $i<$bins; $i++)
	{
		$total = $total + $weights[$i];
		$cumsum[$i] = $total;	
	}
	
	# print STDERR "Cumsum=" . join (",", @cumsum) . "\n";

	my $r = $total * rand(1);
	
	for (my $i=0; $i<$bins; $i++)
	{
		if ($cumsum[$i] > $r)
		{
		#	print STDERR "selected $r --> $i\n";
			
			return $i;
		}
	}
}


__DATA__

random_pssm_sequences.pl <file>

   Generates random sequences based on the given PSSM and length 
   distribution. The format of the input file is 
   
      <counter> <p(A)> <p(C)> <p(G)> <p(T or U)> <p(length=counter)> 

   -n <num>:     Number of sequences to generate (default: 10)
   -a <str>:     Alphabet (default: ACGT)
   -id <str>:	 Sequence name prefix (default: '')

