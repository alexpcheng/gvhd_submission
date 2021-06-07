#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/RNA/RNAmodel.pl";

# =============================================================================
# Const
# =============================================================================
my $BG_MOTIF = "$ENV{GENIE_HOME}/Runs/Folding/Rabani06/Model/BG_motif/bg.tab";
my $MAX_SEQUENCES_PER_FILE = 100;
my $SEPERATOR = ":";

# =============================================================================
# Main part
# =============================================================================

# reading arguments
if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file_name = $ARGV[0];
if (length($file_name) < 1 or $file_name =~ /^-/) {
  $file_ref = \*STDIN;
}
else {
  shift(@ARGV);
  open(FILE, $file_name) or die("Could not open $file_name.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $n = get_arg("n", 10, \%args);
my $min_len = get_arg("min", 15, \%args);
my $max_len = get_arg("max", 70, \%args);
my $bg_file = get_arg("bg_model", $BG_MOTIF, \%args);
my $bg_create = get_arg("bg_create", 0, \%args);
my $bg_shuffle = get_arg("bg_shuffle", 0, \%args);
my $per_sequence = get_arg("per_sequence", 0, \%args);
my $bg_factor = get_arg("bg", 0.05, \%args);
my $p_distr = get_arg("p", "b", \%args);
my $f = get_arg("f", "r", \%args);
my $stem = get_arg("stem", 1, \%args);
my $loop = get_arg("loop", 1, \%args);


# ------------------------------------------------
# Initializing Sequences and Structures
# ------------------------------------------------
print STDERR "--------------------------------------------------------\n";
print STDERR " Initializing Sequences and Structures\n";
print STDERR "--------------------------------------------------------\n";

my @positive_names;
my @positive_sequences;
my @positive_folds;

while (<$file_ref>) {
  chomp;
  my ($id, $seq, $struct) = split("\t");
  if ($id =~ m/^(.+)$SEPERATOR(\d+?)$/g) {
    $id = $1;
  }

  push(@positive_names, "$id");
  push(@positive_sequences, $seq);
  push(@positive_folds, $struct);
}
close($file_ref);

print STDERR scalar(@positive_sequences);
print STDERR " Positive sequences read\n";


# ------------------------------------------------
# Initializing BG distribution
# ------------------------------------------------
print STDERR "--------------------------------------------------------\n";
print STDERR " Initializing BG distribution\n";
print STDERR "--------------------------------------------------------\n";
my %single_feature_counts_bg;
my %single_feature_counts_std_bg;
my $bg_size;

# create bg from a given sequence file
if ($bg_create != 0) {
  my @folds;
  open(BGFILE, $bg_create) or die "cannot open $bg_create\n";
  while (<BGFILE>) {
    chomp;
    my ($id, $seq, $struct) = split("\t", $_);
    push(@folds, $struct);
  }
  $bg_size = scalar(@folds);
  %single_feature_counts_bg = find_features($min_len, $max_len, @folds);
}

# create bg by shuffling input sequences
elsif ($bg_shuffle != 0) {
  my ($reps, $split, $overlap) = split(",", $bg_shuffle);
  my %sequences;
  for (my $i = 0; $i < scalar(@positive_names); $i++) {
    $sequences{$positive_names[$i]} = $sequences{$positive_names[$i]}.$positive_sequences[$i];
  }
  my %negative_sequences = build_negative_set($reps, 1, $per_sequence, \%sequences);
  $bg_size = scalar(@positive_names)*$reps;

  my @folds;
  open(SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
  my $count = 0;
  foreach my $id (keys %negative_sequences) {
    my $seq = $negative_sequences{$id};
    my $length = length($seq);
    my $start = 0;

    while($start < $length) {
      my $sub_seq = substr($seq, $start, $split);
      print SEQFILE ">n_$id$SEPERATOR$start\n$sub_seq\n";

      $count++;
      $start = $start + ($split - $overlap);
    }
    if ($count >= $MAX_SEQUENCES_PER_FILE) {
      close(SEQFILE);
      push(@folds, rna_fold($count, "tmp_seqfile_$$"));
      $count = 0;

      open(SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
    }
  }
  close(SEQFILE);
  push(@folds, rna_fold($count, "tmp_seqfile_$$"));
  system("/bin/rm tmp_seqfile_$$;");

  $bg_size = scalar(@folds);
  %single_feature_counts_bg = find_features($min_len, $max_len, @folds);
}

# use a given bg distribution
else {
  open(NEGFILE, $bg_file) or die("Could not open $bg_file.\n");
  $bg_size = <NEGFILE>;
  chomp $bg_size;

  while (<NEGFILE>) {
    chomp;
    my @values = split("\t", $_);
    $single_feature_counts_bg{$values[0]} = $values[1];
    $single_feature_counts_std_bg{$values[0]} = $values[2];
  }
  close(NEGFILE);
}

print STDERR "BG size is $bg_size\n";
print STDERR scalar(keys %single_feature_counts_bg);
print STDERR " BG features used\n";


# ------------------------------------------------
# Build initial models
# ------------------------------------------------
print STDERR "--------------------------------------------------------\n";
print STDERR " Build Initial Models\n";
print STDERR "--------------------------------------------------------\n";

my $initials = build_initial_models(\@positive_names, \@positive_sequences, \@positive_folds, \%single_feature_counts_bg, \%single_feature_counts_std_bg,
				    $bg_size, $bg_factor, $min_len, $max_len, $f, $n, $stem, $loop, $p_distr);

print STDERR " Total: $initials motifs created\n";
system("bin/rm -rf features_$$.tab");


# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAbuild_initial_model.pl <file_name> [options]

  RNAbuild_initial_model.pl reads RNA sequences and structures from stdin and
  creates initial models for learning a CM.

  Sequences are given in the following format: <id> <sequence> <structure>

OPTIONS
  -n <num>                  Number of models to initialize (Default = 10).
  -min <num>                Minimal motif size (default = 15).
  -max <num>                Maximal motif size (default = 70).
  -bg_model <file>          Negative feature set to use (if not specified use default set).
  -bg_create <file>         Use the examples in <file> to create negative feature set.
  -bg_shuffle <num>,<split>,<overlap>      Create <num> negative examples from each input sequence (Default = 5),
                            using the same di-nucleotide distribution as the input set.
                            Fold the sequences in segments of size <split>, with overlap of
                            <overlap> between segments.
  -per_sequence             Calculate the di-nucleotide distribution per sequence.
  -bg <num>                 Ignore motifs with p-value > <num> (Default = 0.05).
                            The p-value is calculated for the number of times the motif
                            appears in the input set, using the given BG model.
  -p <n|b>                  Use normal or binomial distribution to calculate pvalues (default: binomial).
                            For normal distribution, counts mean and std should be given in the input file.
  -f <l|r|b|a>              Filtering by position (features that always appear as part of another) (default = r).
                               r = Keep the largest feature.
                               l = Keep the smallest feature.
                               b = Keep both largest and smallest feature.
                               a = keep all features.
  -stem <num>               Treat stems with less then <num> difference in length as equal (Default = 1)
  -loop <num>               Treat loops with less then <num> difference in length as equal (Default = 1)
