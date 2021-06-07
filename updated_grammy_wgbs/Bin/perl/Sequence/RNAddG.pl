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

my $echoed_args = 	echo_arg("p", \%args) . 
					echo_arg("d0", \%args) . 
					echo_arg("d1", \%args) . 
					echo_arg("d2", \%args) . 
					echo_arg("d3", \%args) . 
					echo_arg("C", \%args) . 
					echo_arg("T", \%args) . 
					echo_arg("4", \%args) . 
					echo_arg("noLP", \%args) . 
					echo_arg("noGU", \%args) . 
					echo_arg("noCloseGU", \%args) . 
					echo_arg("P", \%args) . 
					echo_arg("circ", \%args) . 
					echo_arg("S", \%args) .
					echo_arg("f", \%args) . 
					echo_arg("e", \%args) . 
					echo_arg("nsp", \%args);

my $utrparams = get_arg("s", "3utr_fly", \%args);


while (<$file_ref>)
{
	chop;
	if(/\S/)
	{
		my @r = split("\t");
		my $id = $r[0];
		my $seq = $r[1];
	
		my ($bindStart, $bindEnd, $mirna_seq, $dG2) = split(";", $r[2]);
		
		#QQQ print STDERR "RNAddG: start=$bindStart; end=$bindEnd\n";
		
		my $target_seq = substr ($seq, $bindStart-1, ($bindEnd-$bindStart+1));
		
		if (!$quiet) { print STDERR "\n    Calculating ddG for $id (target at $bindStart-$bindEnd)... "; }

		# Call RNAHybrid to calculate dG2 #####################################
		
		my @result;
		if ($dG2 ne "")
		{
			my @prog_result = split (/\n/, `$RNAHYBRID_EXE_DIR/RNAhybrid -c -s $utrparams $echoed_args $target_seq $mirna_seq`);
			my $nresults = @prog_result;
			
			if ($nresults ne 1)
			{
				print STDERR "RNAHybrid returned $nresults results (should return 1 result). Aborting.\n";
				print STDERR "Request was: $RNAHYBRID_EXE_DIR/RNAHybrid -c -s $utrparams $target_seq $mirna_seq\n";
				print STDERR "Result is: " . join ('\n', @prog_result);
				next;
			}
				
			@result = split (/:/, @prog_result[0]);
			$dG2 = $result[4];
			#QQQ print STDERR "\n$result[7]   dG2 = $dG2\n$result[8]\n$result[9]\n$result[10]\n\n";
		}
		
		#QQQ print STDERR "TARGET=$target_seq MIRNA=$mirna_seq\n";
		
		
		
		# Call RNAddG  ########################################################
		
		my $constraint = " " x ($bindStart-1) . "x" x ($bindEnd-$bindStart+1) . " " x (length($seq) - $bindEnd); 

		open (SEQFILE, ">tmp_seqfile") or die ("Could not open temporary sequence file.\n");
		print SEQFILE "$seq\n$constraint\n$dG2\n";
		close (SEQFILE);
		
		my $resline = `$RNAddG_EXE_DIR/RNAddG < tmp_seqfile`;
		chomp ($resline);
		@result = split (/\t/, $resline);
	
		print "$id\t" . join ("\t", @result) . "\n";
	}
}

if (!$quiet) { print STDERR "Done.\n"; }

system("rm tmp_seqfile");


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
    
OPTIONS
       -p     Calculate the partition function and  base  pairing  probability
              matrix  in addition to the mfe structure. Default is calculation
              of mfe structure only. Prints a  coarse  representation  of  the
              pair  probabilities  in  form  of a pseudo bracket notation, the
              ensemble free energy, the frequency of the  mfe  structure,  and
              the  structural diversity.  See the description of pf_fold() and
              mean_bp_dist() in the RNAlib documentation for details.
              Note that unless you also specify  -d2  or  -d0,  the  partition
              function  and  mfe  calculations  will  use a slightly different
              energy model. See the discussion of dangling end options  below.

       -p0    Calculate the partition function but not the pair probabilities,
              saving about 50% in runtime. Prints the ensemble free energy -kT
              ln(Z).

       -C     Calculate  structures subject to constraints.  The program reads
              first the sequence, then a string containing constraints on  the
              structure  encoded  with  the symbols: | (the corresponding base
              has to be paired x (the base is unpaired) < (base  i  is  paired
              with a base j>i) > (base i is paired with a base j<i) and match-
              ing brackets ( ) (base i pairs base j)  With  the  exception  of
              "|",  constraints  will  disallow all pairs conflicting with the
              constraint. This is  usually  sufficient  to  enforce  the  con-
              straint,  but  occasionally a base may stay unpaired in spite of
              constraints. PF folding ignores constraints of type "|".

       -T temp
              Rescale energy parameters to a temperature of temp C. Default is
              37C.

       -4     Do   not   include  special  stabilizing  energies  for  certain
              tetra-loops. Mostly for testing.

       -d[0|1|2|3]
              How to treat "dangling  end"  energies  for  bases  adjacent  to
              helices  in  free ends and multi-loops: With (-d1) only unpaired
              bases can participate in at most one dangling end, this  is  the
              default  for mfe folding but unsupported for the partition func-
              tion folding. With -d2 this check is ignored, dangling  energies
              will be added for the bases adjacent to a helix on both sides in
              any case; this is the default  for  partition  function  folding
              (-p).  -d  or  -d0  ignores dangling ends altogether (mostly for
              debugging).
              With -d3 mfe folding will allow  coaxial  stacking  of  adjacent
              helices  in  multi-loops.  At the moment the implementation will
              not allow coaxial stacking of the two interior pairs in  a  loop
              of degree 3 and works only for mfe folding.
              Note  that  by  default (as well as with -d1 and -d3) pf and mfe
              folding treat dangling ends differently. Use -d2 in addition  to
              -p to ensure that both algorithms use the same energy model.

       -noLP  Produce  structures  without lonely pairs (helices of length 1).
              For partition function folding this only  disallows  pairs  that
              can  only  occur  isolated.  Other  pairs may still occasionally
              occur as helices of length 1.

       -noGU  Do not allow GU pairs.

       -noCloseGU
              Do not allow GU pairs at the end of helices.
       
           -e 1|2 Rarely used option to fold sequences from the artificial ABCD...
              alphabet,  where  A pairs B, C-D etc.  Use the energy parameters
              for GC (-e 1) or AU (-e 2) pairs.

       -P <paramfile>
              Read energy parameters from  paramfile,  instead  of  using  the
              default  parameter set. A sample parameter file should accompany
              your distribution.  See the RNAlib documentation for details  on
              the file format.

       -nsp pairs
              Allow  other  pairs in addition to the usual AU,GC,and GU pairs.
              pairs is a comma separated list of additionally  allowed  pairs.
              If a the first character is a "-" then AB will imply that AB and
              BA are allowed pairs.  e.g. RNAfold -nsp -GA  will allow GA  and
              AG pairs. Nonstandard pairs are given 0 stacking energy.

       -S scale
              In  the  calculation  of the pf use scale*mfe as an estimate for
              the ensemble free energy (used to avoid overflows). The  default
              is  1.07,  useful values are 1.0 to 1.2. Occasionally needed for
              long sequences.  You can also recompile the program to use  dou-
              ble precision (see the README file).

       -circ  Assume  a  circular  (instead of linear) RNA molecule. Currently
              works only for mfe folding.

       


