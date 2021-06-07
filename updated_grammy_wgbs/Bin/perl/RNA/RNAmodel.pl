#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
use List::Util 'shuffle';

require "$ENV{PERL_HOME}/Lib/libstats.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";

# =============================================================================
# Const
# =============================================================================
my $VIENNA_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/Progs";
my $CONTRAFOLD_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Contrafold/contrafold/src";
my $MAX_SEQUENCES_PER_FILE = 100;

# clustering const
my $DMAX = 20;
my $METRIC = "f";
my $PERCENTILE = 1;
my $LINKAGE_METHOD = "MaxLinkage";
my $SEP = ":";


# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# build_initial_models
# ------------------------------------------------------------------------
sub build_initial_models() {
#  my ($names_ref, $sequences_ref, $folds_ref, $bg_counts_ref, $bg_size, $bg_factor, $min_len, $max_len, $filter, $n, $stem, $loop) = @_;
  my ($names_ref, $sequences_ref, $folds_ref, $bg_counts_ref, $bg_std_ref, $bg_size, $bg_factor, $min_len, $max_len, $filter, $n, $stem, $loop, $p_distr) = @_;
  my $input_size = scalar(@$sequences_ref);
  if ($bg_size <= 1) {
    $input_size = 1;
  }

  my $total_genes = count_unique($names_ref);

  #### Finding features ####
  # Feature = a structural element contained within the RNA structhre.
  # Ignore the dots at the end/beginning of the feature
  # <min_size> <= feature size <= <max_size>
  ####
  my %features_sequences; # features sequences: <feature> => { [seq] [seq] ... }
  my %features_genes; # <feature> => { hash of genes }
  my %single_counts;

  my @features_struct;
  my @features_start;
  my @features_end;
  my @features_ids;
  for (my $i = 0; $i < scalar(@$folds_ref); $i++) {

    my $name = $$names_ref[$i];
    my $struct = $$folds_ref[$i];
    my $sequence = $$sequences_ref[$i];

    my $total_size = length($struct);
    my $max_st = $total_size - $min_len;
    my $size = $max_len;
    if ($size > $total_size){
      $size = $total_size;
    }

    my $struct_num = $struct;
    $struct_num =~ s/\(/1 /g;
    $struct_num =~ s/\)/-1 /g;
    $struct_num =~ s/\./0 /g;
    my @all_struct = split(/ /, $struct_num); # the entire structure
    unshift(@all_struct, 0);

    my @curr_struct; # the current part of the structure
    @curr_struct[0] = 0;
    for (my $i = 1; $i <= $size; $i++) {
      $curr_struct[$i] = $curr_struct[$i-1] + $all_struct[$i];
    }

    # find features
    for (my $st = 1; $st <= $max_st; $st++) { # possible starting points
      for (my $k = $min_len; $k <= $size; $k++) { # possible feature lengths

	# feature: ends with zero, and never reach negative values
	# drop features that contain points in each of the edges
	my @mot = @curr_struct;
	splice(@mot, $k+1);
	my $str_mot = substr($struct, $st-1, $k);

	if (legal_feature($str_mot, @mot)) {
	  my $seq_mot = substr($sequence, $st-1, $k);

	  push(@features_struct, $str_mot);
	  push(@features_start, $st - 1);
	  push(@features_end, $st + $k - 2);
	  push(@features_ids, $i);

	  $single_counts{$str_mot}++;

	  if (exists $features_sequences{$str_mot}) {
	    my $ref = $features_sequences{$str_mot};
	    push (@$ref, "$seq_mot");
	  }
	  else {
	    $features_sequences{$str_mot} = [$seq_mot];
	  }

	  if (exists $features_genes{$str_mot}) {
	    my $ref = $features_genes{$str_mot};
	    $$ref{$name}++;
	  }
	  else {
	    my %h;
	    $h{$name} = 1;
	    $features_genes{$str_mot} = \%h;
	  }
	}
      }

      # end point
      if ($st + $size > $total_size){
	$size = $size - 1;
      }

      # move one character
      my $v = -1 * $all_struct[$st];
      for (my $j = 1; $j < $size; $j++) {
	$curr_struct[$j] = $curr_struct[$j+1] + $v;
      }

      if ($st + $size <= $total_size) {
	$curr_struct[$size] = $curr_struct[$size-1] + $all_struct[$st+$size];
      }
    }
  }

  print STDERR scalar(keys %single_counts);
  print STDERR " features found in positive sequences.\n";


  ##### Filtering features #1 ####
  # removing from positive list features that appear less than BG_FACTOR times more than expected
  # <count>/<set size> - <bg count>/<bg size> > <factor> * <bg std>/<bg size>
  # i.e., the counts of the motif in the given set is higher than expected in random set
  # by <factor> standard deviations.
  ####
  my %features_pvalue;

  if ($p_distr eq "n") { # normal
    foreach my $feature (keys %single_counts) {
      my $bg_mean = 1;
      my $bg_std = 1;
      if (exists($$bg_counts_ref{$feature})) {
	$bg_mean = $$bg_counts_ref{$feature};

	if (exists($$bg_std_ref{$feature}) and $$bg_std_ref{$feature} != 0) {
	  $bg_std = $$bg_std_ref{$feature};
	}
	else {
	  $bg_std = $bg_mean;
	}
      }
      my $zscore = ($single_counts{$feature}/$input_size - $bg_mean/$bg_size) / ($bg_std/$bg_size);
      my $pvalue = NormalStd2Pvalue($zscore);
      #print "$feature\t$zscore\t$pvalue\n";

      #if ($pvalue < $bg_factor/$total_genes) {
      if ($zscore > sqrt(1/($bg_factor/$total_genes))) {
	$features_pvalue{$feature} = $pvalue;
      }
    }
  }
  else { # binomial
    foreach my $feature (keys %single_counts) {
      my $bg_mean = exists($$bg_counts_ref{$feature}) ? int($$bg_counts_ref{$feature}) : 0;
      my $ref = $features_genes{$feature};
      my $k = scalar(keys %$ref);
      my $n = $k + $bg_mean;
      my $K = $total_genes;
      my $N = $bg_size + $K;
      my $pvalue = ComputeHyperPValue($k, $n, $K, $N);
      #print "$feature\t$pvalue\t($k, $n, $K, $N)\n";

      if ($pvalue < $bg_factor/$total_genes) {
	$features_pvalue{$feature} = $pvalue;
      }
    }
  }

  print STDERR scalar(keys %features_pvalue);
  print STDERR " features after filtering using negatives.\n";

  #### Filtering features #2 ####
  # features <a>,<b> co-occure if they always appear together.
  # In this case one of them is contained within the other.
  # If <a> is contained within <b>, then add <a> as a child of <b> in the tree T.
  #
  # f = r: we want to keep only the high level features (i.e, features that has no parents in the tree).
  # So we remove all the features that are contained within another, i.e., keep only the tree roots (no parents).
  #
  # f = l: we want to keep only the low level features (i.e, features that has no children in the tree).
  # So we remove all the features that contain another feature, i.e., keep only the tree leaves (no children).
  ####
  my %features;
  if ($filter ne "a") {
    my %parents;
    my %children;
    my %pair_counts;
    for(my $i = 0; $i < scalar(@features_struct); $i++) {

      if (exists $features_pvalue{$features_struct[$i]}) {
	for (my $j = $i+1; $j < scalar(@features_struct) and $features_ids[$i] == $features_ids[$j]; $j++) {

	  if (exists $features_pvalue{$features_struct[$j]} and $features_start[$j] <= $features_start[$i] and $features_end[$i] <= $features_end[$j]) {
	    $pair_counts{"$features_struct[$j]_$features_struct[$i]"}++;

	    if ($single_counts{$features_struct[$i]} == $pair_counts{"$features_struct[$j]_$features_struct[$i]"}) {
	      $children{$features_struct[$j]} = 1;
	      $parents{$features_struct[$i]} = 1;
	    }
	  }
	  elsif (exists $features_pvalue{$features_struct[$j]} and $features_start[$i] <= $features_start[$j] and $features_end[$j] <= $features_end[$i]) {
	    $pair_counts{"$features_struct[$i]_$features_struct[$j]"}++;

	    if ($single_counts{$features_struct[$j]} == $pair_counts{"$features_struct[$i]_$features_struct[$j]"}) {
	      $children{$features_struct[$i]} = 1;
	      $parents{$features_struct[$j]} = 1;
	    }
	  }
	}
      }
    }

    if ($filter eq "r") {
      foreach my $feature (keys %features_pvalue) {
	if (not exists($parents{$feature})) {
	  $features{$feature} = $features_pvalue{$feature};
	}
      }
    }
    elsif ($filter eq "l") {
      foreach my $feature (keys %features_pvalue) {
	if (not exists($children{$feature})) {
	  $features{$feature} = $features_pvalue{$feature};
	}
      }
    }
    else {
      foreach my $feature (keys %features_pvalue) {
	if ((not exists($parents{$feature})) or (not exists($children{$feature}))) {
	  $features{$feature} = $features_pvalue{$feature};
	}
      }
    }

    print STDERR scalar(keys %features);
    print STDERR " features after filtering by positions.\n";
  }
  else {
    %features = %features_pvalue;
  }

  #### Simplify features ####
  # Ignore certain information within each feature, to make the feature space smaller
  ####
  my %matching_features;
  foreach my $f (keys %features) {
    my $simple_f = simplify($f, $stem, $loop);
    if (exists $matching_features{$simple_f}) {
      my $ref = $matching_features{$simple_f};
      push(@$ref, $f);
    }
    else {
      $matching_features{$simple_f} = [$f];
    }

    my $simple_f2 = simplify($f, 2*$stem-1, 2*$loop-1);
    if ($simple_f2 ne $simple_f) {
      if (exists $matching_features{$simple_f2}) {
	my $ref = $matching_features{$simple_f2};
	push(@$ref, $f);
      }
      else {
	$matching_features{$simple_f2} = [$f];
      }
    }
  }
  print STDERR scalar(keys(%matching_features));
  print STDERR " features after simplification.\n";

  #### Scoring features ####
  # score = <gene_num> + 0.1*<len>/<max_len> + 0.01*<count>/<max_count>
  # <count> = number of features of the same length
  # For features with a single gene, the second term is ignored
  ####
  my %features_score; # <feature> => [score]
  my %features_by_score; # <score> => { [feature] [feature] ... }

  # calculate basic score = gene_num + 0.1avg_length
  my %features_by_length; # <length> => { [feature] [feature] ... }
  foreach my $m (keys(%matching_features)) {

    my $length = 0;
    my %all_gene_names;
    my $all_ref = $matching_features{$m};
    foreach my $f (@$all_ref) {
      my $hash_ref = $features_genes{$f};
      foreach my $g (keys %$hash_ref) {
	$all_gene_names{$g} = 1;
      }
      $length = $length + length($f);
    }
    my $genes_num = scalar(keys %all_gene_names);
    $length = $length/scalar(@$all_ref);
    if ($genes_num > 1) {
      $features_score{$m} = $genes_num + 0.1*($length-$min_len)/($max_len-$min_len);
    }
    else {
      $features_score{$m} = $genes_num;
    }

    # for genes with length lower than max_len, count frequency of the specific length
    if ($length < 0.95*$max_len) {
      if (exists $features_by_length{$length}) {
	my $ref = $features_by_length{$length};
	push (@$ref, $m);
      }
      else {
	$features_by_length{$length} = [$m];
      }
    }
  }

  # add length frequencies to scores
  my %length_counts; # <count> => { [feature] [feature] ... }
  my $max_count = 0;
  foreach my $len (keys %features_by_length) {
    my $ref = $features_by_length{$len};
    my $count = scalar(@$ref);

    if (exists $length_counts{$count}) {
      my $r = $length_counts{$count};
      push(@$r, @$ref);
    }
    else {
      $length_counts{$count} = [@$ref];
    }

    if ($count > $max_count) {
      $max_count = $count;
    }
  }
  foreach my $k (keys %length_counts) {
    my $ref = $length_counts{$k};

    for (my $p = 0; $p < scalar(@$ref); $p++) {
      my $m = $$ref[$p];
      my $score = $features_score{$m} + 0.01*$k/$max_count;
      $features_score{$m} = $score;

      if (exists $features_by_score{$score}) {
	my $ref = $features_by_score{$score};
	push (@$ref, $m);
      }
      else {
	$features_by_score{$score} = [$m];
      }
    }
  }

  # sort numerically descending (best score at the top of the list)
  my @sorted_scores = sort {$b <=> $a} keys(%features_by_score);
  my @found_features;
  my $count = 0;
  foreach my $k (@sorted_scores) {
    my $ref = $features_by_score{$k};
    push(@found_features, @$ref);

    $count = $count + scalar(@$ref);
    if ($count > $n) {
      last;
    }
  }

  #### Build initial models ####
  # Each feature results in two files:
  #  1. initial_model_#.tab -- The first line contains the structure, and next lines
  #     the sequences, one per line.
  #  2. motif_set_#.tab -- each line is of the format <name> <sequence> <structure>
  #     for the different sequences that match the feature.
  ###

  my $found_features_num = scalar(@found_features);
  my $initials = $found_features_num < $n ? $found_features_num : $n;
  print STDERR "Initializing models from best $initials features:\n";

  for (my $i = 0; $i < $initials; $i++) {
    my $feature = $found_features[$i];

    my $ref = $matching_features{$feature};
    my @structures;
    foreach my $f (@$ref) {
      push(@structures, $f);
    }
    print STDERR " Initial model $i: $feature (score $features_score{$feature})\n";

    # printing initial model
    open(INITIAL, ">initial_model_$i.tab") or die "Could not open initial_model_$i.tab.\n";
    my $representative = representative_motif(\%features_genes, \@structures);
    print INITIAL "$representative\n";
    my $seq_list_ref = $features_sequences{$representative};
    foreach my $s (@$seq_list_ref) {
      print INITIAL "$s\n";
    }
    close(INITIAL);

    # printing motif set
    open(SET, ">motif_set_$i.tab") or die "Could not open motif_set_$i.tab.\n";
    my $count = 0;
    foreach my $f (@structures) {
      my $seq_list_ref = $features_sequences{$f};
      foreach my $s (@$seq_list_ref) {
	print SET "$count\t$s\t$f\n";
	$count++;
      }
    }
    close(SET);
  }

  return $initials;
}

