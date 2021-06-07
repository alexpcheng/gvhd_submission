#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAddG_EXE_DIR 		= "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs";
my $RNAHYBRID_EXE_DIR 	= "$ENV{GENIE_HOME}/Bin/RNAHybrid/RNAhybrid-2.1/src";

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
	
		(my $bindStart, my $bindEnd, my $mirna_seq) = split(";", $r[2]);
		
		my $mirna_length = length ($mirna_seq);
		
		print "\nCalculating ddG for target $id...";
				
		# Call RNAHybrid to calculate full length hybrid and extarct indexes ######
		
		my $target_seq = substr ($seq, $bindStart-1, ($bindEnd-$bindStart+1));		

		my @prog_result = split (/\n/, `$RNAHYBRID_EXE_DIR/RNAhybrid -c -s $utrparams $target_seq $mirna_seq`);
		my $nresults = @prog_result;
		
		if ($nresults ne 1)
		{
			print STDERR "RNAHybrid returned $nresults results (should return 1 result). Aborting.\n";
			next;
		}
			
		my @result = split (/:/, @prog_result[0]);
		
		print "\n$result[7]\n$result[8]\n$result[9]\n$result[10]";
		
		my @targetIndex = &calcIndex($result[7], $result[8]);
		my @miRNAIndex  = &calcIndex($result[9], $result[10]);
					
		print "\n		TargetIndex = " . join (",", @targetIndex);
		print "\n		 miRNAIndex = " . join (",", @miRNAIndex);
	
		# Create a mapping of miRNA bases to target bases 
		
		my @miRNA2target = ();
		for (my $c = 0; $c < @miRNAIndex; $c++)
		{
			$miRNA2target[$miRNAIndex[$c]] = $targetIndex[$c];
		}
		
		$miRNA2target[0] = 0;

		print "\n		miRNA2target = " . join (",", @miRNA2target) . "\n";
		
		# Calculate ddG for each miRNA length ##################################
		
		my $targetLength = 12;
		open (SEQFILE, ">tmp_seqfile") or die ("Could not open temporary sequence file.\n");
		
		for (my $i = 7; $i <= $mirna_length; $i++)
		{
			my $mirna_subseq = substr ($mirna_seq, 0, $i);
			my $target_seq = substr ($seq, $bindEnd-$targetLength, $targetLength);
				
			# Call RNAHybrid to calculate dG2 and actual extend of target ######

			print "$RNAHYBRID_EXE_DIR/RNAHybrid -c -s $utrparams $target_seq $mirna_subseq\n";
			
			my @prog_result = split (/\n/, `$RNAHYBRID_EXE_DIR/RNAhybrid -c -s $utrparams $target_seq $mirna_subseq`);
			my $nresults = @prog_result;
			
			if ($nresults ne 1)
			{
				print STDERR "RNAHybrid returned $nresults results (should return 1 result). Aborting.\n";
				next;
			}
				
			my @result = split (/:/, @prog_result[0]);
			my $dG2 = $result[4];

			print "\n$result[7]   miRNA = $i; target = $miRNA2target[$i]; dG2 = $dG2\n$result[8]\n$result[9]\n$result[10]\n\n";

			# Calculate the actual target binding size
			
			my $count1;
			my $count2;
			
			$_ = $result[7]; $count1 = tr/A-Z//;
			$_ = $result[8]; $count2 = tr/A-Z//;
			
			my $totalcount = $count1 + $count2;
			
			print "First count = $totalcount... ";
			
			my $r7r = reverse ($result[7]);
			my $r8r = reverse ($result[8]);
			
			my $r7spaces = 0;
			my $r8spaces = 0;
			
			while (chop ($r7r) eq ' ') { $r7spaces++; }
			while (chop ($r8r) eq ' ') { $r8spaces++; }

			print "spaces = $r7spaces, $r8spaces... ";

			$totalcount -= ($r8spaces - $r7spaces);
			print "=$totalcount\n";
			
			# Next time we allow 5 more bases
			$targetLength = $totalcount + 5;
		
			# Add a line to the constraints file that will later be read by RNAddG 
			
			my $constraint = " " x ($bindEnd-$targetLength) . "x" x ($targetLength) . " " x (length ($seq) - $bindEnd); 

			print "seqlen = " . length ($seq) . "; constlen = " . length($constraint) . "\n";
			
			print SEQFILE "$seq\n$constraint\n$dG2\n";			
		}
		
		# Call RNAddG  ########################################################

		close (SEQFILE);
		
		my $resline = `$RNAddG_EXE_DIR/RNAddG $echoed_args < tmp_seqfile`;
		chomp ($resline);
		@result = split (/\t/, $resline);

		print join ("\t", @result) . "\n";
		
	}
}

print STDERR "Done.\n";

# QQQ add: system("rm tmp_seqfile");


sub calcIndex
{
	my $line1 = $_[0];
	my $line2 = $_[1];
	
	my $len = length ($line1);
	
	my $curIndex = 1;
	my @indexVector = ();
	
	for (my $i = $len - 1; $i >= 0; $i--)
	{		
		if ((substr ($line1, $i, 1) eq " ") && (substr ($line2, $i, 1) eq " "))
		{
			$indexVector[$i] = 0;
		}
		else
		{
			$indexVector[$i] = $curIndex++;
		}
	}
	
	return @indexVector;
}


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
    <id> <sequence> <restriction_start>;<restriction_end>;<miRNA_sequence>
    
    where the restriction coordinates denote areas that must be unpaired in
    the secondary structure.
    
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

       


