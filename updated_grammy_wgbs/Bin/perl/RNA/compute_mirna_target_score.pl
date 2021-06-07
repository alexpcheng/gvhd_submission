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
my $dG5_col = get_arg("dG5", -1, \%args);
my $dG3_col = get_arg("dG3", -1, \%args);
my $dGopen_col = get_arg("dGopen", -1, \%args);
my $dG0_col = get_arg("dG0", -1, \%args);
my $dG1_col = get_arg("dG1", -1, \%args);
my $weights_string = get_arg("weights", "", \%args);

my @weights = split(/\,/, $weights_string);
if (@weights ne 3)
{
	print STDOUT <DATA>;
	die ("\nERROR: Weights string should include three values (w0,w1,w2).\n\n");
}

if ( ($dG5_col eq -1) || ($dG3_col eq -1) || ( ($dGopen_col eq -1) && ( ($dG0_col eq -1) || ($dG1_col eq -1) ) ))
{
	print STDOUT <DATA>;
	die ("\nERROR: Must supply dG5 column, dG3 column and either dGopen or dG0 and dG1 columns.\n\n");
}

while (<$file_ref>)
{
	chomp;

	my @r = split("\t");
	my $dGopen;
	
	if ($dGopen_col > -1)
	{
		$dGopen = $r[$dGopen_col];
	}
	else
	{
		$dGopen = $r[$dG0_col] - $r[$dG1_col];
	}
	
	my $score = $weights[0] +
				$r[$dG5_col] +
				$weights[2] * $r[$dG3_col] -
				$weights[1] * $dGopen;
	
	#print STDERR "Score = $score\n";
	print join ("\t", @r) . "\t$score\n";
}


__DATA__

compute_mirna_target_score.pl

    Computes the overall miRNA target score based on the given weights, using
    the following equation:
	
         score = w0 + dG5 + w2 x dG3 + w1 x dGopen
	
    Parameters:
	
        weights "w0,w1,w2"        string of numerical values separated by commas.

        dG5 <col>                 column index (zero-based) where energies can be found.
        dG3 <col>                 both dG5 and dG3 must be given, and then either dGopen
        dGopen <col>              of both dG0 and dG1.
        dG0 <col>
        dG1 <col>
    