# ------------------------------------------------------------------------
# count_unique
# ------------------------------------------------------------------------
sub count_unique($) {
  my ($list_ref) = @_;

  my %hash;
  foreach my $i (@$list_ref) {
    $hash{$i} = 1;
  }

  return scalar(keys %hash);
}

# ------------------------------------------------------------------------
# round
# ------------------------------------------------------------------------
sub round($) {
  my ($num) = @_;

  my $int = int($num);
  return ($int + (($num - $int) >= 0.5));
}

# ------------------------------------------------------------------------
# build_negative_set
# ------------------------------------------------------------------------
sub build_negative_set($$$$) {
  my ($reps, $pair, $per_sequence, $positive_sequences_ref) = @_;
  my %negative_set;
  my @rkey = ( 'A', 'C', 'G', 'U' );

  # Build negative set by pairwise nucleotide distribution
  if ($pair) {
    if ($per_sequence) {
      foreach my $id (keys %$positive_sequences_ref) {
	my $base_id = $id;
	my $serial = "";
	if ($id =~ m/(.+):(.*)/g) {
	  $base_id = $1;
	  $serial = $SEP.$2;
	}

	my $seq = $$positive_sequences_ref{$id};
	my $length = length($seq);

	my %sequences = ($id => $seq);
	my @nucleotide = calculate_distribution(\%sequences, 1, 1);

	for (my $i = 0; $i < $reps; $i++) {
	  my $v = rand(1);
	  my $prev = $v < $nucleotide[0] ? 0 : $v < $nucleotide[1] ? 1 : $v < $nucleotide[2] ? 2 : 3;
	  my $seq = $rkey[$prev];
	  for (my $j = 1; $j < $length; $j++) {
	    $v = rand(1);
	    my $nuc = $v < $nucleotide[$prev*4 + 4] ? 0 : $v < $nucleotide[$prev*4 + 5] ? 1 : $v < $nucleotide[$prev*4 + 6] ? 2 : 3;
	    $seq = $seq.$rkey[$nuc];
	    $prev = $nuc;
	  }
	  $negative_set{"$base_id.$i$serial"} = $seq;
	}
      }
    }
    else {
      my @nucleotide = calculate_distribution($positive_sequences_ref, 1, 0);
      foreach my $id (keys %$positive_sequences_ref) {
	my $base_id = $id;
	my $serial = "";
	if ($id =~ m/(.+):(.*)/g) {
	  $base_id = $1;
	  $serial = $SEP.$2;
	}

	my $length = length($$positive_sequences_ref{$id});
	for (my $i = 0; $i < $reps; $i++) {
	  my $v = rand(1);
	  my $prev = $v < $nucleotide[0] ? 0 : $v < $nucleotide[1] ? 1 : $v < $nucleotide[2] ? 2 : 3;
	  my $seq = $rkey[$prev];
	  for (my $j = 1; $j < $length; $j++) {
	    $v = rand(1);
	    my $nuc = $v < $nucleotide[$prev*4 + 4] ? 0 : $v < $nucleotide[$prev*4 + 5] ? 1 : $v < $nucleotide[$prev*4 + 6] ? 2 : 3;
	    $seq = $seq.$rkey[$nuc];
	    $prev = $nuc;
	  }
	  $negative_set{"$base_id.$i$serial"} = $seq;
	}
      }
    }
  }

  # Build negative set by single nucleotide distribution
  else {
    if ($per_sequence) {
      foreach my $id (keys %$positive_sequences_ref) {
	my $base_id = $id;
	my $serial = "";
	if ($id =~ m/(.+):(.*)/g) {
	  $base_id = $1;
	  $serial = $SEP.$2;
	}

	for (my $i = 0; $i < $reps; $i++) {
	  $negative_set{"$base_id.$i$serial"} = shuffle_sequence($$positive_sequences_ref{$id});
	}
      }
    }
    else {
      my @nucleotide = calculate_distribution($positive_sequences_ref, 0, 0);

      foreach my $id (keys %$positive_sequences_ref) {
	my $base_id = $id;
	my $serial = "";
	if ($id =~ m/(.+):(.*)/g) {
	  $base_id = $1;
	  $serial = $SEP.$2;
	}

	my $length = length($$positive_sequences_ref{$id});
	for (my $i = 0; $i < $reps; $i++) {
	  my $seq = "";
	  for (my $j = 0; $j < $length; $j++) {
	    my $v = rand(1);
	    my $nuc = $v < $nucleotide[0] ? 0 : $v < $nucleotide[1] ? 1 : $v < $nucleotide[2] ? 2 : 3;
	    $seq = $seq.$rkey[$nuc];
	  }
	  $negative_set{"$base_id.$i$serial"} = $seq;
	}
      }
    }

  }
  return %negative_set;
}

