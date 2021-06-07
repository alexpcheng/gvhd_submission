#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


# reading arguments
if ($ARGV[0] eq "--help")
{
   print STDOUT <DATA>;
   exit;
}

my $file_name = $ARGV[0];
shift(@ARGV);
die "ERROR - input stab file name not given\n" if (length($file_name) < 1 or $file_name =~ /^-/);

my %args = load_args(\@ARGV);

my $kmer_length = get_arg("kmer_length", 3, \%args);
my $needle_out_file = get_arg("needle_out_file", "", \%args);

my $output_type = get_arg("output_type", "CORRESPONDING_KMER_PAIRS", \%args);
die "ERROR - illegal 'output_type' ($output_type)\n" unless ( $output_type eq "CORRESPONDING_KMER_PAIRS" or $output_type eq "SORTED_KMER_PAIRS" or $output_type eq "KMER_COUNTS_PER_INPUT_SEQ" or $output_type eq "KMER_SNP_AND_INDEL_COUNTS_PER_INPUT_SEQ" or $output_type eq "KMER_SNP_OR_INDEL_WITH_POSITION_PER_INPUT_SEQ" );

my $no_headers = get_arg("no_headers", 0, \%args);
my $use_center = get_arg("use_center", 0, \%args);

die "ERROR - given 'use_center' value ($use_center) is smaller than the 'kmer_length' ($kmer_length)\n" if ( $use_center and $use_center < $kmer_length );

my $rand = int(rand(100000));
my $needle_res_file = "tmp_needle_res_" . $rand;

# run needle.pl:
system("needle.pl $file_name > $needle_res_file");

# parse needle.pl output:
open(NEEDLE_RES, $needle_res_file) or die("ERROR - failed to open needle.pl output file '$needle_res_file'\n");

my $seq1_name = "";
my $seq2_name = "";

my $aligned_seq1 = "";
my $aligned_seq2 = "";
my $alignment_symbols_seq = "";

my $first_line = 1;
my $next_line_is_alignment_symbols = 0;

while (<NEEDLE_RES>) {
  chomp;

  if ( $first_line ) {
    my @line = split(/\t/,$_);
    $seq1_name = $line[0];
    $seq2_name = $line[1];
    $first_line = 0;
  }
  elsif ( $_ =~ /^$seq1_name/ ) {
    my @line = split(/\s+/,$_);
    $aligned_seq1 .= $line[2];
    $next_line_is_alignment_symbols = 1;
  }
  elsif ( $_ =~ /^$seq2_name/ ) {
    my @line = split(/\s+/,$_);
    $aligned_seq2 .= $line[2];
  }

# FIXME - currently not using alignment symbols.
# Also, there is a bug: if first alignmene sybols are spaces (alignment starts with deletions/insertions)
# then they will not be picked up (see regexp below).
#
#  elsif ( $next_line_is_alignment_symbols ) {
#    my $align_symbols = $_;
#    $align_symbols =~ s/^\s+//g;
#    $alignment_symbols_seq .= $align_symbols;
#    $next_line_is_alignment_symbols = 0;
#  }

}
close NEEDLE_RES;

if ( $needle_out_file ne "" ) {
  system("mv $needle_res_file $needle_out_file");
}
else {
  unlink $needle_res_file;
}

#print $aligned_seq1 . "\n";
#print $alignment_symbols_seq . "\n";
#print $aligned_seq2 . "\n";

my $alignment_length = length($aligned_seq1);
die "ERROR - needle output alignment sequences are not of the same length\n" if ( $alignment_length != length($aligned_seq2) );

print "$seq1_name\t$seq2_name\n" if ( $output_type eq "CORRESPONDING_KMER_PAIRS" and not $no_headers );

my $first = 0;
my $last = $alignment_length - $kmer_length;
if ( $use_center ) {
  $first = int( ($alignment_length - $use_center) / 2 );
  $last = int( ($alignment_length + $use_center) / 2 - $kmer_length );
}

my %counts_hash;
my $key_delim = '#';

