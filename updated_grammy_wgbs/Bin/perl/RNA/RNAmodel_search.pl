#!/usr/bin/perl

# =============================================================================
# Include
# =============================================================================
use strict;
require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/RNA/RNAmodel.pl";

my $BG_MODEL = "$ENV{GENIE_HOME}/Runs/Folding/Rabani06/Model/BG_model/bg.tab";

# =============================================================================
# Main part
# =============================================================================

if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my $input_file = $ARGV[0];
if (length($input_file) < 1 or $input_file =~ /^-/) {
  open(INF, ">tmp_inputfile_$$.tab") or die "Cannot create input file\n";
  while(<STDIN>) {
    print INF "$_";
  }
  close(INF);
  $input_file = "tmp_inputfile_$$.tab";
}

my %args = load_args(\@ARGV);
my $threshold = get_arg("t", 0, \%args);
my $bg_file = get_arg("bg", "$BG_MODEL", \%args);
my $cm_file = get_arg("cm", 0, \%args);
if (not $cm_file) {
  print STDERR "Error. Must give a CM file\n";
  exit(1);
}

# matching model to sequences
match_model($bg_file, $cm_file, $input_file, "tmp_outfile_$$.tab", 1);

# printing output
open(OUTF, "tmp_outfile_$$.tab") or die "Cannot read output file\n";
while (<OUTF>) {
  chomp $_;
  my @list = split("\t", $_);
  my $seq = <OUTF>;
  chomp $seq;
  $seq =~ s/-//g;
  my $struct = <OUTF>;
  chomp $struct;
  $struct =~ s/-//g;
  my $model = <OUTF>;

  if ($list[2] > $threshold) {
    $list[1] =~ m/(.+):(\d+)/g;
    $list[3] += $2;
    $list[4] += $2;
    print "$1\t$list[2]\t$list[3]\t$list[4]\t$seq\t$struct\n";
  }
}
close(OFILE);

system("/bin/rm -rf tmp_*file_$$.tab");

# =============================================================================
# Subroutines
# =============================================================================

# ------------------------------------------------------------------------
# Help message
# ------------------------------------------------------------------------
__DATA__

RNAmodel_search.pl <input file> [options]

  RNAmodel_search.pl reads input sequences and structures from stdin and
  search for a given CM model in these sequences.

  Input set should be given in the format:
    <id>:<index> <sequence> <structure>
  If each id contains only a single instance, <index> can be omitted.

OPTIONS
  -cm <file>                Covariance model file (produced by RNAmotif_finder.pl).
  -t <num>                  Print only matches with score >= <num> (Default = 0).
  -fold  <split>,<overlap>  Ignore input folds. Use Vienna RNAfold for folding.
                            Fold the sequences in segments of size <split>, with overlap of
                            <overlap> between segments.
  -bg <file>                Background model probabilities (if not specified use default set).