# ------------------------------------------------------------------------
# calculate nucleotide distribution
# ------------------------------------------------------------------------
sub calculate_distribution($$) {
  my ($sequences_ref, $pair, $prior) = @_;
  if (not defined $prior) {
    $prior = 0;
  }

  # nucleotide distributions
  my %key = ( 'A'=> 0, 'C'=> 1, 'G'=>2, 'U'=>3 );
  my @nucleotide;

  # calculate pairwise nucleotide distribution
  if ($pair) {
    @nucleotide = ($prior,$prior,$prior,$prior, # A U G C
		   $prior,$prior,$prior,$prior, # AA AU AG AC
		   $prior,$prior,$prior,$prior, # CA CU CG CC
		   $prior,$prior,$prior,$prior, # GA GU GG GC
		   $prior,$prior,$prior,$prior);# UA UU UG UC
    my $sum = 4*$prior;

    foreach my $id (keys %$sequences_ref) {
      my $seq = $$sequences_ref{$id};
      $seq =~ tr/T/U/;
      my $length = length($seq);

      my $prev = $key{substr($seq, 0, 1)};
      $nucleotide[$prev]++;
      for (my $p = 1; $p < $length; $p++) {
	my $nuc = $key{substr($seq, $p, 1)};
	$nucleotide[$nuc]++;
	$nucleotide[($prev+1)*4 + $nuc]++;
	$prev = $nuc;
      }
      $sum += $length;
    }

    $nucleotide[0] = $nucleotide[0]/$sum;
    print STDERR "$nucleotide[0]\t";
    for(my $i = 1; $i < 4; $i++) {
      $nucleotide[$i] = $nucleotide[$i]/$sum + $nucleotide[$i-1];
      print STDERR "$nucleotide[$i]\t";
    }
    print STDERR "\n";

    for(my $k = 1; $k <= 4; $k++) {
      my $sum = 0;
      for (my $i = 0; $i < 4; $i++) {
	$sum += $nucleotide[$k*4+$i];
      }

      $nucleotide[$k*4] = $nucleotide[$k*4]/$sum;
      print STDERR "$nucleotide[$k*4]\t";
      for (my $i = 1; $i < 4; $i++) {
	$nucleotide[$k*4+$i] = $nucleotide[$k*4+$i]/$sum + $nucleotide[$k*4+$i-1];
	print STDERR "$nucleotide[$k*4+$i]\t";
      }
      print STDERR "\n";
    }
  }
  # calculate single nucleotide distribution
  else {
    @nucleotide = ($prior,$prior,$prior,$prior);# A U G C
    my $sum = 4*$prior;

    foreach my $id (keys %$sequences_ref) {
      my $seq = $$sequences_ref{$id};
      $seq =~ tr/T/U/;
      my $length = length($seq);

      my $prev = $key{substr($seq, 0, 1)};
      $nucleotide[$prev]++;
      for (my $p = 1; $p < $length; $p++) {
	my $nuc = $key{substr($seq, $p, 1)};
	$nucleotide[$nuc]++;
	$prev = $nuc;
      }
      $sum += $length;
    }

    $nucleotide[0] = $nucleotide[0]/$sum;
    print STDERR "$nucleotide[0]\t";
    for(my $i = 1; $i < 4; $i++) {
      $nucleotide[$i] = $nucleotide[$i]/$sum + $nucleotide[$i-1];
      print STDERR "$nucleotide[$i]\t";
    }
    print STDERR "\n";
  }

  return(@nucleotide);
}

