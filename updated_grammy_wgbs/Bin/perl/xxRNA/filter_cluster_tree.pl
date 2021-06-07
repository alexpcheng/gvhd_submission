#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";


# =============================================================================
# Main part
# =============================================================================
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
  open(FILE, "../".$file_name) or die("Could not open $file_name.\n");
  $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);
my $debug = get_arg ("debug", 0, \%args);
my $full = get_arg("f", 0, \%args);
my $sort_by = get_arg ("s", "a", \%args);


# read input
my @lists;
my @scores;
my @sizes;
my %scores_for_sort;
while (<STDIN>) {
  chomp $_;

  my ($id, $size, $score, $list) = split("\t", $_);
  $lists[$id] = $list;
  $scores[$id] = $score;
  $sizes[$id] = $size;

  if (defined $scores_for_sort{$score}) {
    my $ref = $scores_for_sort{$score};
    push(@$ref, $id);
  }
  else {
    $scores_for_sort{$score} = [$id];
  }
}

# sort by score
my @sorted_scores;
if ($sort_by eq "a") {
  @sorted_scores = sort {$a <=> $b} keys %scores_for_sort;
}
else {
  @sorted_scores = sort {$b <=> $a} keys %scores_for_sort;
}

# print selected clusters
my %ids_to_use;
for(my $i = 0; $i < scalar(@lists); $i++) {
  $ids_to_use{$i} = 1;
}

if ($full) {
  foreach my $score (@sorted_scores) {
    my $ref = $scores_for_sort{$score};

    foreach my $id (@$ref) {
      if ($ids_to_use{$id} == 0) {
	next;
      }

      my $list = $lists[$id];
      my @list_array = split(";", $list);
      print "$id\t$sizes[$id]\t$score\t$list\n";

      foreach my $i (keys %ids_to_use) {
	my $check_list = $lists[$i];
	my @check_list_array = split(";", $check_list);
	if ($ids_to_use{$i} and ($check_list =~ m/$list/g or $list =~ m/$check_list/g or compare_lists(\@list_array, \@check_list_array) >= 0)) {
	  $ids_to_use{$i} = 0;
	}
      }
    }
  }
}
else {
  foreach my $score (@sorted_scores) {
    my $ref = $scores_for_sort{$score};

    foreach my $id (@$ref) {
      if ($ids_to_use{$id} == 0) {
	next;
      }

      my $list = $lists[$id];
      print "$id\t$sizes[$id]\t$score\t$list\n";

      foreach my $i (keys %ids_to_use) {
	my $check_list = $lists[$i];
	if ($ids_to_use{$i} and ($check_list =~ m/$list/g or $list =~ m/$check_list/g)) {
	  $ids_to_use{$i} = 0;
	}
      }
    }
  }
}


# =============================================================================
# Subroutines
# =============================================================================

# --------------------------------------------------------
# Compare two lists of strings
# return:  0 if the lists are equal
#          1 list1 contains list2
#          2 list2 contains list1
#         -1 otherwise
# --------------------------------------------------------
sub compare_lists($$) {
  my ($ref1, $ref2) = @_;

  my %counts;
  my $sum1;
  my $sum2;
  foreach my $i (@$ref1) {
    $counts{$i}++;
  }
  foreach my $i (@$ref2) {
    $counts{$i}++;
    $sum2 += $counts{$i};
  }
  foreach my $i (@$ref1) {
    $sum1 += $counts{$i};
  }

  my $c1 = $sum2 == 2*scalar(@$ref2); # list1 contains list2
  my $c2 = $sum1 == 2*scalar(@$ref1); # list2 contains list1

  if ($c1 and $c2) {
    return 0;
  }
  elsif ($c1) {
    return 1;
  }
  elsif ($c2) {
    return 2;
  }
  else {
    return -1;
  }
}

# --------------------------------------------------------
# help message
# --------------------------------------------------------

__DATA__

filter_cluster_tree.pl [file]

 Input: <id> <size> <score> <list of members>

 Filter containing/contained clusters with lower scores from the list.

 Note:
  - Id must be a number (integer).
  - By default assume each group of members will always appear at the same order
    (unless -f is used, and then a full inclusion check is performed).

Options:
  -s [d/a]    sort scores descending or ascending (default=ascending)
  -f          Use full inclusion check between clusters.
  -debug      debug mode.
