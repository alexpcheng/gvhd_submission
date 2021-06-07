#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $BIN_PATH   = "$ENV{GENIE_HOME}/Bin/Alignment";
my $SEPERATOR  = ":";

# =============================================================================
# Main part
# =============================================================================

if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $type = get_arg("t", "global", \%args);
my $dbg = get_arg("dbg", 0, \%args);

##### INPUT INFORMATION

# Reading input files (multiple features)
print STDERR "Reading input features ... ";

my %input_data; # <id> => [ feature1, feature2 ...]
my %comp_input_data; # <id> => [ feature1, feature2 ...]
my %multiple_ids;

my $file = get_arg("f1", "null", \%args);
my $feature_counter = 0;
my $multiple_insts = 0;
while ($file ne "null") {
  $feature_counter++;
  open(INFILE, "$file") or die "Cannot read $file\n";
  while (<INFILE>) {
    chomp $_;
    $_ =~ m/^(.+)\t(.+)$/g;
    my $id = $1;
    my @array = split(";", $2);

    if (defined $input_data{$id}) {
      my $ref = $input_data{$id};
      if (scalar(@array) != scalar(@$ref)) {
	print STDERR "Wrong input format. Incompatible sequence size\n";
	exit(1);
      }

      for (my $e = 0; $e < scalar(@array); $e++) {
	$$ref[$e] = $$ref[$e].",$array[$e]";
      }
    }
    else {
      my @input;
      for (my $e = 0; $e < scalar(@array); $e++) {
	$input[$e] = "$array[$e]";
      }
      $input_data{$id} = \@input;
    }

    if ($id =~ m/(.+)$SEPERATOR(\d+)/g) {
      $multiple_insts = 1;
      if (defined $multiple_ids{$1}) {
	my $ref = $multiple_ids{$1};
	push(@$ref, $id);
      }
      else {
	$multiple_ids{$1} = [$id];
      }
    }
  }
  close(INFILE);
  my $f = $feature_counter+1;
  $file = get_arg("f$f", "null", \%args);
}

if ($feature_counter <= 0) {
  print STDERR "No imput files given !!! \n";
  exit(1);
}

print STDERR "$feature_counter features\n";


##### Parameters

my $cmd = "";
my $gopen = 0;
my $gext = 0;
my $comp = get_arg("c1", 0, \%args);
for (my $i = 1; $i <= $feature_counter; $i++) {

  # comparison file
  if ($comp) {
    my $comp_file = get_arg("c$i", "null", \%args);
    if ($comp_file eq "null") {
      print STDERR "Parameters error: Missing comparison file for feature $i\n";
    }

    open(INF, "$comp_file") or die "Cannot read $file\n";
    while (<INF>) {
      chomp $_;
      $_ =~ m/^(.+)\t(.+)$/g;
      my $id = $1;
      my @array = split(";", $2);

      if (defined $comp_input_data{$id}) {
	my $ref = $comp_input_data{$id};
	if (scalar(@array) != scalar(@$ref)) {
	  print STDERR "Wrong input format. Incompatible sequence size\n";
	  exit(1);
	}

	for (my $e = 0; $e < scalar(@array); $e++) {
	  $$ref[$e] = $$ref[$e].",$array[$e]";
	}
      }
      else {
	my @input;
	for (my $e = 0; $e < scalar(@array); $e++) {
	  $input[$e] = "$array[$e]";
	}
	$comp_input_data{$id} = \@input;
      }

      if ($id =~ m/(.+)$SEPERATOR(\d+)/g) {
	$multiple_insts = 1;
	if (defined $multiple_ids{$1}) {
	  my $ref = $multiple_ids{$1};
	  push(@$ref, $id);
	}
	else {
	  $multiple_ids{$1} = [$id];
	}
      }
    }
    close(INF);
  }

  # parameters
  my $function = get_arg("L$i", "null", \%args);
  my $parameters = get_arg("p$i", "null", \%args);
  my $match = get_arg("match$i", "null", \%args);
  my $mismatch = get_arg("mismatch$i", "null", \%args);
  if ($function ne "null") {
    $cmd = $cmd."l,$function";
  }
  elsif ($parameters ne "null") {
    $cmd = $cmd."s,$parameters";
  }
  elsif ($match ne "null" and $mismatch ne "null") {
    $cmd = $cmd."m,$match,$mismatch";
  }
  else {
    print STDERR "Parameters error: Missing comparison parameters for feature $i\n";
    exit (1);
  }
  $cmd = $cmd.",";

  # gopen, gext
  $gopen += get_arg("gopen$i", 0, \%args);
  $gext += get_arg("gext$i", 0, \%args);
}

my $input_seq = scalar(keys %input_data) + scalar(keys %comp_input_data);
print STDERR "$input_seq sequences\n";

chop $cmd;
if ($type eq "local") {
  $cmd = "l -p ".$cmd;
}
elsif ($type eq "distance") {
  $cmd = "d -p ".$cmd;
}
else {
  $cmd = "g -p ".$cmd;
}

if ($feature_counter == 1) {
  $cmd = "cat tmp_inputfile_$$.tab | $BIN_PATH/simple_alignment $input_seq ".$cmd;
}
else {
  $cmd = "cat tmp_inputfile_$$.tab | $BIN_PATH/alignment $feature_counter ".$cmd;
}
if ($comp) {
  my $split = scalar (keys %input_data);
  $cmd = $cmd." -s $split";
}
$cmd = $cmd." -gopen $gopen -gext $gext >> tmp_outputfile_$$.tab";