# ------------------------------------------------------------------------
# shuffle_sequence(sequence)
# ------------------------------------------------------------------------
sub shuffle_sequence($) {
  my ($seq) = @_;
  my @seq_let = split (undef, $seq);
  my @shuffled_let = shuffle(@seq_let);
  my $shuffled = join ("", @shuffled_let);

  return $shuffled;
}

# ------------------------------------------------------------------------
# simplify(feature)
# ------------------------------------------------------------------------
sub simplify($$$) {
  my ($feature, $stem, $loop) = @_;

  # ignore buldges of single nucleotide
  #$feature =~ s/\(.\(/\(\(/g;
  #$feature =~ s/\).\)/\)\)/g;

  # ignore deviations of $stem nucleotide in stem length
  $feature =~ s/\({1,$stem}/\[/g;
  $feature =~ s/\){1,$stem}/\]/g;

  # ignore deviations of $loop nucleotide in loop length
  $feature =~ s/\.{1,$loop}/\*/g;

  return $feature;
}

# ------------------------------------------------------------------------
# find_features($$@)
# ------------------------------------------------------------------------
sub find_features($$@) {
  my ($min_len, $max_len, @list) = @_;

  my %counts;
  foreach my $struct (@list) {
    my $total_size = length($struct);
    my $max_st = $total_size - $min_len;
    my $size = $max_len;
    if ($size > $total_size){
      $size = $total_size;
    }

    my $struct_num = $struct;
    $struct_num =~ s/\(/1 /g;
    $struct_num =~ s/\)/-1 /g;
    $struct_num =~ s/\./0 /g;
    my @all_struct = split(/ /, $struct_num); # the entire structure
    unshift(@all_struct, 0);

    my @curr_struct; # the current part of the structure
    @curr_struct[0] = 0;
    for (my $i = 1; $i <= $size; $i++) {
      $curr_struct[$i] = $curr_struct[$i-1] + $all_struct[$i];
    }

    # find features
    for (my $st = 1; $st <= $max_st; $st++) { # possible starting points
      for (my $k = $min_len; $k <= $size; $k++) { # possible feature lengths

	# feature: ends with zero, and never reach negative values
	# drop features that contain points in each of the edges
	my @mot = @curr_struct;
	splice(@mot, $k+1);
	my $str_mot = substr($struct, $st-1, $k);
	if (legal_feature($str_mot, @mot)) {
	  $counts{$str_mot}++;
	}
      }

      # end point
      if ($st + $size > $total_size){
	$size = $size - 1;
      }

      # move one character
      my $v = -1 * $all_struct[$st];
      for (my $j = 1; $j < $size; $j++) {
	$curr_struct[$j] = $curr_struct[$j+1] + $v;
      }

      if ($st + $size <= $total_size) {
	$curr_struct[$size] = $curr_struct[$size-1] + $all_struct[$st+$size];
      }
    }
  }

  return %counts;
}

