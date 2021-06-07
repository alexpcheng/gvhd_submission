#!/usr/bin/perl

use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAfold_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs";
my $MAX_SEQUENCES_PER_FILE = 20;
my $SEPERATOR = ":";



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

my $echoed_args = 
  echo_arg("p", \%args) .
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

my $DNA_par = get_arg("DNA", 0, \%args);
my $partition = get_arg("p", 0, \%args);
my $print_energy = get_arg ("energy", 0, \%args);
my $split = get_arg("split", 0, \%args);
my $overlap = get_arg("overlap", 0, \%args);
my $plot = get_arg("plot", 0, \%args);
my $sequence = get_arg("sequence", 0, \%args);

if ($DNA_par) {
  $echoed_args .= " -P $RNAfold_EXE_DIR/dna_DM.par";
}



# writing sequences into a file until reaching MAX_SEQUENCES_PER_FILE,
# then folding
open (SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
my $count = 0;


while (<$file_ref>) {
  chop;

  if(/\S/) {

    (my $id, my $seq, my $constraint) = split("\t");	
    print STDERR "    Folding $id... \n";

    # print sequence
    if ($split) {
      my $length = length($seq);
      my $start = 0;

      while($start < $length) {
	my $sub_seq = substr($seq, $start, $split);

	print SEQFILE ">$id$SEPERATOR$start\n$sub_seq\n";
	if ($constraint ne "") {
	  print SEQFILE "$constraint\n";
	}

	$count++;
	$start = $start + ($split - $overlap);
      }
    }
    else {
      print SEQFILE ">$id\n$seq\n";
      if ($constraint ne "") {
	print SEQFILE "$constraint\n";
      }
      $count++;
    }

    # folding sequences
    if ($count >= $MAX_SEQUENCES_PER_FILE) {
      close (SEQFILE);

      my $cmd = "$RNAfold_EXE_DIR/RNAfold $echoed_args < tmp_seqfile_$$";
      execute_command($cmd, $partition, $print_energy, $sequence, $count);
      if (not $plot) {
	system("/bin/rm *_ss.ps;");
	if ($partition) {
	  system("/bin/rm  *_dp.ps;");
	}
      }

      $count = 0;
      open (SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
    }
  }
}

close (SEQFILE);
my $cmd = "$RNAfold_EXE_DIR/RNAfold $echoed_args < tmp_seqfile_$$";
execute_command($cmd, $partition, $print_energy, $sequence, $count);
if (not $plot) {
  system("/bin/rm *_ss.ps;");
  if ($partition) {
    system("/bin/rm  *_dp.ps;");
  }
}
print STDERR "Done.\n";

system("/bin/rm tmp_seqfile_$$");





sub execute_command($$$$$) {
  my ($cmd, $partition, $print_energy, $sequence, $count) = @_;
  #print "$cmd\n";

  my @prog_result = split (/\n/, `$cmd`);

  for (my $i = 0; $i < $count; $i++) {
    my $id = shift (@prog_result);       # id
    $id =~ m/>(.+)/g;
    $id = $1;

    my $seq = shift (@prog_result);	 # sequence
    my $line = shift (@prog_result);     # structure

    #print STDERR "|$seq|$line|\n";
    $line =~ m/([\.\(\)]+) \( *(.+)\)/g;
    my $fold = $1;
    my $energy = $2;

    if ($sequence) {
      print "$id\t$seq\t$fold";
    }
    else {
      print "$id\t$fold";
    }

    my @part;
    if ($partition) {
      @part = split (/ /, shift (@prog_result), 2);
      print "\t$part[0]";
      my $data = shift (@prog_result);
    }

    if ($print_energy) {
      print "\t$energy";

      if ($partition) {
	my $part_e = substr ($part[1], 1, -1);
	$part_e =~ s/^\s+//;
	print "\t$part_e";
      }
    }
    print "\n";
  }
}




__DATA__

RNAfold.pl

    RNAfold.pl reads RNA sequences from stdin, calculates their  minimum  free
    energy  (mfe)  structure  and  prints  to  stdout  the mfe structure in
    bracket notation and its free energy.

    The sequences are given in the following format:
    <id> <sequence>



OPTIONS

  -energy        Print the mfe (and possibly the free energy of ensemble, in case
                 used in conjuction with the -p parameter)

  -DNA           Use DNA parameters (fold DNA).

  -p             Calculate the partition function and  base  pairing  probability
                 matrix  in addition to the mfe structure. Default is calculation
                 of mfe structure only. Prints a  coarse  representation  of  the
                 pair  probabilities  in  form  of a pseudo bracket notation, the
                 ensemble free energy, the frequency of the  mfe  structure,  and
                 the  structural diversity.  See the description of pf_fold() and
                 mean_bp_dist() in the RNAlib documentation for details.
                 Note that unless you also specify  -d2  or  -d0,  the  partition
                 function  and  mfe  calculations  will  use a slightly different
                 energy model. See the discussion of dangling end options  below.

  -C             Calculate  structures subject to constraints.  The program reads
                 first the sequence, then a string containing constraints on  the
                 structure  encoded  with  the symbols: | (the corresponding base
                 has to be paired x (the base is unpaired) < (base  i  is  paired
                 with a base j>i) > (base i is paired with a base j<i) and match-
                 ing brackets ( ) (base i pairs base j)  With  the  exception  of
                 "|",  constraints  will  disallow all pairs conflicting with the
                 constraint. This is  usually  sufficient  to  enforce  the  con-
                 straint,  but  occasionally a base may stay unpaired in spite of
                 constraints. PF folding ignores constraints of type "|".

  -T temp        Rescale energy parameters to a temperature of temp C. Default is
                 37C.

  -4             Do not include  special  stabilizing  energies  for  certain
                 tetra-loops. Mostly for testing.

  -d[0|1|2|3]    How to treat "dangling  end"  energies  for  bases  adjacent  to
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

  -noLP          Produce  structures  without lonely pairs (helices of length 1).
                 For partition function folding this only  disallows  pairs  that
                 can  only  occur  isolated.  Other  pairs may still occasionally
                 occur as helices of length 1.

  -noGU          Do not allow GU pairs.

  -noCloseGU     Do not allow GU pairs at the end of helices.

  -e 1|2         Rarely used option to fold sequences from the artificial ABCD...
                 alphabet,  where  A pairs B, C-D etc.  Use the energy parameters
                 for GC (-e 1) or AU (-e 2) pairs.

  -P <paramfile> Read energy parameters from  paramfile,  instead  of  using  the
                 default  parameter set. A sample parameter file should accompany
                 your distribution.  See the RNAlib documentation for details  on
                 the file format.

  -nsp pairs     Allow  other  pairs in addition to the usual AU,GC,and GU pairs.
                 pairs is a comma separated list of additionally  allowed  pairs.
                 If a the first character is a "-" then AB will imply that AB and
                 BA are allowed pairs.  e.g. RNAfold -nsp -GA  will allow GA  and
                 AG pairs. Nonstandard pairs are given 0 stacking energy.

  -S scale       In  the  calculation  of the pf use scale*mfe as an estimate for
                 the ensemble free energy (used to avoid overflows). The  default
                 is  1.07,  useful values are 1.0 to 1.2. Occasionally needed for
                 long sequences.  You can also recompile the program to use  dou-
                 ble precision (see the README file).

  -circ          Assume  a  circular  (instead of linear) RNA molecule. Currently
                 works only for mfe folding.

  -split <num>   Split the given sequence into seperate parts of size <num>, and
                 fold each of them seperately (Deafult = do not split).

  -overlap <num> Overlap in spliting the sequence (Default = 0, no overlap).

  -plot          Produces PostScript files with plots of the resulting secondary
                 structure graph and a "dot plot" of the base pairing matrix.
                 The dot plot shows a matrix of squares with area proportional
                 to the pairing probability in the upper half, and one square for
                 each pair in the minimum free energy structure in the lower half.
                 The PostScript files "[id]_ss.ps" and "[id]_dp.ps" are produced
                 for the structure and dot plot, respectively.

  -sequence      Print the sequence as well as the structure.
