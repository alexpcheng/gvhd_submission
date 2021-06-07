#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}


#
# Loading args:
#

my %args = load_args(\@ARGV);

my $size = get_arg("size", 2, \%args);
die "ERROR - size ($size) not positive.\n" if ( $size < 1 );

my $alphabet_str = get_arg("alphabet", "ACGT", \%args);
die "ERROR - given alphabet string is empty.\n" if ( length($alphabet_str) == 0 );

my $get_sets = get_arg("get_sets", 0, \%args);

my @alphabet = split(//, $alphabet_str);
my $alphabet_size = @alphabet;


#
# Recursive computation:
#

RecursiveAddNucleotideToKmerOrSet("",0);


#
# End of main script
#

sub RecursiveAddNucleotideToKmerOrSet {
    my ($nucleotides_prefix, $first_alphabet_index_to_use) = @_;

    if ( length($nucleotides_prefix) == $size ) {
	print "$nucleotides_prefix\n";
	return;
    }

    for (my $i = $first_alphabet_index_to_use ; $i < $alphabet_size ; $i++ ) {
	my $next_level_first_alphabet_index_to_use = $get_sets ? $i + 1 : 0 ;
	RecursiveAddNucleotideToKmerOrSet($nucleotides_prefix . $alphabet[$i], $next_level_first_alphabet_index_to_use); 
    }
}


__DATA__

generate_kmers_or_nucleotide_sets.pl

  Generate all k-mers or nucleotide sets of a given size over a given alphabet,
  and print as a column to stdout.

  Options:
  --------
  --help:                    Prints this message.

  -size <int>:               Size of k-mers or of nucleotide sets (default: 2).
  -alphabet <str>:           Alphabet to use (default: ACGT).
  -get_sets:                 If set, will only generate unique nucleotide sets (default: k-mers).

