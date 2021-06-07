#!/usr/bin/perl
use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $RNAfold_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs/";
my $DIST_FROM_EDGE = 15;

# help mesasge
if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}




# parameters
my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) {
  $file_ref = \*STDIN;
} 
else {
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
  shift(@ARGV);
}

my $dist = 1;
my $mode = 0; # 1 = up, 2 = down, 3 = st, 4 = end
my $pos = 0;

my $arg = $ARGV[0];
while ($arg =~ /^-/) {
  shift(@ARGV);
  if ($arg =~ /-up/) {
    print STDERR "mode up \n";
    $dist = 0;
    $mode = 1;
  }
  elsif ($arg =~ /-down/) {
    print STDERR "mode down \n";
    $dist = 0;
    $mode = 2;
  }
  elsif ($arg =~ /-st/) {
    print STDERR "mode st \n";
    $dist = 0;
    $mode = 3;
    $pos = shift(@ARGV);
  }
  elsif ($arg =~ /-end/) {
    print STDERR "mode end \n";
    $dist = 0;
    $mode = 4;
    $pos = shift(@ARGV);
  }
  $arg = $ARGV[0];
}





# read all sequences while creating the input file for RNAfold
my @counts;
my @probs;

while (<$file_ref>) {
  chop;
  if (/\S/) {

    # create temporary sequence file
    (my $id, my $seq) = split("\t");

    my $size = length($seq);
    if (not $dist) {
      for (my $i = 0; $i < $size; $i++) {
	$counts[$i]++;
      }
    }

    print STDERR "$id : seq of size $size\n";
    open (SEQFILE, ">tmp_seqfile") or
      die("Could not open temporary sequence file.\n");
    print SEQFILE "> $id\n$seq\n";
    close (SEQFILE);

    # run RNAfold
    my $r = `$RNAfold_EXE_DIR/RNAfold -p < tmp_seqfile`;

    # read *_dp.ps files and analyze them
    my @c_dist_probs;

    my $ubox = `grep ubox *_dp.ps`;
    my @lines = split(/\n/, "$ubox");

    foreach my $l (@lines) {
      if ($l =~ m/^(\d+) (\d+) ([0-9\.]+) ubox$/g) {
	my $st = $1; # first base position
	my $end = $2; # last base position
	my $prob = $3*$3; # prob for pairing
	
	# by dist
	if (($dist) and
	    ($st > $DIST_FROM_EDGE) and ($end < $size - $DIST_FROM_EDGE)) {
	  my $dist = $end - $st + 1;
	  $c_dist_probs[$dist] += $prob;
	}

	# by pos
	elsif ($mode == 1) {
	  $probs[$end] += $prob;
	} elsif ($mode == 2) {
	  $probs[$st] += $prob;
	} elsif ($mode == 3) {
	  if ($st >= $pos) {
	    $probs[$end] += $prob;
	  }
	  if ($end >= $pos) {
	    $probs[$st] += $prob;
	  }
	} elsif ($mode == 4) {
	  if ($st < $pos) {
	    $probs[$end] += $prob;
	  }
	  if ($end < $pos) {
	    $probs[$st] += $prob;
	  }
	}
      }
    }

    if ($dist) {
      my $sum = 0;
      for (my $i = 0; $i < scalar(@c_dist_probs); $i++) {
	$sum += $c_dist_probs[$i];
      }

      for (my $i = 0; $i < scalar(@c_dist_probs); $i++) {
	$probs[$i] += $c_dist_probs[$i]/$sum;
	$counts[$i]++;
      }
    }

    # remove files
    system("rm *_ss.ps");
    system("rm *_dp.ps");
  }
}

# remove temporary files
system("rm tmp_seqfile");


# print results
# averages
for (my $i = 1;  $i < scalar(@probs); $i++) {
  if ($counts[$i] > 0) {
    $probs[$i] = $probs[$i]/$counts[$i];
  }
  printf("%d\t%.9f\n", $i, $probs[$i]);
}




__DATA__

RNApair.pl

RNApair.pl reads RNA sequences from stdin, Calculate the partition
function and base pairing probability statistics.

The sequences are given in the following format: <id> <sequence>

Options:
  -dist     calculate the pairing pribabilities between bases of
            a specific distance for each distance [DEFAULT].
            format: <distance> <prob>
  -up       calculate the pairing probabilities with upstream bases 
            for each position.
            format: <position> <prob>
  -down     calculate the pairing probabilities with downstream bases 
            for each position.
            format: <position> <prob>
  -st <num> calculate the pairing probabilities with positions starting with
            the given position.
            format: <position> <prob>
  -end <num> calculate the pairing probabilities with positions up to
            the given position.
            format: <position> <prob>
