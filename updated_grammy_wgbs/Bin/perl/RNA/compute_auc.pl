#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

my $MAXDOUBLE = 1.79769e+308;
my $EPS = 0.00000001;



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
  open(FILE, $file_name) or die("Could not open file '$file_name'.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $pos_label = get_arg("pos_label", "1", \%args);
my $neg_label = get_arg("neg_label", "0", \%args);
my $wpos_label = get_arg("wpos_label", "2", \%args);
my $roc = get_arg("roc", 0, \%args);

# reading input, calculating TP and FP for each threshold
my @FPR;
my @TPR;
my @WTPR;
my $TP = 0;
my $FP = 0;
my $WTP = 0;

push(@FPR, 0);
push(@TPR, 0);
push(@WTPR, 0);
while (<$file_ref>) {
  chomp $_;
  my $class = $_;

  if ($class eq $pos_label) {
    $TP++;
  }
  elsif ($class eq $neg_label) {
    $FP++;
  }
  elsif ($class eq $wpos_label) {
    $WTP++;
  }
  else {
    print STDERR "Wrong label $class !!!\n";
    exit(1);
  }

  push(@FPR, $FP);
  push(@TPR, $TP);
  push(@WTPR, $WTP);
}

# calculate TPR, FPR
my $positives = $TP + $WTP;
my $negatives = $FP + $WTP;
for (my $i = 0; $i < scalar(@FPR); $i++) {
  $FPR[$i] = ($FPR[$i]+$WTPR[$i])/$negatives;
  $TPR[$i] = $TPR[$i]/$positives;
}

# calculate area under the curve
# for each square: s=TPR[i]*(FPR[i]-FPR[i-1])
if ($roc) {
  for (my $i = 1; $i < scalar(@FPR); $i++) {
    print "$FPR[$i]\t$TPR[$i]\n";
  }
}
else {
  my $auc = 0;
  for (my $i = 1; $i < scalar(@FPR); $i++) {
    $auc += $TPR[$i] * ($FPR[$i] - $FPR[$i-1]);
  }
  print "$auc\n";
}


# =============================================================================
# Subroutines
# =============================================================================


# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

compute_auc.pl <file_name> [options]

Get as input an ordered list of classifications into two groups: 
positives and negatives.
Calculate the area under the curve (auc) measurment for the ROC curve of the
given order of positive and negative examples.

Input format: list of positive/negative labels (each in seperate line)

NOTE: Assumes the list is sorted, and the classification of the best score is
      at the top of the list.

OPTIONS:
   -pos_label <string>     Positive examples labels (default = 1)
   -neg_label <string>     Negative examples labels (default = 0)
   -wpos_label <string>    Wrong positive examples label (default = 2)
   -roc                    Print ROC values
