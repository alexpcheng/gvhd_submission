#!/usr/bin/perl

use strict;
use Switch;

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
my $global_N = get_arg("n", 1, \%args);

my $n_molecules;

while (<$file_ref>)
{
	chomp;

	my ($id, $sequence, $fold, $abundant) = split("\t");
	
	if (!$abundant)
	{
		$abundant = 1;
	}
	
	$n_molecules = int ($global_N * $abundant);
	
	print STDERR "Cleaving $id ";
	if ($n_molecules > 1) { print STDERR "($n_molecules copies) "; }
	print STDERR "... ";
	
	my %hydrogenMap = &mapHydrogen ($fold);
	
	for (my $n_mol = 1; $n_mol <= $n_molecules; $n_mol++)
	{
		my @cleaved_positions = ();
		
		# Step on fold and choose where to cut
		
		for (my $i = 0; $i < length ($fold) - 1; $i++)
		{
			my $can_cleave = &cleavePossible ($type, substr ($fold, $i, 2), substr ($sequence, $i, 2));
			
			if (($can_cleave && ($p_cleave >= rand())) || (!$can_cleave && ($p_cleave*$p_wrong > rand())))
			{
				push (@cleaved_positions, $i);
# 				if (exists ($hydrogenMap{$i}))
# 				{
# 					# In case of ds -- cut on other side too
# 					push (@cleaved_positions, $hydrogenMap{$i});
# 				}		
			}	
		}
		
		&outputFragments ($id, $n_mol, $sequence, @cleaved_positions);
	}
	
	print STDERR "   OK.\n";
}	


################################
sub outputFragments {

	my ($id, $n_mol, $sequence, @cleaved_positions) = @_;
	push (@cleaved_positions, (-1, length($sequence)-1));
		
    my %saw;
    my @sorted_cleave = sort { $a <=> $b } grep(!$saw{$_}++, @cleaved_positions);
    
    my $segnum = 1;
    
	for (my $i = 0; $i < $#sorted_cleave; $i++)
	{
		print "$id\t$id" . "_" . $n_mol . "_" . $segnum++ . "\t" . ($sorted_cleave[$i]+2) . "\t" . ($sorted_cleave[$i+1]+1) . "\t" . substr ($sequence, ($sorted_cleave[$i]+1), ($sorted_cleave[$i+1] - $sorted_cleave[$i])) . "\n";
	}
}


################################
sub cleavePossible {

	my $type = $_[0];
	my @fold_area = split (//, $_[1]);
	my @sequence_area = split (//, $_[2]);
	
	switch ($type) {
	
		case "I"
		{
			# RNAse I: 3' of any ssRNA.
			return (($fold_area[0] eq ".") ? 1 : 0);
		}
		
		case "V1"
		{
			# RNAse V1: Both sides should be dsRNA.
			return (($fold_area[0] ne ".") ? 1 : 0);			
		}
		
		case "A"
		{
			# RNAse A: 3' of ss C or U
			return (($fold_area[0] eq ".") && (($sequence_area[0] eq "C") || ($sequence_area[0] eq "U")) ? 1 : 0);
		}
		
		case "T1"
		{
			# RNAse T1: 3' of ss G
			return (($fold_area[0] eq ".") && ($sequence_area[0] eq "G") ? 1 : 0);
		}

		else
		{
			die "Unrecognized RNAse type $type.";
		}
	}
}



sub mapHydrogen {

	my $fold = $_[0];
	
	my %result;
	my @opens = {};
	
	for (my $i = 0; $i < length ($fold)-1; $i++)
	{
		my $cur = substr ($fold, $i, 1);
		
		if ($cur eq ".") { next; }
		if ($cur eq "(") { push (@opens, $i); }
		if ($cur eq ")")
		{
			if (length (@opens) < 1) { die "ERROR at position $i of sequence"; }
			
			my $x = pop (@opens);
			
			if ((substr ($fold, $x, 2) eq "((") && (substr ($fold, ($i-1), 2) eq "))"))
			{
				$result{$x} = ($i-1);
				$result{($i-1)} = $x;
			}
		}
	}
	
	return %result;
}



__DATA__

RNAse.pl

	Simulate RNAses. Gets a sequence-structure file of the format <ID> <Sequence> <Structure>
	[<abundancty>] and outputs the fragments of the resulting cleavage by the given RNAse.
	
	If the fourth (abundancy) row is given, the number of molecules from each RNA will be
	the number given in that fourth column multiplied by the -n parameter (see below)
	
	Output format:
		<ID> <ID_N_S> <start> <end> <sequence>
		
	where N is the running number of the RNA molecule and S is the segment number.
	
	Parameters:
		-p        Probability of cleavage (default: 1)
		-pw       Probability of wrong (non-specific) cleavage (default: 0)
		-type     Type of RNAse. Currently supports I, V1, A, T1 (default: I)
		-n        Number of molecules from each RNA (default: 1)
		