# ------------------------------------------------------------------------
# legal_feature(feature_string, list)
# ------------------------------------------------------------------------
sub legal_feature($@) {
  my ($str_feature, @feature) = @_;
  my $s = @feature;

  # last element must be zero
  if ($feature[$s-1] != 0) {
    return(0);
  }

  # no negative values
  my $i = 0;
  while ($i < $s and $feature[$i] >= 0) {
    $i = $i + 1;
  }

  # feature cannot contain points in the edges
  # i.e. cannot extand a feature by points
  if (($str_feature =~ m/^\.(.*)/g) or ($str_feature =~ m/(.*)\.$/g)) {
    return(0);
  }

  # feature cannot contain lonely base pairs
  if (($str_feature =~ m/\.\(\./g) or ($str_feature =~ m/\.\)\./g) or ($str_feature =~ m/^\(\./g) or ($str_feature =~ m/\.\)$/g)) {
    return(0);
  }

  return($i == $s);
}

# ------------------------------------------------------------------------
# Find a single structure to represent a list of structures
# Method: select the structure that match the largest number of genes
# ------------------------------------------------------------------------
sub representative_motif ($$) {
  my ($gene_counts_ref, $structures_ref) = @_;

  my @structures = @$structures_ref;
  my $size = scalar(@structures);
  if ($size == 1) {
    return $structures[0];
  }

  my %gene_counts = %$gene_counts_ref;
  my $max_struct = $structures[0];
  my $hash_ref = $gene_counts{$max_struct};
  my $max_counts = scalar(keys %$hash_ref);

  for (my $i = 1; $i < $size; $i++) {
    my $struct = $structures[$i];
    $hash_ref = $gene_counts{$struct};
    my $counts = scalar(keys %$hash_ref);

    if (($counts > $max_counts) or ($counts == $max_counts and length($struct) > length($max_struct))) {
      $max_struct = $struct;
      $max_counts = $counts;
    }
  }

  return $max_struct;
}

