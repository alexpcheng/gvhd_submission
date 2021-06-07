#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $sequence_length = get_arg("l", 8, \%args);
my $alphabet = get_arg("a", "ACGT", \%args);

my $no_rev_comp = get_arg("no_rev_comp", 0, \%args);


my $alphabet_size = length($alphabet);

my $all_seqs_num =  $alphabet_size ** $sequence_length;

my @cur_seq;

my $j=1;
for (my $i = 0; $i < $all_seqs_num; ++$i)
{
	my $cur_seq_numeric_val = $i;
	
	
	
	undef  @cur_seq;
	my  @cur_seq;
	
	for (my $p = 0; $p < $sequence_length; ++$p)
	{
		my $cur_l = $cur_seq_numeric_val % $alphabet_size;
		
		push(@cur_seq, substr($alphabet, $cur_l, 1));
		
		#print STDOUT substr($alphabet, $cur_l, 1);
		
		$cur_seq_numeric_val /= $alphabet_size;
		
		
	}
	
	my $cur_seq_str = join("", @cur_seq);
	
	if ($no_rev_comp == 0  || $cur_seq_str le ReverseComplement($cur_seq_str))
	{
		print "Seq$j\t";
		print STDOUT  $cur_seq_str;
		print "\n";
		$j++;
	}
}

__DATA__

generate_all_sequences_in_length.pl 

   Generates random sequences

   -l <num>    :     Length of each sequence (default: 500)

   -a <str>	   :     Alphabet (default: ACGT)
   
   -no_rev_comp:	 generate only on strand of every revcomp


