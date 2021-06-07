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

my $positive_stub_file = get_arg("p", "", \%args);
my $negative_stub_file = get_arg("n", "", \%args);
my $take_logs_of_entries = get_arg("l", 0, \%args);
my $print_sequences_and_scores = get_arg("print", "", \%args);
my $print_roc = get_arg("roc", 0, \%args);
my $print_roc_summary = get_arg("roc_sum", 0, \%args);

my $LOG2 = log(2);

my @positions = split(/\t/, <$file_ref>);
my @weights;
my %char2id;
my $id = 0;
while (<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    #print STDERR "$row[0]";

    for (my $i = 1; $i < @row; $i++)
    {
	$weights[$id][$i - 1] = $row[$i];

	if ($take_logs_of_entries == 1) { $weights[$id][$i - 1] = log($weights[$id][$i - 1]) / $LOG2; }

	#print STDERR "\t$weights[$id][$i - 1]";
    }

    #print STDERR "\n";

    $char2id{$row[0]} = $id;
    $id++;
}

my @scores;
&ScoreSequences($positive_stub_file, 1);
my $num_positive_examples = @scores;
&ScoreSequences($negative_stub_file, 0);
my $num_negative_examples = @scores - $num_positive_examples;

print STDERR "Sorting...";
@scores = sort { my @aa = split(/\t/, $a); my @bb = split(/\t/, $b); $bb[0] != $aa[0] ? $bb[0] <=> $aa[0] : $aa[1] <=> $bb[1]; } @scores;
print STDERR "Done.\n";

my $area_of_roc = 0;
my $total_positives = 0;
my $total_negatives = 0;
my $prev_sensitivity = 0;
my $prev_total_negatives = 0;
print STDERR "Computing ROC";
for (my $i = 0; $i < @scores; $i++)
{
    my @row = split(/\t/, $scores[$i]);

    if (length($print_sequences_and_scores) > 0 and $i < $print_sequences_and_scores)
    {
	print &format_number($row[0], 2) . "\t$row[1]\t$row[2]\t$row[3]\n";
    }

    my $sensitivity = $total_positives / $num_positive_examples;

    if ($row[1] eq "0")
    {
	if ($sensitivity != $prev_sensitivity or $i == @scores - 1)
	{
	    $prev_total_negatives = $total_negatives;

	    if ($print_roc == 1)
	    {
		print "$total_positives\t$num_positive_examples\t";
		print &format_number($total_positives / $num_positive_examples, 3) . "\t";
		print "$total_negatives\t$num_negative_examples\t";
		print &format_number($total_negatives / $num_negative_examples, 3) . "\t";
		print &format_number($area_of_roc, 3) . "\n";
	    }
	}

	$area_of_roc += $sensitivity / $num_negative_examples;
    }

    $prev_sensitivity = $sensitivity;

    if ($row[1] eq "1") { $total_positives++; }
    elsif ($row[1] eq "0")
    {	
	$total_negatives++;
    }

    if ($i % 10000 == 0) { print STDERR "."; }
}
print STDERR "Done\n";

if ($print_roc == 1)
{
    print "$total_positives\t$num_positive_examples\t";
    print &format_number($total_positives / $num_positive_examples, 3) . "\t";
    print "$total_negatives\t$num_negative_examples\t";
    print &format_number($total_negatives / $num_negative_examples, 3) . "\t";
    print &format_number($area_of_roc, 3) . "\n";
}

if ($print_roc_summary == 1)
{
    print "ROC AREA\t" . &format_number($area_of_roc, 3) . "\t$num_positive_examples\t$num_negative_examples\n";
}

sub ScoreSequences ()
{
    my ($file, $label) = @_;

    print STDERR "Scoring file $file";
    my $row_counter = 0;

    open(FILE, "<$file");
    while(<FILE>)
    {
	chop;

	my @row = split(/\t/);

	my $sequence = $row[1];
	my $score = 0;
	for (my $i = 0; $i < length($sequence); $i++)
	{
	    my $element = substr($sequence, $i, 1);
	    $score += $weights[$char2id{$element}][$i];

	    #print STDERR "weights[$char2id{$element}][$i] = $weights[$char2id{$element}][$i]\n";
	}
	push(@scores, "$score\t$label\t$row[0]\t$row[1]");

	$row_counter++;
	if ($row_counter % 10000 == 0) { print STDERR "."; }
    }

    print STDERR "\n";
}

__DATA__

motif2roc.pl <weights file>

   Takes in a weight matrix file in the format of positions of the motif in columns,
   characters in rows, and entries corresponding to weights of characters per positions.
   Computes ROC curves for comparing hits on positive and negative sets.

   -p <file>:    Positive file sequences in stub format
   -n <file>:    Negative file sequences in stub format

   -l:           Take logs of the weights (good if starting with probabilities in entries)

   -print <num>: Print the first <num> sequences and their associated scores (0 in num means print all sequences)
   -roc:         Print the ROC graph
   -roc_sum      Print the ROC summary