# ------------------------------------------------------------------------
# Fold seuqneces
# ------------------------------------------------------------------------
sub rna_fold($$$@) {
  my ($count, $file, $type, $subopt, @output_ref) = @_;
  my $results;
  my @folds;

  if ($type == 1) {
    $results = `$VIENNA_EXE_DIR/RNAsubopt -e $subopt -noLP < $file; /bin/rm *_ss.ps;`;
    my @prog_result = split (">", $results);
    for (my $i = 0; $i < scalar(@prog_result); $i++) {
      my $line = $prog_result[$i];
      my @data = split ("\n", $line);

      $data[0] =~ m/ (.+) \[.+\]/g;
      my $id = $1;
      $data[1] =~ m/^([ACGTU]+) .+/g;
      my $seq = $1;
      $seq =~ tr/T/U/;

      for (my $j = 2; $j < scalar(@data); $j++) {
	$data[$j] =~ m/^([\(\)\.]+) .+/g;
	my $fold = $1;
	foreach my $ref (@output_ref) {
	  print $ref "$id\t$seq\t$fold\n";
	}
	push(@folds, $fold);
      }
    }
  }
  elsif ($type == 2) {
    my $cmd = "$CONTRAFOLD_EXE_DIR/contrafold predict tmp_seqfile_$$";
    my $result = `$cmd`;
    my ($id, $seq, $fold) = split(/\n/, $result);
    $id =~ m/>(.+)/g;
    if (defined $1) {
      $id = $1;
    }

    foreach my $ref (@output_ref) {
      print $ref "$id\t$seq\t$fold\n";
    }
    push(@folds, $fold);
  }
  else {
    $results = `$VIENNA_EXE_DIR/RNAfold -noLP < $file; /bin/rm *_ss.ps;`;
    my @prog_result = split (/\n/, $results);
    for (my $i = 0; $i < $count; $i++) {
      my $id = shift (@prog_result);       # id
      $id =~ m/>(.+)/g;
      $id = $1;

      my $seq = shift (@prog_result);	 # sequence
      my $fold = shift (@prog_result);     # structure
      $fold =~ m/([\(\)\.]+)/g;
      $fold = $1;
      foreach my $ref (@output_ref) {
	print $ref "$id\t$seq\t$fold\n";
      }
      push(@folds, $fold);
    }
  }

  return @folds;
}

