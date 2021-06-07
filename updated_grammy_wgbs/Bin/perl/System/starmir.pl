#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $delay = get_arg("d", 10, \%args);
my $reqfile = get_arg ("req", "request.txt", \%args);
my $host = get_arg ("host", "wwwproxy.weizmann.ac.il", \%args);
my $port = get_arg ("port", "8080", \%args);


open(FILE,"$reqfile") || die("Couldn't open file $reqfile for reading.");

my @REQLINES = <FILE>;
close(FILE);
my $reqtext = join ("", @REQLINES);

while (<$file_ref>)
{
	chomp;

	(my $mir_id, my $mir_seq, my $utr_id, my $utr_seq, my $coding_seq) = split("\t");	

	print STDERR "\n	Processing $mir_id on $utr_id: Preparing...";

	$reqtext =~ s/QQQmir_idQQQ/$mir_id/g;
	$reqtext =~ s/QQQmir_seqQQQ/$mir_seq/g;
	$reqtext =~ s/QQQutr_idQQQ/$utr_id/g;
	$reqtext =~ s/QQQutr_seqQQQ/$utr_seq/g;
	$reqtext =~ s/QQQcoding_seqQQQ/$coding_seq/g;
	
	open (SEQFILE, ">tmp_reqfile") or die ("Could not open temporary request file.\n");
	print SEQFILE "$reqtext\n";
	close (SEQFILE);

	print STDERR " Requesting...";
	
	my $cmd = "nc $host $port < tmp_reqfile";
	print STDERR "Calling $cmd\n";
	
	my $reply = `$cmd`;
	
	#open(FILE,"reply.txt") || die("Couldn't open file $reqfile for reading.");

	#my @REPLINES = <FILE>;
	#close(FILE);
	#my $reply = join ("", @REPLINES);

	#checkstatus.pl?dt=0515035054&pid=30224">
	if ($reply =~ /checkstatus.pl\?dt=([0-9]*)\&pid=([0-9]*)/)
	{
		print STDERR " OK.";
		print "$mir_id\t$utr_id\t$1\t$2\n";
	}
	else
	{
		print STDERR " Could not find IDs.";
	}
	
	sleep ($delay);
}

print STDERR "Done.\n";

#system("rm tmp_reqfile");


__DATA__

RNAfold.pl

	RNAfold.pl reads RNA sequences from stdin, calculates their  minimum  free
    energy  (mfe)  structure  and  prints  to  stdout  the mfe structure in
    bracket notation and its free energy.
    
    The sequences are given in the following format:
    <id> <sequence> 

OPTIONS

       -energy   Print the mfe (and possibly the free energy of ensemble, in
                 case used in conjuction with the -p parameter)

       -DNA   Use DNA parameters (fold DNA).
       
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

       