# seq1_index is the 1-based index in the original seq1 (and not in aligned_seq1, that can contain gaps)
my $seq1_index = 0;
for ( my $i=0 ; $i < $first ; $i++ ) {
  $seq1_index++ unless ( substr($aligned_seq1,$i,1) eq "-" );
}

# seq2_index is the 1-based index in the original seq2 (and not in aligned_seq2, that can contain gaps)
my $seq2_index = 0;
for ( my $i=0 ; $i < $first ; $i++ ) {
  $seq2_index++ unless ( substr($aligned_seq2,$i,1) eq "-" );
}

# Note that $i is 0-based, while $seq1_index and $seq2_index are 1-based.
#
# FIXME - currently not efficient, comparing kmers along all aligned sequence:
#
for ( my $i=$first ; $i <= $last ; $i++ ) {
  my $seq1_kmer = substr($aligned_seq1,$i,$kmer_length);
  my $seq2_kmer = substr($aligned_seq2,$i,$kmer_length);

  $seq1_index++ unless ( substr($aligned_seq1,$i,1) eq "-" );
  $seq2_index++ unless ( substr($aligned_seq1,$i,1) eq "-" );

  next if ( $seq1_kmer eq $seq2_kmer );

  # switching on output types:

  if ( $output_type eq "CORRESPONDING_KMER_PAIRS" ) {
    print "$seq1_kmer\t$seq2_kmer\n";
  }

  elsif ( $output_type eq "SORTED_KMER_PAIRS" ) {
    if ( $seq2_kmer lt $seq1_kmer ) { print "$seq2_kmer\t$seq1_kmer\n"; }
    else { print "$seq1_kmer\t$seq2_kmer\n"; }
  }

  elsif ( $output_type eq "KMER_COUNTS_PER_INPUT_SEQ" ) {
    unless ( $seq1_kmer =~ /-/ ) {
      my $key = $seq1_name . $key_delim . $seq1_kmer;
      if ( defined($counts_hash{$key}) ) { $counts_hash{$key} = $counts_hash{$key}++; }
      else { $counts_hash{$key} = 1; }
    }
    unless ( $seq2_kmer =~ /-/ ) {
      my $key = $seq2_name . $key_delim . $seq2_kmer;
      if ( defined($counts_hash{$key}) ) { $counts_hash{$key} = $counts_hash{$key}++; }
      else { $counts_hash{$key} = 1; }
    }
  }

  elsif ( $output_type eq "KMER_SNP_AND_INDEL_COUNTS_PER_INPUT_SEQ" ) {
    my $diff_type = "SNP";
    if ( $seq1_kmer =~ /-/ or $seq2_kmer =~ /-/ ) { $diff_type = "Insertion"; }

    unless ( $seq1_kmer =~ /-/ ) {
      my $key = $seq1_name . $key_delim . $seq1_kmer . $key_delim . $diff_type;
      if ( defined($counts_hash{$key}) ) { $counts_hash{$key} = $counts_hash{$key}++; }
      else { $counts_hash{$key} = 1; }
    }
    unless ( $seq2_kmer =~ /-/ ) {
      my $key = $seq2_name . $key_delim . $seq2_kmer . $key_delim . $diff_type;
      if ( defined($counts_hash{$key}) ) { $counts_hash{$key} = $counts_hash{$key}++; }
      else { $counts_hash{$key} = 1; }
    }
  }

  elsif ( $output_type eq "KMER_SNP_OR_INDEL_WITH_POSITION_PER_INPUT_SEQ" ) {
    my $diff_type = "SNP";
    if ( $seq1_kmer =~ /-/ or $seq2_kmer =~ /-/ ) { $diff_type = "Insertion"; }

    unless ( $seq1_kmer =~ /-/ ) {
      print $seq1_name . "\t" . $seq1_kmer . "\t" . $diff_type . "\t" . $seq1_index . "\n";
    }
    unless ( $seq2_kmer =~ /-/ ) {
      print $seq2_name . "\t" . $seq2_kmer . "\t" . $diff_type . "\t" . $seq2_index . "\n";
    }
  }
}