# -----------------------------------------------------------------------------
# clustering
# -----------------------------------------------------------------------------
sub clustering($$) {
  my ($features_list_ref, $output_file) = @_;
  my @features_list = @$features_list_ref;

  # calculating distances, creating distance file
  my @ids;
  open(STRFILE, ">tmp_calc_distances_$$.tab") or die("Could not open tmp_calc_distances.\n");
  for(my $i = 0; $i < scalar(@features_list); $i++) {
    for (my $j = $i+1; $j < scalar(@features_list); $j++) {
      print STRFILE "$features_list[$i]\n$features_list[$j]\n";
      push (@ids, "$i\t$j");
    }
  }
  close(STRFILE);
  my $r = `$VIENNA_EXE_DIR/RNAdistance -D$METRIC < tmp_calc_distances_$$.tab | cut -d " " -f 2 | tr "\n" "\t"`;
  my @distances = split("\t", $r);

  open(DIST, ">feature_distances_$$.tab") or die ("Could not open feature_distances.tab.\n");
  my $max_distance = 0;
  for (my $k = 0; $k < scalar(@distances); $k++) {
    if ($distances[$k] <= $DMAX) {
      print DIST "$ids[$k]\t$distances[$k]\n";
      if ($distances[$k] > $max_distance) {
	$max_distance = $distances[$k];
      }
    }
  }
  close(DIST);

  # running clustering
  open(XML, ">tmp_xml_$$.map") or die("Could not open tmp_xml_$$.map.\n");
  print XML "<?xml version=\"1.0\"?>\n\n";
  print XML "<MAP>\n";
  print XML "  <RunVec>\n";
  print XML "    <Run Name=\"Cluster\" Logger=\"logger.log\">\n";
  print XML "      <Step Type=\"LoadGeneGraph\"\n";
  print XML "            Name=\"LoadGeneGraph\"\n";
  print XML "            GeneGraphName=\"gene_graph\"\n";
  print XML "            File=\"feature_distances_$$.tab\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"Clustering\"\n";
  print XML "            Name=\"Cluster\"\n";
  print XML "            GeneGraphName=\"gene_graph\"\n";
  print XML "            NumClusters=\"1\"\n";
  print XML "            LinkageMethod=\"$LINKAGE_METHOD\"\n";
  print XML "            LinkagePercent=\"$PERCENTILE\"\n";
  print XML "            Method=\"Hierarchical\"\n";
  print XML "            MaxMergesPerNode=\"20\"\n";
  print XML "  	         OutputFile=\"$output_file\">\n";
  print XML "      </Step>\n";
  print XML "    </Run>\n";
  print XML "  </RunVec>\n";
  print XML "</MAP>\n";
  close(XML);

  &RunGenie("", "", "tmp_xml_$$.map", "", "", "");
  system("/bin/rm logger.log tmp_calc_distances_$$.tab feature_distances_$$.tab;"); #tmp_xml_$$.map

  return $max_distance;
}

# ------------------------------------------------------------------------
# Learn rna model
# ------------------------------------------------------------------------
sub learn_model($$) {
  my ($bg_model, $initial_model, $initial_motif_set, $training_set, $training_set_all, $model, $output, $alignment, $cons) = @_;

  open(XML, ">tmp_xml_$$.map") or die "cannot create tmp_xml_$$.map \n";
  print XML "<?xml version=\"1.0\"?>\n\n";
  print XML "<MAP>\n";
  print XML "  <RunVec>\n";
  print XML "    <Run Name=\"RNAmodel\" Logger=\"logger.log\">\n";
  print XML "      <Step Type=\"LoadRnaBgParams\"\n";
  print XML "            Name=\"LoadRnaBgParams\"\n";
  print XML "            RnaBgModelName=\"bg_model\"\n";
  print XML "            File=\"$bg_model\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LoadRnaModel\"\n";
  print XML "            Name=\"LoadRnaModel\"\n";
  print XML "            RnaModelName=\"model\"\n";
  print XML "            File=\"$initial_model\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LoadRnaData\"\n";
  print XML "            Name=\"LoadRnaMotifs\"\n";
  print XML "            RnaDataName=\"motif_set\"\n";
  print XML "            File=\"$initial_motif_set\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LearnRnaModelParams\"\n";
  print XML "            Name=\"TrainModel\"\n";
  print XML "            RnaModelName=\"model\"\n";
  print XML "            RnaBgModelName=\"bg_model\"\n";
  print XML "            RnaDataName=\"motif_set\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LoadRnaData\"\n";
  print XML "            Name=\"LoadRnaMotifs\"\n";
  print XML "            RnaDataName=\"training_set\"\n";
  print XML "            File=\"$training_set\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LearnRnaModelParams\"\n";
  print XML "            Name=\"TrainModel\"\n";
  print XML "            RnaModelName=\"model\"\n";
  print XML "            RnaBgModelName=\"bg_model\"\n";
  print XML "            RnaDataName=\"training_set\"\n";
  print XML "            OutputFile=\"$model\">\n";
  print XML "      </Step>\n";
  if (defined $alignment) {
    print XML "      <Step Type=\"MatchRnaModel\"\n";
    print XML "            Name=\"MatchModel\"\n";
    print XML "            RnaModelName=\"model\"\n";
    print XML "            RnaBgModelName=\"bg_model\"\n";
    print XML "            RnaDataName=\"training_set\"\n";
    print XML "            RnaBestAlignment=\"true\"\n";
    print XML "            OutputFile=\"$alignment\">\n";
    print XML "      </Step>\n";
  }
  if (defined $output) {
    print XML "      <Step Type=\"LoadRnaData\"\n";
    print XML "            Name=\"LoadRnaMotifs\"\n";
    print XML "            RnaDataName=\"training_set_all\"\n";
    print XML "            File=\"$training_set_all\">\n";
    print XML "      </Step>\n";
    print XML "      <Step Type=\"MatchRnaModel\"\n";
    print XML "            Name=\"MatchModel\"\n";
    print XML "            RnaModelName=\"model\"\n";
    print XML "            RnaBgModelName=\"bg_model\"\n";
    print XML "            RnaDataName=\"training_set_all\"\n";
    print XML "            OutputFile=\"$output\">\n";
    print XML "      </Step>\n";
  }
  if (defined $cons) {
    print XML "      <Step Type=\"PrintRnaModel\"\n";
    print XML "            Name=\"PrintModel\"\n";
    print XML "            RnaModelName=\"model\"\n";
    print XML "            RnaBgModelName=\"bg_model\"\n";
    print XML "        	   OutputFile=\"$cons\">\n";
    print XML "      </Step>\n";
  }
  print XML "    </Run>\n";
  print XML "  </RunVec>\n";
  print XML "</MAP>\n";
  close(XML);

  &RunGenie("", "", "tmp_xml_$$.map", "", "", "");
  system("/bin/rm logger.log;"); #tmp_xml_$$.map
}

