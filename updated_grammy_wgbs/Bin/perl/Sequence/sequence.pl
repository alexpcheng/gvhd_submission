#!/usr/bin/perl

use strict;
use List::Util qw/shuffle/;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
my $n_input;

if (length($file) < 1 or $file =~ /^-/) 
{
	print STDOUT "ERROR: Must provide input file name.\n\n";
	print STDOUT <DATA>;
	exit;
}
else
{ 
	open(FILE, $file) or die("Could not open file '$file'.\n");
	$file_ref = \*FILE;
	
	$n_input = `wc -l $file`;
}

my %args = load_args(\@ARGV);
my $p_insert = get_arg("pi", 0, \%args);
my $p_delete = get_arg("pd", 0, \%args);
my $p_subst = get_arg("ps", 0, \%args);

my $n_requested = get_arg("n", 0, \%args);
my $oversample = get_arg("os", 0, \%args);

print STDERR "Sequencing from $n_input sequences... ";

my @amount = ();
my @list = ();

# If we have less input than the requested amount, take every sequence once
if (($n_requested > $n_input) && (not $oversample))
{
	$n_requested = 0;
}

if ($n_requested > 0)
{
	if ($n_requested > $n_input)
	{
		# Need to oversample
		print STDERR "Oversampling...\n";
		
		for (my $i=0; $i<$n_requested; $i++)
		{
			my $chosen = int (rand ($n_input));
			$amount[$chosen]++;
		}
	}
	else
	{
		# Choose n_requested from n_input by shuff
		my @list = (shuffle 1 .. $n_input);

		for (my $i=0; $i<$n_requested; $i++)
		{
			$amount[$list[$i]]++;
		}
	}
}

my $i = 0;

while (<$file_ref>)
{
	chomp;

	my ($id, $sequence) = split("\t");
	
	my $cur_amount = 1;

	if ($n_requested)
	{
		$cur_amount = int ($amount[$i]);
	}
	
	for (my $j=0; $j<$cur_amount; $j++)
	{
		my $output_seq = &sequence ($sequence, $p_insert, $p_delete, $p_subst);
		print "$id\t$output_seq\n";
	}
	$i++;
}


################################
sub sequence {

	my ($seq, $p_insert, $p_delete, $p_subst) = @_;

	return $seq;
}



__DATA__

sequence.pl

	Simulate massively parallel sequencing technologies. Given an input STAB file,
	samples sequences from it, applies the given noise (sequencing errors) and
	generates an output STAB with the chosen IDs and sequences.

    IMPORTANT:
    
	              This script does not support STDIN input, since it has to know
	              beforehand the amount of sequences in order to efficiently randomly
	              choose a sample from them.

	Parameters:
	              
		-ps <num> Probability of base substitution (default: 0).
		-pi <num> Probability of base insertion (default: 0).
		-pd <num> Probability of base deletion (default: 0).
		
		-n <num>  Number of sequences to sample form input STAB file (default: 0,
		          meaning that every sequence is sampled exactly once)
		          
		-os       Over-sample. In case the input STAB file is smaller than the given
		          "n" parameter (above), allow over-sampling (choosing some sequences
		          more than once). Default: off.
		          
