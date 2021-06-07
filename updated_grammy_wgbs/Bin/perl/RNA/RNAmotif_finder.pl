#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
use List::Util 'shuffle';
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/RNA/RNAmodel.pl";

# =============================================================================
# Const
# =============================================================================
my $BG_MOTIF = "$ENV{GENIE_HOME}/Runs/Folding/Rabani06/Model/BG_motif/bg.tab";
my $BG_MODEL = "$ENV{GENIE_HOME}/Runs/Folding/Rabani06/Model/BG_model/bg.tab";
my $SEPERATOR = ":";
my $MAX_SEQUENCES_PER_FILE = 100;

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

my $fold = get_arg("fold", 0, \%args);
my $contrafold = get_arg("contrafold", 0, \%args);
my $subopt = get_arg("subopt", -1, \%args);
my $negative = get_arg("negative", 0, \%args);
my $shuffle = get_arg("shuffle", 5, \%args);
my $per_sequence = get_arg("per_sequence", 0, \%args);

my $min = get_arg("min", 15, \%args);
my $max = get_arg("max", 70, \%args);
my $bg_motifs = get_arg("bg_motifs", "$BG_MOTIF", \%args);
my $bg_create = get_arg("bg_create", 0, \%args);
my $bg_factor = get_arg("bg", 0.01, \%args);
my $p_distr = get_arg("p", "b", \%args);
my $position_filter = get_arg("f", "r", \%args);
my $stem = get_arg("stem", 1, \%args);
my $loop = get_arg("loop", 1, \%args);

my $n = get_arg("n", 5, \%args);
my $auc = get_arg("auc", 0, \%args);
my $cv_file = get_arg("cv_file", 0, \%args);
my $bg_file = get_arg("bg_model", "$BG_MODEL", \%args);

my $output_pref = get_arg("output_pref", 0, \%args);
my $output_dir = get_arg("output_dir", 0, \%args);

my $output_file_prefix = "";
if ($output_dir) {
  system("mkdir $output_dir");
  $output_file_prefix = "$output_dir/";
}
if ($output_pref) {
  $output_file_prefix = $output_file_prefix."$output_pref";
}


my $split = 200;
my $overlap = 100;

# ------------------------------------------------
# Input sequences
# ------------------------------------------------
print STDERR "================================================================\n";
print STDERR "Input sequences\n";
print STDERR "================================================================\n";

my %sequences;
open(TRAIN, ">training_set_$$.tab") or die ("Cannot open training_set_$$.tab\n");
open(TRAIN_ALL, ">training_set_all_$$.tab") or die ("Cannot open training_set_all_$$.tab\n");

