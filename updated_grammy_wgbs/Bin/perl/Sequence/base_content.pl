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

#my $word_length = get_arg("n", 5, \%args);

my @pssm;
my @lendist;
my $maxlen = 0;
my $nseqs = 0;

# Read sequences and aggregate bases

while(<$file_ref>)
{
	chomp;
	(my $id, my $sequence) = split(/\t/);
	my $seqlen = length ($sequence);
	
	print $id . "\t" . $seqlen . "\t";
	
	$_ = $sequence; my $countA = tr/Aa//;
	$_ = $sequence; my $countC = tr/Cc//;
	$_ = $sequence; my $countG = tr/Gg//;
	$_ = $sequence; my $countT = tr/TUtu//;
	
	printf 	$countA / $seqlen . "\t" . 
			$countC / $seqlen . "\t" .
			$countG / $seqlen . "\t" .
			$countT / $seqlen . "\n";
}

__DATA__

base_content.pl <file>

   Takes in a stab file and computes the base content of each sequecne. 
   
   The output is a tab delimited file containing the following information:
   <ID> <length> <p(A)> <p(C)> <p(G)> <p(T or U)>
