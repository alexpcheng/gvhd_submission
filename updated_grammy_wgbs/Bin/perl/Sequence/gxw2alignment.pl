#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/genie_helpers.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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

my $matrices_file = get_arg("m", "", \%args);
my $use_weight_matrix_name = get_arg("n", "", \%args);
my $sequences_file = get_arg("s", "", \%args);
my $sequences_list = get_arg("l", "", \%args);
my $results_file = get_arg("r", "", \%args);
my $background_order = get_arg("b", 0, \%args);
my $background_matrix_file = get_arg("bck", "", \%args);
my $double_strand_binding = get_arg("ds", 0, \%args);
my $alphabet = get_arg("a", "ACGT", \%args);
my $print_html_version = get_arg("html", 0, \%args);
my $html_colors_str = get_arg("htmlc", "", \%args);
my $print_full_alignment = get_arg("f", 0, \%args);
my $no_reverse_complement = get_arg("norc", 0, \%args);

my $alphabet_size = length($alphabet);
my %alphabet2id;
for (my $i = 0; $i < $alphabet_size; $i++)
{
    my $char = substr($alphabet, $i, 1);
    $alphabet2id{$char} = $i;
}

my %html_colors_hash;
my %html_lengths;
my @html_colors = split(/\,/, $html_colors_str);
for (my $i = 0; $i < @html_colors; $i += 2)
{
    $html_colors_hash{$html_colors[$i]} = $html_colors[$i + 1];
    $html_lengths{length($html_colors[$i])} = "1";
}

my $sequences_str = `fasta2stab.pl $sequences_file`;
my @sequences = split(/\n/, $sequences_str);
my %sequences_hash;
my %sequence_lengths;
foreach my $sequence (@sequences)
{
    my @row = split(/\t/, $sequence);

    $sequence_lengths{$row[0]} = length($row[1]);
    $sequences_hash{$row[0]} = $row[1];
}

my $exec_str = "gxw2stats.pl -m $matrices_file ";
if (length($use_weight_matrix_name) > 0) { $exec_str   .= "-n $use_weight_matrix_name "; }
if (length($sequences_file) > 0) { $exec_str   .= "-s $sequences_file "; }
if (length($sequences_list) > 0) { $exec_str   .= "-l $sequences_list "; }
$exec_str   .= "-b $background_order ";
if ($no_reverse_complement == 1) { $exec_str   .= "-norc "; }
if (length($background_matrix_file) > 0) { $exec_str .= "-bck $background_matrix_file "; }
if ($double_strand_binding == 1) { $exec_str   .= "-ds "; }
$exec_str   .= "-t WeightMatrixPositions ";
$exec_str   .= "-best ";

my $best_positions_str = length($results_file) == 0 ? `$exec_str | cut -f2-` : `cat $results_file`;
my @best_positions = split(/\n/, $best_positions_str);
my %best_positions_hash;
my $max_start_position = 0;
my $max_alignment_length = 0;
my $alignment_length = 0;
my @alignment_counts;
foreach my $best_position (@best_positions)
{
    my @row = split(/\t/, $best_position);

    $best_positions_hash{$row[0]} = $best_position;
    if ($row[1] > $max_start_position)
    {
	$max_start_position = $row[1];
    }
    if ($sequence_lengths{$row[0]} - $row[1] > $max_alignment_length)
    {
	$max_alignment_length =	$sequence_lengths{$row[0]} - $row[1];
    }

    my $sequence = $row[4] == 1 ? &ReverseComplement($sequences_hash{$row[0]}) : $sequences_hash{$row[0]};
    for (my $i = $row[1]; $i <= $row[2]; $i++)
    {
	$alignment_counts[$i - $row[1]][$alphabet2id{substr($sequence, $i, 1)}]++;
    }

    $alignment_length = $row[2] - $row[1] + 1;
}

print STDERR "max_start_position=$max_start_position\n";
print STDERR "max_alignment_length=$max_alignment_length\n";
print STDERR "alignment_length=$alignment_length\n";

my @consensus;
my $consensus_str;
my @consensus_fraction;
for (my $i = 0; $i < $alignment_length; $i++)
{
    my $max_counts = 0;
    my $sum_counts = 0;
    my $max_id = 0;
    for (my $j = 0; $j < $alphabet_size; $j++)
    {
	if ($alignment_counts[$i][$j] > $max_counts)
	{
	    $max_counts = $alignment_counts[$i][$j];
	    $max_id = $j;
	}

	$sum_counts += $alignment_counts[$i][$j];
    }

    $consensus[$i] = substr($alphabet, $max_id, 1);
    $consensus_str .= $consensus[$i];
    $consensus_fraction[$i] = &format_number($max_counts / $sum_counts, 2);
}

