#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAddG_EXE_DIR 		= "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs/";
my $RNAHYBRID_EXE_DIR 	= "$ENV{GENIE_HOME}/Bin/RNAHybrid/RNAhybrid-2.1/src/";

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
my $quiet = get_arg("quiet", 0, \%args);

while (<$file_ref>)
{
	chop;
	if(/\S/)
	{
		my @r = split("\t");
		my $id = $r[0];
		my $seq = $r[1];
	
		my ($bindStart, $bindEnd, $mirna_seq, $dG2) = split(";", $r[2]);
		
		if (!$quiet) { print STDERR "\n    Calculating ddG for $id (target at $bindStart-$bindEnd)... "; }

		# Call RNAddG  ########################################################
		
		open (SEQFILE, ">tmp_seqfile") or die ("Could not open temporary sequence file.\n");
		print SEQFILE "$seq\n$mirna_seq\n";
		close (SEQFILE);
		
		my $target_len = $bindEnd - $bindStart + 1;
		my $resline = `$RNAddG_EXE_DIR/RNAddG4 -s $bindStart -f 8 -t $target_len < tmp_seqfile`;
		chomp ($resline);
		my @result = split (/\t/, $resline);
		
		# QQQ print STDERR "Callling $RNAddG_EXE_DIR/RNAddG4 -s $bindStart -f 8 -t $target_len < tmp_seqfile\n";
		
		print "$id\t" . join ("\t", @result) . "\n";
	}
}

if (!$quiet) { print STDERR "Done.\n"; }

# system("rm tmp_seqfile");


__DATA__

RNAddG.pl

	RNAddG.pl reads RNA sequences from stdin, including a target location for
	miRNA binding and calculates the following energies:
	
	dG0 = energy of ensemble of given RNA.
	dG1 = energy of ensemble of given RNA given that the target area is unbound
	dG2 = energy of binding miRNA - RNA at target site
	ddG = dG1 + dG2 - dG0
	P   = Probability of miRNA being unbound
	
	
    The sequences are given in the following format:
    <id> <sequence> <restriction_start>;<restriction_end>;<miRNA_sequence>;[dG2]
    
    where the restriction coordinates denote areas that must be unpaired in
    the secondary structure. If dG2 is not given in the input file, it is 
    calculated by calling RNAHybrid.



       