# folding the input sequences
if ($fold ne 0) {
  ($split, $overlap) = split(",", $fold);

  if ($contrafold) {
    print STDERR "Using RNAcontrafold to fold input sequences (split=$split, overlap=$overlap).\n";

    while (<$file_ref>) {
      chomp $_;
      my ($id, $seq) = split("\t", "$_");
      $seq =~ tr/T/U/;

      # folding
      my $length = length($seq);
      my $start = 0;

      while($start < $length) {
	my $sub_seq = substr($seq, $start, $split);
	open(SEQFILE, ">tmp_seqfile_$$") or die ("Cannot open temporary sequence file.\n");
	print SEQFILE ">p_$id$SEPERATOR$start\n$sub_seq\n";
	close(SEQFILE);
	rna_fold(1, "tmp_seqfile_$$", 2, $subopt, \*TRAIN, \*TRAIN_ALL);
	$sequences{"$id$SEPERATOR$start"} = $sub_seq;
	$start = $start + ($split - $overlap);
      }
    }
    system("/bin/rm tmp_seqfile_$$;");
  }
  else {
    print STDERR "Using ViennaRNA to fold input sequences (split=$split, overlap=$overlap).\n";

    open(SEQFILE, ">tmp_seqfile_$$") or die ("Cannot open temporary sequence file.\n");
    my $count = 0;
    my $type = $subopt < 0 ? 0 : 1;
    while (<$file_ref>) {
      chomp $_;
      my ($id, $seq) = split("\t", "$_");
      $seq =~ tr/T/U/;

      # folding
      my $length = length($seq);
      my $start = 0;

      while($start < $length) {
	my $sub_seq = substr($seq, $start, $split);
	print SEQFILE ">p_$id$SEPERATOR$start\n$sub_seq\n";
	$sequences{"$id$SEPERATOR$start"} = $sub_seq;
	$count++;
	$start = $start + ($split - $overlap);
      }
      if ($count >= $MAX_SEQUENCES_PER_FILE) {
	close(SEQFILE);
	rna_fold($count, "tmp_seqfile_$$", $type, $subopt, \*TRAIN, \*TRAIN_ALL);
	$count = 0;

	open(SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
      }
    }
    close(SEQFILE);
    rna_fold($count, "tmp_seqfile_$$", $type, $subopt, \*TRAIN, \*TRAIN_ALL);
    system("/bin/rm tmp_seqfile_$$;");
  }
}

# structure is given
else {
  while (<$file_ref>) {
    chomp $_;
    my ($id, $seq, $struct) = split("\t", "$_");
    $seq =~ tr/T/U/;

    print TRAIN "p_$id\t$seq\t$struct\n";
    print TRAIN_ALL "p_$id\t$seq\t$struct\n";
    $sequences{$id} = $seq;
  }
}
close(TRAIN);

my $pos_examples = scalar(keys %sequences);
print STDERR "$pos_examples input sequences\n";


# ------------------------------------------------
# Negative set
# ------------------------------------------------
print STDERR "================================================================\n";
print STDERR "Negative set\n";
print STDERR "================================================================\n";
my $neg_examples = 0;

# reading negative set
if ($negative ne 0) {
  open(NEGF, "$negative") or die "Cannot open $negative\n";
  while (<NEGF>) {
    chomp $_;
    my ($id, $seq, $struct) = split("\t", "$_");
    $seq =~ tr/T/U/;

    if (not defined($struct) ) { # fold sequence
      print STDERR "Using ViennaRNA to fold negative sequence $id (split=$split, overlap=$overlap).\n";

      open(SEQFILE, ">tmp_seqfile_$$") or die ("Cannot open temporary sequence file.\n");
      my $length = length($seq);
      my $start = 0;
      my $count = 0;
      while($start < $length) {
	my $sub_seq = substr($seq, $start, $split);
	print SEQFILE ">n_$id$SEPERATOR$start\n$sub_seq\n";
	$start = $start + ($split - $overlap);
	$count++;
      }
      close(SEQFILE);
      rna_fold($count, "tmp_seqfile_$$", 0, $subopt, \*TRAIN_ALL);
      system("/bin/rm tmp_seqfile_$$;");
    }
    else {
      print TRAIN_ALL "n_$id\t$seq\t$struct\n";
    }

    $neg_examples++;
  }
  close(NEGF);
}

# building negative set from input examples
else {
  my ($reps, $split, $overlap) = split(",", $shuffle);
  my %negative_sequences = build_negative_set($reps, 1, $per_sequence, \%sequences);
  $neg_examples = $pos_examples * $reps;

  if ($contrafold) {
    foreach my $id (keys %negative_sequences) {
      my $seq = $negative_sequences{$id};

      open(SEQFILE, ">tmp_seqfile_$$") or die ("Cannot open temporary sequence file.\n");
      print SEQFILE ">n_$id\n$seq\n";
      close(SEQFILE);
      rna_fold(1, "tmp_seqfile_$$", 2, $subopt, \*TRAIN_ALL);
    }
    system("/bin/rm tmp_seqfile_$$;");
  }
  else {
    open(SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
    my $count = 0;
    my $type = $subopt < 0 ? 0 : 1;
    foreach my $id (keys %negative_sequences) {
      my $seq = $negative_sequences{$id};
      print SEQFILE ">n_$id\n$seq\n";
      $count++;

      if ($count >= $MAX_SEQUENCES_PER_FILE) {
	close(SEQFILE);
	rna_fold($count, "tmp_seqfile_$$", $type, $subopt, \*TRAIN_ALL);
	$count = 0;

	open(SEQFILE, ">tmp_seqfile_$$") or die ("Could not open temporary sequence file.\n");
      }
    }
    close(SEQFILE);
    rna_fold($count, "tmp_seqfile_$$", $type, $subopt, \*TRAIN_ALL);
    system("/bin/rm tmp_seqfile_$$;");
  }
}
close(TRAIN_ALL);

print STDERR "$neg_examples negative sequences\n";



# ------------------------------------------------
# Negative feature set
# ------------------------------------------------
print STDERR "================================================================\n";
print STDERR "Negative feature set\n";
print STDERR "================================================================\n";

my $bg_size = 0;
my %single_feature_counts_bg;
my %single_feature_counts_std_bg;

if ($bg_create) {
  my @folds;
  open(TRAIN_ALL, "training_set_all_$$.tab") or die ("Cannot open training_set_all_$$.tab\n");
  while (<TRAIN_ALL>) {
    chomp $_;
    my ($id, $seq, $struct) = split("\t", $_);
    if ($id =~ m/^n_(.+)/g) {
      push(@folds, $struct);
    }
  }
  close(TRAIN_ALL);

  $bg_size = scalar(@folds);
  %single_feature_counts_bg = find_features($min, $max, @folds);
}

# loading motifs BG distribution
else {
  open(NEGFILE, $bg_motifs) or die("Could not open $bg_motifs.\n");
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

print STDERR scalar(keys %single_feature_counts_bg);
print STDERR " BG features\n";



# ------------------------------------------------
# Calculating AUC score
# ------------------------------------------------
if ($auc != 0) {
  print STDERR "================================================================\n";
  print STDERR "Calculating AUC score\n";
  print STDERR "================================================================\n";

  my $k = 5;
  my $nauc = 1;
  if ($auc =~ m/(\d+),(\d+)/g) {
    $k = $1;
    $nauc = $2;
  }

  if ($k > $pos_examples) {
    print STDERR "Cross validation fold ($k) is too large, reduce to number of input sequences\n";
    $k = $pos_examples;
  }

  print STDERR "Dividing into $k groups\n";
  my @ids;
  foreach my $id (keys %sequences) {
    if ($id =~ m/^(.+)$SEPERATOR(\d+?)$/g) {
      $id = $1;
    }
    push (@ids, $id);
  }
  my %crossv_division = divide($cv_file, $k, @ids); # [id] => [k]

  my @negative_data;
  my @positive_data;
  for (my $i = 0; $i < $k; $i++) {
    my @neg, my @pos;
    $negative_data[$i] = \@neg;
    $positive_data[$i] = \@pos;
  }

  open (INPUT, "training_set_all_$$.tab") or die "cannot open training_set_all_$$.tab\n";
  while (<INPUT>) {
    chomp $_;

    if ($_ =~ m/^p_(.+)$SEPERATOR\d+\t/g) { # positive example
      my $p = $crossv_division{$1};
      my $ref = $positive_data[$p];
      push(@$ref, $_);
    }
    elsif ($_ =~ m/^n_(.+)\.\d+$SEPERATOR\d+\t/g) { # negative example
      my $p = $crossv_division{$1};
      my $ref = $negative_data[$p];
      push(@$ref, $_);
    }
  }
  close (INPUT);

  for (my $i = 0; $i < $k; $i++) {

    # create input files
    open(FILE_T, ">training_set_$$.tab.$i") or die ("Cannot open training_set_$$.tab.$i\n");
    open(FILE_ALL, ">training_set_all_$$.tab.$i") or die ("Cannot open training_set_all_$$.tab.$i\n");

    my @positive_ids;
    my @positive_sequences;
    my @positive_folds;
    for (my $j = 0; $j < $k; $j++) {
      my $neg_ref = $negative_data[$j];
      my $pos_ref = $positive_data[$j];

      if ($j != $i) { # training set
	# positives
	for (my $l = 0; $l < scalar(@$pos_ref); $l++) {
	  print FILE_T "$$pos_ref[$l]\n";
	  print FILE_ALL "$$pos_ref[$l]\n";

	  my ($id, $seq, $struct) = split("\t", $$pos_ref[$l]);
	  if ($id =~ m/^([pn]_.+)$SEPERATOR(\d+?)$/g) {
	    $id = $1;
	  }
	  push(@positive_ids, $id);
	  push(@positive_sequences, $seq);
	  push(@positive_folds, $struct);
	}

	# negatives
	for (my $l = 0; $l < scalar(@$neg_ref); $l++) {
	  print FILE_ALL "$$neg_ref[$l]\n";
	}
      }
      else { # test set
	open(FILE_TEST, ">test_set_all_$$.tab.$i") or die ("Cannot open test_set_all_$$.tab.$i\n");
	for (my $l = 0; $l < scalar(@$pos_ref); $l++) {
	  print FILE_TEST "$$pos_ref[$l]\n";
	}
	for (my $l = 0; $l < scalar(@$neg_ref); $l++) {
	  print FILE_TEST "$$neg_ref[$l]\n";
	}
	close(FILE_TEST);
      }
    }

    close(FILE_T);
    close(FILE_ALL);

    # learning model
    print STDERR "--------------------------------------------------------\n";
    print STDERR "Learning part $i ...\n";
    print STDERR "--------------------------------------------------------\n";
    # Initializing models
    my $initials = build_initial_models(\@positive_ids, \@positive_sequences, \@positive_folds, \%single_feature_counts_bg, \%single_feature_counts_std_bg,
					$bg_size, $bg_factor, $min, $max, $position_filter, $nauc, $stem, $loop, $p_distr);

    # learning all models
    if ($initials > 1) {
      my @best_score;
      my $best;
      for (my $j = 0; $j < $initials; $j++) {
	learn_model($bg_file, "initial_model_$j.tab", "motif_set_$j.tab", "training_set_$$.tab.$i", "training_set_all_$$.tab.$i", "cm_$$.tab.$i.$j", "scores_$$.tab.$i.$j");
	system("/bin/rm initial_model_$j.tab motif_set_$j.tab");

	# calculate scores
	my @score = calc_scores("scores_$$.tab.$i.$j", "cm_$$.tab.$i.$j"); # <auc> <opp> <sum>
	if ((not defined @best_score) or
	    ($score[0] > $best_score[0]) or
	    ($score[0] == $best_score[0] and $score[1] < $best_score[1]) or
	    ($score[0] == $best_score[0] and $score[1] == $best_score[1] and $score[2] > $best_score[2])){
	  @best_score = @score;
	  $best = $j;
	}
      }

      if (defined @best_score) {
	print STDERR "\nSelecting motif $best (training set score: AUC=$best_score[0], opp=$best_score[1], sum=$best_score[2]) to continue.\n\n";

	# match best model to test set
	match_model($bg_file, "cm_$$.tab.$i.$best", "test_set_all_$$.tab.$i", "scores_$$.tab.$i");
	system("cat scores_$$.tab.$i >> crossv_scores_$$.tab; ".
	       "/bin/rm training_set_all_$$.tab.$i training_set_$$.tab.$i test_set_all_$$.tab.$i cm_$$.tab.$i.* scores_$$.tab.$i.* scores_$$.tab.$i;");
      }
    }
    elsif ($initials == 1) {
      learn_model($bg_file, "initial_model_0.tab", "motif_set_0.tab", "training_set_$$.tab.$i", "training_set_all_$$.tab.$i", "cm_$$.tab.$i.0", "scores_$$.tab.$i.0");
      match_model($bg_file, "cm_$$.tab.$i.0", "test_set_all_$$.tab.$i", "scores_$$.tab.$i");
      system("cat scores_$$.tab.$i >> crossv_scores_$$.tab; /bin/rm training_set_all_$$.tab.$i training_set_$$.tab.$i test_set_all_$$.tab.$i cm_$$.tab.$i.* ".
	     "scores_$$.tab.$i.* scores_$$.tab.$i initial_model_0.tab motif_set_0.tab;");
    }
  }

  # calculate auc score
  my @crossv_scores = calc_scores("crossv_scores_$$.tab");
  print STDERR "--------------------------------------------------------\n";
  print STDERR "AUC = $crossv_scores[0]\n";
  print STDERR "--------------------------------------------------------\n";

  print "cross validation AUC is $crossv_scores[0]\n";
  system("/bin/rm training_set_$$.tab training_set_all_$$.tab crossv_scores_$$.tab");
}

# ------------------------------------------------
# Learn models
# ------------------------------------------------
else {

  print STDERR "================================================================\n";
  print STDERR "Find motifs\n";
  print STDERR "================================================================\n";

  # Initializing models
  my @positive_names;
  my @positive_sequences;
  my @positive_folds;

  open(INPUT, "training_set_$$.tab") or die "cannot open training_set_$$.tab\n";
  while (<INPUT>) {
    chomp;
    my ($id, $seq, $struct) = split("\t");
    if ($id =~ m/^(p_.+)$SEPERATOR(\d+?)$/g) {
      $id = $1;
    }

    push(@positive_names, "$id");
    push(@positive_sequences, $seq);
    push(@positive_folds, $struct);
  }
  close(INPUT);

  my $initials = build_initial_models(\@positive_names, \@positive_sequences, \@positive_folds, \%single_feature_counts_bg, \%single_feature_counts_std_bg,
				      $bg_size, $bg_factor, $min, $max, $position_filter, $n, $stem, $loop, $p_distr);

  @positive_names = ();
  @positive_sequences = ();
  @positive_folds = ();

  # Learning model
  print "num\tAUC\topp\tsum\tNeg\tPos\tconsensus\n";
  my $str = "num\tAUC\topp\tsum\tNeg\tPos\tconsensus\n";
  for (my $i = 1; $i <= $initials; $i++) {
    print STDERR "--------------------------------------------------------\n";
    print STDERR "Learning motif $i ...\n";
    print STDERR "--------------------------------------------------------\n";

    my $pi = $i-1;
    #system("mv initial_model_$pi.tab initial_model_$i.tab; mv motif_set_$pi.tab motif_set_$i.tab;");
    learn_model($bg_file, "initial_model_$pi.tab", "motif_set_$pi.tab", "training_set_$$.tab", "training_set_all_$$.tab",
		"$output_file_prefix"."cm_$i.tab", "$output_file_prefix"."scores_$i.tab", "$output_file_prefix"."alignment_$i.tab", "$output_file_prefix"."cons_$i.tab");
    system("/bin/rm initial_model_$pi.tab motif_set_$pi.tab");

    # calculate scores
    my @scores = calc_scores("$output_file_prefix"."scores_$i.tab", "$output_file_prefix"."cm_$i.tab", "$output_file_prefix"."cons_$i.tab"); # <auc> <opp> <sum> <consensus>
    chomp($scores[3]);
    print "$i\t$scores[0]\t$scores[1]\t$scores[2]\t$neg_examples\t$pos_examples\t$scores[3]\n";
    $str = $str."$i\t$scores[0]\t$scores[1]\t$scores[2]\t$neg_examples\t$pos_examples\t$scores[3]\n";
  }

  print STDERR "--------------------------------------------------------\n";
  print STDERR "$str";
  print STDERR "--------------------------------------------------------\n";

  system("/bin/rm training_set_$$.tab training_set_all_$$.tab;");
}

print STDERR "================================================================\n";
print STDERR "Done!\n";
print STDERR "================================================================\n";



# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# divide
# ------------------------------------------------------------------------
sub divide($$@) {
  my ($cv_file, $k, @ids) = @_;
  my %division;

  if ($cv_file) {
    if (open(CV, "$cv_file")) {

      my %values;
      while (<CV>) {
	chomp $_;
	my ($id, $d) = split("\t", $_);
	$division{$id} = $d;
	$values{$d} = 1;
      }
      close(CV);

      if (scalar(values %values) == $k) {
	return %division;
      }
      else {
	print STDERR "Division does not match $k. Create new division ...\n";
      }
    }
    else  {
      print STDERR "Cannot open $cv_file. Build random division\n";
    }
  }

  my @shuffled_ids = shuffle @ids;
  for (my $i = 0; $i < scalar(@shuffled_ids); $i+=$k) {
    for (my $j = 0; $j < $k; $j++) {
      $division{$shuffled_ids[$i+$j]} = $j;
    }
  }

  return %division;
}


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAmotif_finder.pl <file_name> [options]

  RNAmotif_finder.pl reads RNA sequences from stdin and finds structural
  motifs in these sequences.

  Input positive examples should be given in the format:
    <id>:<index> <sequence> <structure>
  If each id contains only a single instance, <index> can be omitted.

OPTIONS

Input data:
  -fold  <split>,<overlap>  Ignore input folds. Use Vienna RNAfold for folding.
                            Fold the sequences in segments of size <split>, with overlap of
                            <overlap> between segments.
  -contrafold               Use RNAcontrafold to fold input sequences.
  -subopt <num>             Fold the sequence using suboptimal folds withing <num> range of the MFE.

  -negative <file>          The given file contains negative examples in the format:
                                <id>:<index> <sequence> <structure>
                            If each id contains only a single instance, <index> can be omitted.
  -shuffle <num>,<split>,<overlap>      Create <num> negative examples from each input sequence (Default = 5),
                            using the same di-nucleotide distribution as the input set.
                            Fold the sequences in segments of size <split>, with overlap of
                            <overlap> between segments.
  -per_sequence             Calculate the di-nucleotide distribution per sequence.

Initialization:
  -min <num>                Minimal motif size (default = 15).
  -max <num>                Maximal motif size (default = 70).
  -bg_motifs <file>         Negative feature set to use (if not specified use default set).
  -bg_create                Use the negative examples to create negative feature set.
  -bg <num>                 Ignore motifs with p-value > <num> (Default = 0.01).
                            The p-value is calculated for the number of times the motif
                            appears in the input set, using the given BG model.
  -p <n|b>                  Use normal or binomial distribution to calculate pvalues (default: binomial).
                            For normal distribution, counts mean and std should be given in the input file.
  -f <l|r|b|a>              Filtering by position (features that always appear as part of another) (default = r)
                               r = Keep the largest feature.
                               l = Keep the smallest feature.
                               b = Keep both largest and smallest feature.
                               a = keep all features.
  -stem <num>               Treat stems with less then <num> difference in length as equal (Default = 1)
  -loop <num>               Treat loops with less then <num> difference in length as equal (Default = 1)

Learning:
  -n <num>                  Learn <num> motifs for the given sequences (default = 5).
  -auc <k>,<n>              Calculate a <k>-fold cross validation AUC score for finding a motif in the given
                            sequences. Select one out of <num> best motifs when calculating AUC score
                            (If parameters are not specified, use k=5, n=1).
                            In this mode no actual motifs are identified.
  -cv_file <file>           Use cv division specified in the given file (default: random division)
                            File format: <id> <number between 1 to k>
  -bg_model <file>          Background model probabilities (if not specified use default set).


Ouput:
  -output_pref <str>        Add the prefix <str> to all output files.
  -output_dir  <str>        Create dir <str> and save all output files in it.
