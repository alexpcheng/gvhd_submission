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
my $p_cleave = get_arg("p", 1, \%args);
my $p_wrong = get_arg("pw", 0, \%args);
my $type = get_arg("type", "I", \%args);
my $n_molecules = get_arg("n", 1, \%args);

while (<$file_ref>)
{
	chomp;

	my ($id, $fold) = split("\t");
	print STDERR "Processing $id ... ";

	print "$id\t$id\t1\t";
	print length ($fold);
	print "\tpair\t1\t1\t";
	
	$fold =~ tr/\./0/;
	$fold =~ tr/\)/1/;
	$fold =~ tr/\(/1/;
	
	print join (";", split ("", $fold));
	print "\n";

	print STDERR "   OK.\n";
}	


__DATA__

fold2pairability.pl

	Given a file of the format <ID> <Fold_string> where fold_string is the parentheses folding
	representation, outputs a chv with 0 for every unpaired base and 1 for paired.
		
