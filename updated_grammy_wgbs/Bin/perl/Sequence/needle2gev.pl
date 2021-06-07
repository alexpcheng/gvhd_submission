#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


if ($ARGV[0] eq "--help") {
  print STDOUT <DATA>;
  exit;
}

my $file_ref;
my $file = $ARGV[0];
my $is_input_by_stdin = (length($file) < 1 or $file =~ /^-/);
if ( $is_input_by_stdin ) {
  $file_ref = \*STDIN;
}
else {
  open(FILE, $file) or die("Could not open file '$file'.\n");
  $file_ref = \*FILE;
}


#
# Loading args:
#

my %args = load_args(\@ARGV);

my $ref_is_second = get_arg("ref_is_second", 0, \%args);

my $ref_start_pos = get_arg("ref_start_pos", "", \%args);
die "ERROR - ref_start_pos not given.\n" if ( $ref_start_pos eq "" );
die "ERROR - given ref_start_pos ($ref_start_pos) is negative.\n" if ( $ref_start_pos < 0 );

my $ref_end_pos = get_arg("ref_end_pos", "", \%args);
die "ERROR - ref_end_pos not given.\n" if ( $ref_end_pos eq "" );
die "ERROR - given ref_end_pos ($ref_end_pos) is negative.\n" if ( $ref_end_pos < 0 );

my $seq_name = get_arg("seq_name", "", \%args);
die "ERROR - seq_name not given.\n" if ( $seq_name eq "" );

my $ind_name = get_arg("individual_name", "", \%args);
die "ERROR - individual_name not given.\n" if ( $ind_name eq "" );


#
# Output defs:
#

my $delim = "\t";
my $endl  = "\n";
my $haplotype_snp_str = "HaplotypeSNP";
my $insertion_str = "Insertion";
my $deletion_str = "Deletion";


#
# Reading alignment:
#

my $ref_seq_name = "";
my $other_seq_name = "";
my $aligned_ref_seq = "";
my $aligned_other_seq = "";
my $first_line = 1;
my $aligned_ref_subseq_length = "";
my $aligned_other_subseq_length = "";

while (<$file_ref>) {
  chomp;

  if ( $first_line ) {
    my @line = split(/\t/,$_);
    if ( $ref_is_second ) {
      $other_seq_name = $line[0];
      $ref_seq_name = $line[1];
    }
    else {
      $ref_seq_name = $line[0];
      $other_seq_name = $line[1];
    }
    $first_line = 0;
  }
  elsif ( $_ =~ /^$ref_seq_name/ ) {
    my @line = split(/\s+/,$_);
    $aligned_ref_seq .= $line[2];
    $aligned_ref_subseq_length = $line[3];
  }
  elsif ( $_ =~ /^$other_seq_name/ ) {
    my @line = split(/\s+/,$_);
    $aligned_other_seq .= $line[2];
    $aligned_other_subseq_length = $line[3];
  }
}
close $file_ref unless ( $is_input_by_stdin );

die "ERROR - aligned_ref_subseq_length is $aligned_ref_subseq_length, not concordant with given reference start and end positions [$ref_start_pos,$ref_end_pos].\n" unless ( $ref_end_pos - $ref_start_pos + 1 == $aligned_ref_subseq_length );

die "ERROR - expected an alignment of 'reference' and 'other' sub-sequences of the same length. aligned_ref_subseq_length == $aligned_ref_subseq_length, aligned_other_subseq_length == $aligned_other_subseq_length.\n" unless ( $aligned_ref_subseq_length == $aligned_other_subseq_length );

my $alignment_length = length($aligned_ref_seq);
die "ERROR - aligned_ref_seq and aligned_other_seq are not of the same length.\n" unless ( $alignment_length == length($aligned_other_seq) );


#
# Parsing alignment and printing in .gev format:
#

my @aligned_ref = split("", $aligned_ref_seq);
my @aligned_other = split("", $aligned_other_seq);

my $curr_insertion_ref_pos = -1;
my $curr_insertion = "";

my $curr_deletion_ref_start = -1;
my $curr_deletion_length = 0;

my $curr_ref_pos = $ref_start_pos - 1 ;

for ( my $alignment_index = 0; $alignment_index < $alignment_length ; $alignment_index++ ) {
  $curr_ref_pos++ unless ( $aligned_ref[$alignment_index] =~ /-/ );

  if ( $aligned_ref[$alignment_index] eq $aligned_other[$alignment_index] ) {
      OutputCurrentInsertionIfExists();
      OutputCurrentDeletionIfExists();
  }

  elsif ( $aligned_ref[$alignment_index] eq '-' ) { # insertion into ref
    if ( $curr_insertion_ref_pos == -1 ) {
      OutputCurrentDeletionIfExists();
      $curr_insertion_ref_pos = $curr_ref_pos;
    }
    $curr_insertion .= $aligned_other[$alignment_index];
  }

  elsif ( $aligned_other[$alignment_index] eq '-' ) { # deletion in ref
    if ( $curr_deletion_ref_start == -1 ) {
      OutputCurrentInsertionIfExists();
      $curr_deletion_ref_start = $curr_ref_pos;
    }
    $curr_deletion_length++;
  }

  elsif ( $aligned_ref[$alignment_index] ne $aligned_other[$alignment_index] ) { # haplotype SNP
      OutputCurrentInsertionIfExists();
      OutputCurrentDeletionIfExists();
      print $seq_name. $delim . $ind_name . $delim . $curr_ref_pos . $delim . $curr_ref_pos . $delim . $haplotype_snp_str . $delim . $aligned_other[$alignment_index] . $endl;
  }
}

OutputCurrentInsertionIfExists();

#
# End of main script.
#

sub OutputCurrentInsertionIfExists
{
  if ( $curr_insertion ne "" ) {
    print $seq_name. $delim . $ind_name . $delim . $curr_insertion_ref_pos . $delim . $curr_insertion_ref_pos . $delim . $insertion_str . $delim . $curr_insertion . $endl;
    $curr_insertion = "";
    $curr_insertion_ref_pos = -1;
  }
}

sub OutputCurrentDeletionIfExists
{
  if ( $curr_deletion_length > 0 ) {
    print $seq_name. $delim . $ind_name . $delim . $curr_deletion_ref_start . $delim .($curr_deletion_ref_start + $curr_deletion_length - 1) . $delim . $deletion_str . $endl;
    $curr_deletion_length = 0;
    $curr_deletion_ref_start = -1;
  }
}


#
# End
#

__DATA__

needle2gev.pl <needle.pl output file>

  --help:                    Prints this message.

  -ref_is_second:            If this flag is set, then the second sequence in the global alignment is considered
                             to be the reference. Else, the first is the reference.

  -ref_start_pos <int>:      0-based index of the start position in the reference sequence.
  -ref_end_pos <int>:        0-based index of the end position in the reference sequence.

  -seq_name <str>:           Name of sequence, to be printed in the first column of the output.
  -individual_name <str>:    Individual name, to be printed in the second column of the output.