if ($print_html_version == 0)
{
    print "Sequence\tStart\tEnd\tScore\tReverse\t";
    for (my $i = 0; $i < @consensus; $i++)
    {
	print "$consensus[$i]";
    }
    print "\n";
}
else
{
    print "Sequence&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\tStart&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\tEnd&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\tScore&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\tReverse&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";

    if ($print_full_alignment == 1)
    {
	for (my $i = 0; $i < $max_start_position; $i++)
	{
	    print "\t";
	}
    }

    for (my $i = 0; $i < @consensus; $i++)
    {
	print "\t";

	if (length($html_colors_str) == 0)
	{
	    print &AlignmentFractionToHTMLColor($consensus_fraction[$i], $consensus[$i]);
	}
	else
	{
	    &PrintHTMLColor($consensus_str, $i);
	}
    }

    if ($print_full_alignment == 1)
    {
	for (my $i = 0; $i < $max_alignment_length - @consensus; $i++)
	{
	    print "\t";
	}
    }

    print "\n";
}

foreach my $sequence (@sequences)
{
    my @row = split(/\t/, $sequence);

    my $best_position_str = $best_positions_hash{$row[0]};
    if (length($best_position_str) > 0)
    {
	my @best_position = split(/\t/, $best_position_str);
	my $alignment_position = $best_position[1];

	print "$best_position_str";

	if ($print_html_version == 0) { print "\t"; }
	
	if ($print_full_alignment == 1)
	{
	    for (my $i = 0; $i < $max_start_position - $alignment_position; $i++)
	    {
		if ($print_html_version == 1) { print "\t"; }
		
		print "-";
	    }
	}

	my $string = $best_position[4] == 1 ? &ReverseComplement($row[1]) : $row[1];
	if ($print_html_version == 1)
	{
	    my $string_length = length($string);
	    my $start = $print_full_alignment == 1 ? 0 : $best_position[1];
	    my $end = $print_full_alignment == 1 ? ($string_length - 1) : $best_position[2];
	    for (my $i = $start; $i <= $end; $i++)
	    {
		print "\t";

		my $char = substr($string, $i, 1);

		if (length($html_colors_str) == 0)
		{
		    if ($i >= $best_position[1] and $i <= $best_position[2] and $char eq $consensus[$i - $best_position[1]])
		    {
			print &AlignmentFractionToHTMLColor($consensus_fraction[$i - $best_position[1]], $char);
		    }
		    else
		    {
			print "$char";
		    }
		}
		else
		{
		    &PrintHTMLColor($string, $i);
		}
	    }
	}
	else
	{
	    if ($print_full_alignment == 1)
	    {
		if ($best_position[1] > 0)
		{
		    print substr($string, 0, $best_position[1]); 
		}
	    }

	    print substr($string, $best_position[1], $alignment_length); 

	    if ($print_full_alignment == 1)
	    {
		if (length($string) - $best_position[2] > 0)
		{
		    print substr($string, $best_position[2] + 1, length($string) - $best_position[2]); 
		}
	    }
	}

	if ($print_full_alignment == 1)
	{
	    for (my $i = length($row[1]) - $alignment_position; $i < $max_alignment_length; $i++)
	    {
		if ($print_html_version == 1) { print "\t"; }
		
		print "-";
	    }
	}

	print "\n";
    }
}

sub PrintHTMLColor
{
    my ($str, $position) = @_;

    my $color = "";
    foreach my $len (keys %html_lengths)
    {
	for (my $i = $position - $len + 1; $i <= $position and $i < length($str) - $len; $i++)
	{
	    if ($i >= 0)
	    {
		$color = $html_colors_hash{substr($str, $i, $len)};
		if (length($color) > 0)
		{
		    last;
		}
	    }
	}

	if (length($color) > 0)
	{
	    last;
	}
    }

    my $char = substr($str, $position, 1);

    if (length($color) > 0)
    {
	print "<table cellspacing=\"0\" cellpadding=\"0\"><tr><td bgcolor=\"$color\">$char</td></tr></table>";
    }
    else
    {
	print $char;
    }
}

__DATA__

gxw2alignment.pl.pl

   Takes a gxw file and a fasta sequence file and aligns the sequences 
   according to their best position hit for the weight matrix

   -m <str>:     Matrices file (gxw format)
   -n <str>:     Use this matrix only out of the gxw file (default: use all matrices)
   -s <str>:     Sequences file (fasta format)
   -l <str>:     Use only these sequences from the file <str> (default: use all sequences in fasta file)
   -b <num>:     Background order (default: 0)
   -bck <str>:   Background matrix file
   -ds:          Double strand binding

   -r <str>:     Results file for aligned position per sequence. If specified, this will be used instead
                 of internally running gxw2stats.pl.
                 Format: <seq name><tab><start><tab><end><tab><score><tab><0/1> (1 = reverse complement)

   -a <str>:     Alphabet (default: ACGT)
   -f:           Print the full alignment (default: print only the actually aligned positions)

   -norc:        Do *not* use reverse complement in sequence (default: use reverse complement)

   -html:        Print a version for use in html (nucleotides that match consensus sequences are colored)
   -htmlc <str>: Color the specified sequences in the specified color instead of coloring consensus
                 (Format: <seq1,color1,seq2,color2>,... Example: TA,FF0000,CG,98FB98)

