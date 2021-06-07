#!/usr/bin/perl

use strict;
use POSIX;
use Math::Random::OO::Normal;

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

my $replication_num  = get_arg("n", 1, \%args);
my $replication_std  = get_arg("s", 0, \%args);

my $prob_mutation  = get_arg("pm", 10**-5, \%args);
my $prob_insertion = get_arg("pi", 0, \%args);
my $prob_deletion  = get_arg("pd", 0, \%args);


my $randomgenerator = Math::Random::OO::Normal->new($replication_num, $replication_std);

my %mutator = (
	A => 'CGT',
	G => 'ACT',
	C => 'AGT',
	T => 'ACG'
);
    
while(<$file_ref>)
{
	chop;

	(my $id, my $seq) = split(/\t/);

	my $replicates = floor($randomgenerator->next());
	my $seqlength = length($seq);
	
	print STDERR "$id\treplicates: $replicates. {M,I,D}: ";
	
	for (my $i=1; $i <= $replicates; $i++)
	{
		my $mutcounter=0;
		my $inscounter=0;
		my $delcounter=0;
		
		print $id . "." . $i . "\t";
		
		for (my $j=0; $j<$seqlength; $j++)
		{
			if (rand() < $prob_mutation)
			{
				print substr($mutator{substr($seq, $j, 1)}, int(rand(3)), 1);
				$mutcounter++;
			}
			elsif (rand() < $prob_insertion)
			{
				print substr("ACGT", int(rand(4)), 1);
				$inscounter++;
			}
			elsif (rand() < $prob_deletion)
			{
				$delcounter++;
			}
			else
			{
				print substr($seq, $j, 1);
			}
		}
		print STDERR "{$mutcounter,$inscounter,$delcounter}, ";
		print "\n";
	}
	print STDERR "\n";
}

	
__DATA__

mutate_virus.pl <file>

   Given a stab file, mutate each sequence in a predefined way, generating a predefined number
   of offspring

   -n <num>:     Number of times to mutate each sequence (default: 1)
   -s <num>:     Standard deviation of number of sequences (default: 0)

   -pm <num>:    Probability of a point mutation in each base (default: 10^-5)
   -pi <num>:    Probability of a deletion in each base (default: 0)
   -pd <num>:    Probability of an insertion in each base (default: 0)
