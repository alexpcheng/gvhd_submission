#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
    print STDOUT <DATA>;
    exit;
}



my %args = load_args(\@ARGV);

my $aln_file = get_arg("al", "", \%args);
my $subseqs_file = get_arg("subseqs", "", \%args);
my $first = get_arg("1", 0, \%args);
my $second = get_arg("2", 0, \%args);
my $match_num = get_arg("ma", 0, \%args);
my $mismatch_num = get_arg("ms", 0, \%args);
my $gap_num = get_arg("gn", 0, \%args);
my $gap_lengths = get_arg("gl", 0, \%args);
my $name_list_file = get_arg("l", "", \%args);
my $output_file = get_arg("o", "subseqs_aln.out", \%args);
my $list = get_arg("l", "",  \%args);
my $cons_vec1 = get_arg("cvec1", 0, \%args);
my $cons_vec2 = get_arg("cvec2", 0, \%args);
my $cons_vec3 = get_arg("cvec3", 0, \%args);


die ("Choose first OR second sequence\n") if (($second && $first) || ((!$second) && (!$first)));
die ("Choose alignment file\n") if ($aln_file eq "");

`rm $output_file`;
`touch $output_file`;

open(SUB, "$subseqs_file") or die("Unable to open file $subseqs_file\n");

`rm tmp_subseq`;
`touch tmp_subseq`;
`compute_alignment_stats.pl tmp_subseq -ma $match_num -ms $mismatch_num -gn $gap_num -gl $gap_lengths -cvec1 $cons_vec1 -cvec2 $cons_vec2 -cvec3 $cons_vec3 >> $output_file`;

my @subseq;
while (<SUB>)
{
    chomp;
    @subseq = split;
    if ($first)
    {
	`cat $aln_file | grep -w $subseq[0] -A 2 > tmp_subseq`;
	`compute_alignment_stats.pl tmp_subseq -ma $match_num -ms $mismatch_num -gn $gap_num -gl $gap_lengths -cvec1 $cons_vec1 -cvec2 $cons_vec2 -cvec3 $cons_vec3 -seq1_subseq $subseq[1] -l $list | body.pl 2 -1 >> $output_file`;
    }
    else
    {
	`cat $aln_file | grep -w $subseq[0] -B 1 -A 1 > tmp_subseq`;
	`compute_alignment_stats.pl tmp_subseq -ma $match_num -ms $mismatch_num -gn $gap_num -gl $gap_lengths -cvec1 $cons_vec1 -cvec2 $cons_vec2 -cvec3 $cons_vec3 -seq2_subseq $subseq[1] -l $list | body.pl 2 -1 >> $output_file`;
    }
}



__DATA__
    
    compute_subseqs_alignment_stats.pl 
    
    Takes in an alignment output file of the format:

    seq1 aligned seq
    seq2 aligned seq
    =================
    
    and subsequences file and computes statstics as described below

    CONSIDERED ALIGNMENT
    ====================
    -al <str> file containing needle alignments
    -l  <str> a list file containing the sequences to consider (names of either seq1 or seq2)
    -subseqs <str> file containing subseqs to consider from each alignment (format: seq_name<tab>subseq)
    -1 <bool> subseqs are from first sequence in each alignment (default: true)
    -2 <bool> subseqs are from first sequence in each alignment (default: false)

    COMPUTED STATISTICS
    ===================
    
    -ma <bool> match num 
    -ms <bool> mismatch num 
    -gn <bool> gap number
    -gl <bool> gap lengths
    -cvec1 <bool> conservation score vector relative to first sequence
    -cvec2 <bool> conservation score vector relative to second sequence
    cvec3 <bool> conservation score vector relative to both sequences (discard leading and terminating gaps)

    OUTPUT
    ======
    -o <str> output file (default: subseqs_aln.out)
