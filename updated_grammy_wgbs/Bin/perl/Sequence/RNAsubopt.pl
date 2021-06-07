#!/usr/bin/perl

use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAfold_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs/";
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
my $stability = get_arg("S", 0, \%args);
my $split = get_arg("split", 0, \%args);
my $overlap = get_arg("overlap", 0, \%args);
my $sequence = get_arg("sequence", 0, \%args);

my $echoed_args = echo_arg("e", \%args) .
  echo_arg("d", \%args) .
  echo_arg("s", \%args) .
  echo_arg("p", \%args) .
  echo_arg("S", \%args) .
  echo_arg("logML", \%args) .
  echo_arg("ep", \%args) .
  echo_arg("noLP", \%args);

while (<$file_ref>) {
  chop;
  if(/\S/) {
    (my $id, my $seq) = split("\t");
    print STDERR "    Folding $id... \n";

    # print the sequences
    open (SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
    if ($split) {
      my $length = length($seq);
      my $start = 0;
      while($start < $length) {
	my $sub_seq = substr($seq, $start, $split);
	print SEQFILE ">$id$SEPERATOR$start\n$sub_seq\n";
	$start = $start + ($split - $overlap);
      }
    }
    else {
      print SEQFILE ">$id\n$seq\n";
    }
    close (SEQFILE);

    my $results = `$RNAfold_EXE_DIR/RNAsubopt $echoed_args < tmp_seqfile_$$`;
#    print STDERR "$results\n";
    my @prog_result = split (">", $results);
    if ($stability == 0) {
      shift (@prog_result);	# remove first line
    }

    for (my $i = 0; $i < scalar(@prog_result); $i++) {
      my $line = $prog_result[$i];
      my @data = split ("\n", $line);

      $data[0] =~ m/ (.+) \[.+\]/g;
      my $id = $1;
      $data[1] =~ m/^([ACGTU]+) .+/g;
      my $seq = $1;
      $seq =~ tr/T/U/;

      if ($sequence) {
	for (my $j = 2; $j < scalar(@data); $j++) {
	  $data[$j] =~ m/^([\(\)\.]+) .+/g;
	  my $fold = $1;
	  print "$id\t$seq\t$fold\n";
	}
      }
      else {
	print "$id\t$seq\n";
	for (my $j = 2; $j < scalar(@data); $j++) {
	  $data[$j] =~ m/^([\(\)\.]+) (.+)/g;
	  my $fold = $1;
	  my $mfe = $2;
	  print "$fold\t$mfe\n";
	}
      }
    }
  }
}

system("/bin/rm tmp_seqfile_$$");



__DATA__

RNAsubopt.pl <stab file>

   RNAsubopt calculates all suboptimal secondary structures within a user
   defined energy range above the mini-mum free energy (mfe).It prints the
   suboptimal structures in bracket notation.

   The output is a tab delimited file containing the sequence ID, the
   sequence itself followed by pairs of bracket notations and mfes of the
   foldings in increasing order of free energy.

  -e range    Calculate  suboptimal  structures  within  range kcal/mol of the
              mfe.  Default is 1.

  -s          Sort results by increasing mfe.

  -p n        Instead  of producing all suboptimals in a range, produce a ran-
              dom sample of n suboptimal structures, drawn with  probabilities
              equal  to their Boltzmann weights via stochastic backtracking in
              the partition function.

  -d[0|1|2|3] Change treatment of dangling ends, as in  RNAfold  and  RNAeval.
              The default is -d2 (as in partition function folding). If -d1 or
              -d3 are specified the structures are generated as with  -d2  but
              energies are re-evaluated before printing.

  -logML      re-calculate  energies  of structures using a logarithmic energy
              function for multi-loops before output.  This  option  does  not
              effect  structure  generation, only the energies that is printed
              out. Since logML lowers energies somewhat, some  structures  may
              be missing.

  -ep prange  Only print structures with energy within prange of the mfe. Use-
              ful in conjunction with -logML, -d1 or -d3: while the -e  option
              specifies the range before energies are re-evaluated, -ep speci-
              fies the maximum energy after re-evaluation.

  -noLP       Only produce structures without lonely pairs (helices of  length
              1). This reduces the number of structures drastically and should
              therefore be used for longer sequences and larger energy ranges.

  -split n    Split the given sequence into seperate parts of size n, and
              fold each of them seperately (Deafult = do not split).

  -overlap n  Overlap in spliting the sequence (Default = 0, no overlap).

  -sequence   Print the sequence as well as the structure.