# ------------------------------------------------------------------------
# Match rna model
# ------------------------------------------------------------------------
sub match_model($$$$) {
  my ($bg_model, $model, $test_set, $output, $best) = @_;

  open(XML, ">tmp_xml_$$.map") or die "cannot create tmp_xml_$$.map \n";
  print XML "<?xml version=\"1.0\"?>\n\n";
  print XML "<MAP>\n";
  print XML "  <RunVec>\n";
  print XML "    <Run Name=\"RNAmodel\" Logger=\"logger.log\">\n";
  print XML "      <Step Type=\"LoadRnaBgParams\"\n";
  print XML "            Name=\"LoadRnaBgParams\"\n";
  print XML "            RnaBgModelName=\"bg_model\"\n";
  print XML "            File=\"$bg_model\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LoadRnaModelParams\"\n";
  print XML "            Name=\"LoadRnaModelParams\"\n";
  print XML "            RnaModelName=\"model\"\n";
  print XML "            File=\"$model\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"LoadRnaData\"\n";
  print XML "            Name=\"LoadRnaMotifs\"\n";
  print XML "            RnaDataName=\"test_set\"\n";
  print XML "            File=\"$test_set\">\n";
  print XML "      </Step>\n";
  print XML "      <Step Type=\"MatchRnaModel\"\n";
  print XML "            Name=\"MatchModel\"\n";
  print XML "            RnaModelName=\"model\"\n";
  print XML "            RnaBgModelName=\"bg_model\"\n";
  if (defined $best) {
    print XML "            RnaBestAlignment=\"true\"\n";
  }
  print XML "            RnaDataName=\"test_set\"\n";
  print XML "            OutputFile=\"$output\">\n";
  print XML "      </Step>\n";
  print XML "    </Run>\n";
  print XML "  </RunVec>\n";
  print XML "</MAP>\n";
  close(XML);

  &RunGenie("", "", "tmp_xml_$$.map", "", "", "");
  system("/bin/rm logger.log;");#tmp_xml_$$.map
}

# ------------------------------------------------------------------------
# Calculate scores for each motif
# ------------------------------------------------------------------------
sub calc_scores($$$$) {
  my ($input_file, $model_file, $cons_file) = @_;

  # Read input file
  system("cat $input_file | tr \"_\" \"\t\" | cut -f 2,4 | sort -k 2 -n -r > $input_file.sort");
  open (INPUT, "$input_file.sort") or die ("cannot open $input_file \n");
  my @FPR;
  my @TPR;
  my $TP = 0;
  my $FP = 0;
  my $wpos = 0;
  my $wneg = 0;
  my $pos_sum = 0;

  push(@FPR, 0);
  push(@TPR, 0);
  while (<INPUT>) {
    chomp $_;
    if ($_ =~ m/^([np])\t(.+)/g) {
      my $id = $1;
      my $score = $2;
      if ($id eq "n") {
	$FP++;
	if ($score <= 0) {
	  $wneg++;
	}
      }
      else {
	$TP++;
	if ($score > 0) {
	  $wpos++;
	}
	$pos_sum += $score;
      }

      push(@FPR, $FP);
      push(@TPR, $TP);
    }
  }

  # calculate auc
  my $auc = 0;
  if ($FP != 0 and $TP != 0) {

    for (my $i = 0; $i < scalar(@FPR); $i++) {
      $FPR[$i] = $FPR[$i]/$FP;
      $TPR[$i] = $TPR[$i]/$TP;
    }

    for (my $i = 1; $i < scalar(@FPR); $i++) {
      $auc += $TPR[$i] * ($FPR[$i] - $FPR[$i-1]); # for each square: s=TPR[i]*(FPR[i]-FPR[i-1])
    }
  }
  elsif ($FP == 0) {
    $auc = 1;
  }
  else {
    $auc = 0;
  }

  # [no. of below-zero negative examples] + [no. of above-zero positive examples]
  my $opp = $wpos + $wneg;

  # [sum of positive examples score]/[model size]
  my $sum;
  if (defined $model_file) {
    $sum = $pos_sum/(`cat $model_file | grep E | tail -1 | cut -f 2`+1);
  }

  # consensus
  my $cons;
  if (defined $cons_file) {
    $cons = `cat $cons_file | cut -f 3`;
  }

  system("/bin/rm $input_file.sort");
  return ($auc, $opp, $sum, $cons);
}

# =============================================================================
# EOF
# =============================================================================
