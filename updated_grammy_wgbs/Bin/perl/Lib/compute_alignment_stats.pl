#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
    print STDOUT <DATA>;
    exit;
}


my $file_ref;
my $file = $ARGV[0];
if (length($file) < 1 or $file =~ /^-/) 
{
    $file_ref = \*STDIN;
}
else
{
    open(FILE, $file) or die("Could not open file '$file'.\n");
    $file_ref = \*FILE;
}

my %args = load_args(\@ARGV);

my $arg_start = get_arg("s", 0, \%args);
my $arg_end = get_arg("e", -1, \%args);
my $seq1_subseq = get_arg("seq1_subseq", "", \%args);
my $seq2_subseq = get_arg("seq2_subseq", "", \%args);
my $match_num = get_arg("ma", 0, \%args);
my $mismatch_num = get_arg("ms", 0, \%args);
my $gap_num = get_arg("gn", 0, \%args);
my $gap_lengths = get_arg("gl", 0, \%args);
my $name_list_file = get_arg("l", "", \%args);
my $cons_vec1 = get_arg("cvec1", 0, \%args);
my $cons_vec2 = get_arg("cvec2", 0, \%args);
my $cons_vec3 = get_arg("cvec3", 0, \%args);
my $match_score = get_arg("masc", 1, \%args);
my $mismatch_score = get_arg("mssc", 0, \%args);
my $gap_score = get_arg("gsc", 0, \%args);


my $align_all = 0;
my %name_hash;
if ($name_list_file ne "")
{
    open(NAMES, $name_list_file) or die("Could not open file '$name_list_file'.\n");
    my $name_file_ref = \*NAMES;
    while (<$name_file_ref>)
    {
	chomp;
	$name_hash{$_} = 1;
    }
    close (NAMES);
}
else
{
    $align_all = 1;
}

my $string = "seq1_name\tseq2_name\tstart\tend";
if ($match_num)
{
    $string = $string."\tMatch Num";
}
if ($mismatch_num)
{
    $string = $string."\tMismatch Num";
}
if ($gap_num)
{
    $string = $string."\tGap Num";
}
if ($gap_lengths)
{
    $string = $string."\tGap Lengths";
}
if ($cons_vec1)
{
    $string = $string."\tConservation Realative to Seq1";
}
if ($cons_vec2)
{
    $string = $string."\tConservation Realative to Seq2";
}
if ($cons_vec3)
{
    $string = $string."\tConservation Realative to both";
}
print "$string\n";



my $seq1 = "";
my $seq1_name = "";
my $seq2 = "";
my $seq2_name = "";
my @tmp;
my $line;
my $alignment_length;
my @relevant_seq1;
my @relevant_seq2;
my $ma;
my $ms;
my $gn;
my @gl;
my $cur_gl;
my $in_gap;
my $sep = "";
my $start;
my $end;
my @cons1;
my @cons2;
my @cons3;
my $ali_started;