#### Alignments

open(FILE, ">tmp_inputfile_$$.tab") or die "Cannot create tmp_inputfile_$$.tab\n";
foreach my $id (keys %input_data) {
  print FILE "$id\t";
  my $ref = $input_data{$id};
  if ($feature_counter == 1) {
    print FILE scalar(@$ref);
    print FILE "\t";
  }

  foreach my $element (@$ref) {
    print FILE "$element;";
  }
  print FILE "\n";
}

foreach my $id (keys %comp_input_data) {
  print FILE "$id\t";
  my $ref = $comp_input_data{$id};
  if ($feature_counter == 1) {
    print FILE scalar(@$ref);
    print FILE "\t";
  }

  foreach my $element (@$ref) {
    print FILE "$element;";
  }
  print FILE "\n";
}

close(FILE);

print STDERR "Running command: $cmd\n";
system("$cmd");
print STDERR "Done!\n";



##### PRINTING RESULTS

# calculate max of multiple comparisons
if ($multiple_insts) {
  my %results_score;
  my %results_alignment;
  open(RESULT, "tmp_outputfile_$$.tab") or die "Cannot read tmp_outputfile_$$.tab\n";

  if ($type eq "distance") {
    while (<RESULT>) {
      chomp $_;
      my @line = split("\t", $_);

      my @ids;
      $ids[0] = $line[0];
      if ($ids[0] =~ m/^(.+)$SEPERATOR(\d+)$/g) {
	$ids[0] = $1;
      }
      $ids[1] = $line[1];
      if ($line[1] =~ m/^(.+)$SEPERATOR(\d+)$/g) {
	$ids[1] = $1;
      }
      my @sid = sort @ids;
      my $id = $sid[0]."\t".$sid[1];

      if ((not defined $results_score{$id}) or ($results_score{$id} > $line[2])) {
	$results_score{$id} = $line[2];
	$results_alignment{$id} = $line[3];
      }
    }
  }
  else {
    while (<RESULT>) {
      chomp $_;
      my @line = split("\t", $_);

      my @ids;
      $ids[0] = $line[0];
      if ($ids[0] =~ m/^(.+)$SEPERATOR(\d+)$/g) {
	$ids[0] = $1;
      }
      $ids[1] = $line[1];
      if ($line[1] =~ m/^(.+)$SEPERATOR(\d+)$/g) {
	$ids[1] = $1;
      }
      my @sid = sort @ids;
      my $id = $sid[0]."\t".$sid[1];

      if ((not defined $results_score{$id}) or ($results_score{$id} < $line[2])) {
	$results_score{$id} = $line[2];
	$results_alignment{$id} = $line[3];
	if (scalar(@line) > 3) {
	  $results_alignment{$id} = $results_alignment{$id}."\t$line[4]\t$line[5]";
	}
      }
    }
  }

  close(RESULT);
  foreach my $id (keys %results_score) {
    print "$id\t$results_score{$id}\t$results_alignment{$id}\n";
  }
}
# simply print results
else {
  print STDERR "No multiple instances\n";

  open(RESULT, "tmp_outputfile_$$.tab") or die "Cannot read tmp_outputfile_$$.tab\n";
  while (<RESULT>) {
    print $_;
  }
  close(RESULT);
}

if (not $dbg) {
  system("/bin/rm tmp_inputfile_$$.tab tmp_outputfile_$$.tab");
}
print STDERR "Done.\n";




# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

vector_align.pl

Given a features file of the format: <ID> <Feature_vector>
computes the best alignment between all pairs of features.

Output format: <ID1> <ID2> <Score> <Alignment> <start1> <start2>
The <Alignment> string represents the alignment that was used to generate the
reported score. M=Match, S=Substitution, I=Insertioin, D=Deletion. E.g. MMMISIISSSSM
(I = gap in seq2, D= gap in seq1).

Higher score represent better alignments, except for the "distance" type of alignment.

Multiple sequences with the same id:
To give as input more than a single line with the same id, use the format:
  <ID>:<Count> <Feature_vector>
Treats all lines as a single group, and compute the best alignment between a
member of the first group and a member of the second group (i.e., compute all
pairwise alignments of members of the first group with members of the second group,
and selects the best alignment).

Parameters:
    -t <type>          Type of alignment:
                           - "global" (simple alignment)
                           - "local" (no cost for ins/del at beginning and end of alignment)
                           - "distance" ((-1) * vector distance. the two vectors must be of the same length)
                       Default = global.

    -dbg               Keep temporary files.

    -f[F] <name>       Feature file name.

    -c[F] <name>       Comparison file for feature [F], in the same format as the feature file. If specified
                       compute only comparisons between feature file instances and comparison file instances,
                       instead of all pairwise comparisons.

    -gopen[F] <n>      Penalty for gap opening (Default = 0)
    -gext[F] <n>       Penalty for gap extention (Default = 0)

 One of:
    -match[F] <num>    Match penalty.
    -mismatch[F] <num> Mismatch penalty.

    -L[F] <num>        Metric to use when comparing two scalars.
                       (e.g.: the parameter -L[F] 2 means score= 1/[1+(a - b)^2])

    -p[F] <file>       Parameters file containing a substitution matrix
                       (N+1 lines x N columns; top row is list of objects,
                       lines are ordered respectively).

Remarks:
    * [F] is the feature file number (1, 2, ...).
    * The mask and coverage columns are not used at this stage.
