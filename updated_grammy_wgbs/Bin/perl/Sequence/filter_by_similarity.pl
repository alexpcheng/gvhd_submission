#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";

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
my $similarity = get_arg("similarity", 0.8, \%args);


my @sequences;
my @ids;
while (<$file_ref>) {
  chomp $_;
  my ($id, $seq) = split("\t", $_);

  push (@sequences, $seq);
  push (@ids, $id);
}

my @filtered_ids = filter_by_sequence_similarity(\@sequences, $similarity);

foreach my $i (@filtered_ids) {
  print "$ids[$i]\t$sequences[$i]\n";
}



# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Filter seuqence list by similarity
# ------------------------------------------------------------------------
sub filter_by_sequence_similarity($$) {
  my ($seq_ref, $identity) = @_;

  my @ids;
  for (my $i = 0; $i < scalar(@$seq_ref); $i++) {
    push(@ids, $i);
  }

  my @final_ids;
  while (scalar(@ids) > 0) {
    my @new_ids;

    # create sequence fasta file
    open (OUT, ">sequences_$$.stab") or die "Cannot open sequences.fasta\n";
    my $k = pop(@ids);
    my $len = length($$seq_ref[$k]);
    print OUT "$k\t$$seq_ref[$k]\n";

    my $align = 0;
    foreach my $i (@ids) {
      my $l = length($$seq_ref[$i]);
      if (($l < $len and $l/$len < $identity) or ($l > $len and $len/$l < $identity)){
	push (@new_ids, $i);	
      }
      else {
	$align = 1;
	print OUT "$i\t$$seq_ref[$i]\n";
      }
    }
    close(OUT);

    # pairwise alignment (global)
    if ($align) {
      my $output = `cat sequences_$$.stab | needle.pl | cut -f 2,3 | tr "/" "\t" | modify_column.pl -c 1 -dc 2 | filter.pl -c 1 -max $identity | cut -f 1 | tr "\n" "\t"`; # [Subject ids]
      push(@new_ids, split ("\t", $output));
    }
    push(@final_ids, $k);
    @ids = @new_ids;

    system("/bin/rm sequences_$$.stab");
  }

  return (@final_ids);
}

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

filter_by_similarity.pl <file_name>

filter sequences in a give stab file to sequences with less then % similarity.

OPTIONS:
  -similarity <num>         filter sequences with more than <num> sequence similarity (Default = 0.8).
