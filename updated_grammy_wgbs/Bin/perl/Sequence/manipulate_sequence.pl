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

#my $skip_rows = get_arg("skip", 0, \%args);
my $move_sequence = get_arg("mv", 0, \%args);
my $replace_sequence = get_arg("rep", 0, \%args);
my $cur_start = get_arg("cur_st", 0, \%args);
my $cur_end = get_arg("cur_end", 0, \%args);
my $new_start = get_arg("new_st", 0, \%args);
my $new_sequence_file = get_arg("new_seq_file", "", \%args);
my $output_file = get_arg("o", "", \%args);
my $append = get_arg("ap", 0,  \%args);
my $del = get_arg("del", 0, \%args);
my $base_name = get_arg("bn", "", \%args);

die ("Conflicting operations\n") if (($move_sequence) && ($replace_sequence));
if ($append)
{
    open(OUT, ">>$output_file") or die ("Could not open file $output_file\n");
}
else
{
    open(OUT, ">$output_file") or die ("Could not open file $output_file\n");
}

my @new_subsequence;
my @new_sequence_length;
my @new_subsequence_replace_name;
my $replace_sequence_index = 0;

if ($replace_sequence)
{
    if (!$del)
    {
	open(NEW_FILE, $new_sequence_file) or die("Could not open file '$new_sequence_file'.\n");
	my $new_file_ref = \*NEW_FILE; 
	while (<$new_file_ref>)
	{
	    chomp;
	    
	    my @new_row = split(/\t/);
	    
	    $new_subsequence_replace_name[$replace_sequence_index] = $new_row[0];
	    $new_subsequence[$replace_sequence_index] = $new_row[1];
	    $new_sequence_length[$replace_sequence_index] = length($new_subsequence[$replace_sequence_index]);
	    
	    die ("illegal sequence length $new_sequence_length[$replace_sequence_index]\n") if ($new_sequence_length[$replace_sequence_index]  <= 0);
	    
	    $replace_sequence_index++;
	}
    }
}

while(<$file_ref>)
{
    chomp;
    
    my @row = split(/\t/);
    my $sequence_name;
    if ($base_name eq "")
    {
	$sequence_name = $row[0];
    }
    else 
    {
	$sequence_name = $base_name;
    }
    my $sequence = $row[1];
    my $sequence_length = length($sequence);
    
    die ("illegal sequence length $sequence_length\n") if ($sequence_length <= 0);
    
    die ("illegal indices start $cur_start end $cur_end\n") if (($cur_start == $cur_end) 
                                                                || ($cur_start < 0) 
                                                                || ($cur_end < 0 )
                                                                || ($cur_start > $cur_end)
								|| ($cur_start >= $sequence_length)
								|| ($cur_end >= $sequence_length));
    
    my $subseq_length = $cur_end - $cur_start + 1;

    die ("illegal index start $new_start\n") if (($new_start < 0)
						 || ($new_start == $cur_start) 
						 || ($new_start > $sequence_length - $subseq_length));
    
 
    my $prefix = substr($sequence, 0, $cur_start);
    my $sub_seq = substr($sequence, $cur_start, $subseq_length);
    my $postfix = substr($sequence, $cur_end+1, $sequence_length - $cur_end + 1);
 
    #print "Test prefix $prefix postfix $postfix sub_seq $sub_seq cur start $cur_start cur end $cur_end new start $new_start seq len $sequence_length\n";

    if ($move_sequence)
    {
	if ($new_start < $cur_start)
	{
	    my $prefix_length = length($prefix);
	    my $prefix1 = substr($prefix, 0, $new_start);	
	    my $prefix2 = substr($prefix, $new_start, $prefix_length - $new_start + 1);
	    my $moved_seq = $prefix1.$sub_seq.$prefix2.$postfix;
	    print OUT "$sequence_name\t$moved_seq\n";
	}
	else
	{
	    my $postfix_length = length($postfix);
	    my $postfix_start_index = $cur_end + 1;
	    my $postfix_new_start_index = $new_start + $subseq_length - $postfix_start_index;
	    my $postfix1 = substr($postfix, 0, $postfix_new_start_index);	
	    my $postfix2 = substr($postfix, $postfix_new_start_index, $postfix_length - $postfix_new_start_index + 1);
	    my $moved_seq = $prefix.$postfix1.$sub_seq.$postfix2;
	    #my $name = $sequence_name."_".$cur_start."_to_".$cur_end."_moved_to_".$new_start;
	    #print OUT "$name\t$moved_seq\n";
	    print OUT "$sequence_name\t$moved_seq\n";
	}	
    }
    elsif ($replace_sequence)
    {
	if ($del)
	{
	    my $replaced_seq = $prefix.$postfix;
	    print OUT "$sequence_name\t$replaced_seq\n";
	}
	else
	{
	    for (my $i = 0; $i < $replace_sequence_index; $i++)
	    {
		#my $name = $sequence_name."_".$cur_start."_to_".$cur_end."_replaced_to_".$new_subsequence_replace_name[$i];
		my $replaced_seq = $prefix.$new_subsequence[$i].$postfix;
		my $name = $sequence_name."_replaced_to_".$new_subsequence_replace_name[$i];
		print OUT "$name\t$replaced_seq\n";
		#print OUT "$name\t$replaced_seq\n";
	    }
	}
    }
    else
    {
	die ("Unrecognized operation\n");
    }
    
    
}

 #   -skip <num>:  Number of row headers to skip (default: 0)

__DATA__
    
    manipulate_sequence.pl <file>
    
    Takes in a stab file and manipulates the sequences:
    
    -mv <bool>:   Operation - move subsequence (default: false)
    
    -rep <bool>:  Operation - replace sequence (default: false)
    
    -cur_st <num>: start location of manipulated subsequence (default: 0)
    
    -cur_end <num>: end location of manipulated subsequence (default: 0)
    
    -new_start <num> : new start location for manipulated subsequence (for move operations, default: 0)
    
    -new_seq_file <string>: name of stab file containing a subsequence that will replace the current subsequence (for replace operations)

    -o <string>: output file

    -ap <bool> : append to output file (default : false)

    -del <bool> : delete specified subsequence (default : false)

    -bn <string> : base name for new sequence (default : original sequence name)