while (<$file_ref>)
{
    $ali_started = 0;
    $start = $arg_start;
    $end = $arg_end;
    chomp;
    @tmp = split;
    $seq1_name = $tmp[0];
    $seq1 = $tmp[1];
    $_ = <$file_ref>;
    chomp;
    @tmp = split;
    $seq2_name = $tmp[0];
    $seq2 = $tmp[1];
    $alignment_length = length($seq1);
    $sep = <$file_ref>;
    if (($align_all) || (exists $name_hash{$seq1_name}) || (exists $name_hash{$seq2_name}))
    {
	if ($seq1_subseq ne "")
	{
	    @tmp = split //, $seq1_subseq;
	    my $tmp_string = join("-*", @tmp);
	    $seq1 =~m/($tmp_string)/;
	    my $subseq = $1;
	    $start = index($seq1, $subseq);
	    $end = $start + length($subseq) - 1;
	}
	elsif ($seq2_subseq ne "")
	{
	    @tmp = split //, $seq2_subseq;
	    my $tmp_string = join("-*", @tmp);
	    $seq2 =~m/($tmp_string)/;
	    my $subseq = $1;
	    $start = index($seq2, $subseq);
	    $end = $start + length($subseq) - 1;
	}
	else
	{
	    if ($end == -1)
	    {
		$end =  $alignment_length - 1;
	    }
	}
	die ("illegal subseq $seq1_name $seq2_name $seq1_subseq $seq2_subseq $start $end\n") if (($start < 0) || ($end < $start) || ($end >  $alignment_length - 1));
	my $relevant_alignment_length = $end - $start + 1;
	@relevant_seq1 = split //, substr($seq1, $start, $relevant_alignment_length);
	@relevant_seq2 = split //, substr($seq2, $start, $relevant_alignment_length);
	
	$ma = 0;
	$ms = 0;
	$gn = 0;
	@gl = ();
	@cons1 = ();
	@cons2 = ();
	@cons3 = ();
	$cur_gl = 0;
	$in_gap = 0;
	for (my $i = 0; $i < $relevant_alignment_length; $i++)
	{
	    if ($relevant_seq1[$i] eq $relevant_seq2[$i])
	    {
		$ma++;
		$in_gap = 0;
		if ($cur_gl != 0)
		{
		    push(@gl, $cur_gl);
		    if (($cons_vec3) && ($ali_started))
		    {
			#only push gaps in the middle of alignment
			for (my $j =0; $j < $cur_gl; $j++)
			{
			    push(@cons3, $gap_score);
			}
		    }
		    $cur_gl = 0;
		}
		$ali_started = 1;
		if ($cons_vec1)
		{
		    push(@cons1, $match_score);
		}
		if ($cons_vec2)
		{
		    push(@cons2, $match_score);
		}
		if ($cons_vec3)
		{
		    push(@cons3, $match_score);
		}
	    }
	    elsif ($relevant_seq1[$i] eq "-")
	    {
		
		if ($in_gap)
		{
		    $cur_gl++;
		}
		else
		{
		    $gn++;
		    $cur_gl = 1;
		    $in_gap = 1;
		}
		if ($cons_vec2)
		{
		    push(@cons2, $gap_score);
		}
	    }
	    elsif ($relevant_seq2[$i] eq "-")
	    {
		
		if ($in_gap)
		{
		    $cur_gl++;
		}
		else
		{
		    $gn++;
		    $cur_gl = 1;
		    $in_gap = 1;
		}
		if ($cons_vec1)
		{
		    push(@cons1, $gap_score);
		}
		
	    }
	    else
	    {
		
		$in_gap = 0;
		$ms++;
		if ($cur_gl != 0)
		{
		    push(@gl, $cur_gl);	    
		    if (($cons_vec3) && ($ali_started))
		    {
			#only push gaps in the middle of alignment
			for (my $j =0; $j < $cur_gl; $j++)
			{
			    push(@cons3, $gap_score);
			}
		    }
		    $cur_gl = 0;
		}
		$ali_started = 1;
		if ($cons_vec1)
		{
		    push(@cons1, $mismatch_score);
		}
		if ($cons_vec2)
		{
		    push(@cons2, $mismatch_score);
		}
		if ($cons_vec3)
		{
		    push(@cons3, $mismatch_score);
		}
	    }
	    
	}
	if ($cur_gl != 0)
	{
	    push(@gl, $cur_gl);
	    $cur_gl = 0;
	}
	$string = $seq1_name."\t".$seq2_name."\t".$start."\t".$end;
	if ($match_num)
	{
	    $string = $string."\t".$ma;
	}
	if ($mismatch_num)
	{
	    $string = $string."\t".$ms;
	}
	if ($gap_num)
	{
	    $string = $string."\t".$gn;
	}
	if ($gap_lengths)
	{
	    my $lengths = join(",", @gl);
	    $string = $string."\t".$lengths;
	}
	if ($cons_vec1)
	{
	    my $j_cons1 = join(",", @cons1);
	    $string = $string."\t".$j_cons1;
	}
	if ($cons_vec2)
	{
	    my $j_cons2 = join(",", @cons2);
	    $string = $string."\t".$j_cons2;
	}
	if ($cons_vec3)
	{
	    my $j_cons3 = join(",", @cons3);
	    $string = $string."\t".$j_cons3;
	}
	print "$string\n";
    }
}

__DATA__
    
    compute_alignment_stats.pl <file>
    
    Takes in an alignment output file of the format:

    seq1 aligned seq
    seq2 aligned seq
    =================
    
    and computes statstics as described below

    CONSIDERED ALIGNMENT
    ====================
    -l <str> a list file containing the sequences to consider (names of either seq1 or seq2)
    -s <num> start location (default: 0)
    -e <num> end location (default : end of alignment)
    -seq1_subseq <string> subsequence of the first seq (default: false)
    -seq2_subseq <string> subsequence of the second seq (default: false)
    
    COMPUTED STATISTICS
    ===================
    
    -ma <bool> match num 
    -ms <bool> mismatch num 
    -gn <bool> gap number
    -gl <bool> gap lengths
    -cvec1 <bool> conservation score vector relative to first sequence
    -cvec2 <bool> conservation score vector relative to second sequence
    -cvec3 <bool> conservation score vector relative to both sequences - leading and trailing gaps are disregarded

    PARAMETERS
    ==========

    -masc <num> score per match relative to examined sequence (default: 1) 
    -mssc <num> score per mismatch relative to examined sequence (default: 0) 
    -gsc  <num> score per gap relative to examined sequence (default: 0) 