# printing counts output:
foreach my $key ( keys(%counts_hash) ) {
  my @split_key = split(/$key_delim/,$key);
  my $num_split_key = @split_key;
  for ( my $i=0 ; $i < $num_split_key ; $i++ ) {
    print $split_key[$i] . "\t";
  }
  print $counts_hash{$key} . "\n";
}


__DATA__

extract_non_identical_kmers_from_global_alignment.pl <stab file>

  Input is a stab file containing 2 sequences to globally align (using needle.pl).
  NOTE: Does not accept input from the standard input (!!!).

  [[ Example - alignment result:

     Seq1  ACGGGCGCC
           |.||| |||
     Seq2  ATGGG-GCC
  ]]

  For the alignment result, several alternative types of outputs can be produced
  (use the -output_type option to set the type you want, see below):

  CORRESPONDING_KMER_PAIRS:
    Will output all corresponding kmer pairs that are not identical in the alignment.

    [[ Example - for the above alignment result, the following 3-mer pairs will be outputed:

       Seq1_name  Seq2_name
       ACG        ATG
       CGG        TGG
       GGC        GG-
       GCG        G-G
       CGC        -GC
    ]]

  SORTED_KMER_PAIRS:
    Will output all kmer pairs that are not identical in the alignment, each pair lexicographically sorted.
    in that case, no headers will be printed, since the seq1 -> seq2 order is lost

    [[ Example - for the above alignment result, the following 3-mer pairs will be outputed:

       -GC        CGC
       ACG        ATG
       CGG        TGG
       G-G        GCG
       GG-        GGC
    ]]

  KMER_COUNTS_PER_INPUT_SEQ:
    For each kmer and input sequence (Seq1 or Seq2), will output the number of times that this kmer
    appeared in the input sequence with a non-identical kmer aligned to it in the other sequence.

    [[ Example - for the above alignment result, the following 3-mer kmers and counts will be outputed:

       Seq1       ACG        1
       Seq1       CGG        1
       Seq1       GGC        1
       Seq1       GCG        1
       Seq1       CGC        1
       Seq2       ATG        1
       Seq2       TGG        1
    ]]

  KMER_SNP_AND_INDEL_COUNTS_PER_INPUT_SEQ:
    Similar to the 'KMER_COUNTS_PER_INPUT_SEQ' option, but differentiates between SNPs and
    insertion/deletion events.

    [[ Example - for the above alignment result, the following 3-mer kmers and counts will be outputed:

       Seq1       ACG        SNP        1
       Seq1       CGG        SNP        1
       Seq1       GGC        Insertion  1
       Seq1       GCG        Insertion  1
       Seq1       CGC        Insertion  1
       Seq2       ATG        SNP        1
       Seq2       TGG        SNP        1
    ]]

  KMER_SNP_OR_INDEL_WITH_POSITION_PER_INPUT_SEQ:
    For each kmer and input sequence (Seq1 or Seq2), if the kmer is aligned to a non-identical kmer
    on the other sequence it will be printed, along with the type of mismatch (SNP/Insertion) and
    the kmer relative start position (1-based) in the input sequence.

    [[ Example - for the above alignment result, the following 3-mer kmers and positions will be outputed:

       Seq1       ACG        SNP        1
       Seq2       ATG        SNP        1
       Seq1       CGG        SNP        2
       Seq2       TGG        SNP        2
       Seq1       GGC        Insertion  4
       Seq1       GCG        Insertion  5
       Seq1       CGC        Insertion  6
    ]]


  Options
  -------
  -kmer_length <int>:             kmer length (default: 3).
  -needle_out_file <str>:         file to which the needle.pl output is to be printed (if not given, then will not be created).

  -output_type <str>:             Type of output to produce. one of:

                                    CORRESPONDING_KMER_PAIRS (the default)
                                    SORTED_KMER_PAIRS
                                    KMER_COUNTS_PER_INPUT_SEQ
                                    KMER_SNP_AND_INDEL_COUNTS_PER_INPUT_SEQ
                                    KMER_SNP_OR_INDEL_WITH_POSITION_PER_INPUT_SEQ

  -no_headers:                    if set then output column headers will not be printed.
  -use_center <i>:                use only the 'i' bases long center of the alignment (default: use all alignment).
