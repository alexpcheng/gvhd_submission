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

my $pattern1 = get_arg("1", "", \%args);
my $pattern2 = get_arg("2", "", \%args);
my $compute_full_histogram = get_arg("h", 0, \%args);
my $max_allowed_spacing = get_arg("m", 100, \%args);
my $print_words = get_arg("p", 0, \%args);
my $print_summary = get_arg("s", 0, \%args);
my $print_summary_statistics = get_arg("ss", 0, \%args);
my $print_summary_counts = get_arg("sc", 0, \%args);
my $print_summary_entropy = get_arg("se", 0, \%args);

my $pattern1_length = length($pattern1);
my $pattern2_length = length($pattern2);

my @spacing_counts;
my $max_spacing = 0;

my $num_sequences;
my $num_words;

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);
  
    $num_sequences++;
    my $sequence = $row[1];

    if ($compute_full_histogram == 0)
    {
	my $inside_pattern1 = -1;
	for (my $i = 0; $i < length($sequence) - $pattern1_length; $i++)
	{
	    my $element1 = substr($sequence, $i, $pattern1_length);
	    my $element2 = substr($sequence, $i, $pattern2_length);

	    my $spacing = $i - ($inside_pattern1 + $pattern1_length);
	    if ($inside_pattern1 >= 0 and $element2 eq $pattern2 and $spacing <= $max_allowed_spacing)
	    {
		if ($print_words == 1) 
		{
		    my $word = substr($sequence, $inside_pattern1, $i + $pattern2_length - $inside_pattern1);
		    print "$row[0]\t$word\t$inside_pattern1\t" . ($i + $pattern2_length - 1) . "\t$spacing\n";
		}
		
		$num_words++;

		$spacing_counts[$spacing]++;

		if ($spacing > $max_spacing)
		{
		    $max_spacing = $spacing;
		}

		$inside_pattern1 = -1;
	    }
	    elsif ($element1 eq $pattern1)
	    {
		$inside_pattern1 = $i;
	    }
	}
    }
    else
    {
	for (my $i = 0; $i < length($sequence) - $pattern1_length; $i++)
	{
	    my $element1 = substr($sequence, $i, $pattern1_length);
	    if ($element1 eq $pattern1)
	    {
		for (my $j = $i + 1; $j < (length($sequence) - $pattern2_length) and ($j - $i <= $max_allowed_spacing); $j++)
		{
		    my $element2 = substr($sequence, $j, $pattern2_length);
		    if ($element2 eq $pattern2)
		    {
			my $spacing = $j - ($i + $pattern1_length);

			if ($print_words == 1) 
			{
			    my $word = substr($sequence, $i, $j + $pattern2_length - $i);
			    print "$row[0]\t$word\t$i\t" . ($j + $pattern2_length - 1) . "\t$spacing\n";
			}

			$num_words++;

			$spacing_counts[$spacing]++;
			
			if ($spacing > $max_spacing)
			{
			    $max_spacing = $spacing;
			}
		    }
		}
	    }
	}
    }
}

if ($print_summary_statistics == 1)
{
    print "Sequences: $num_sequences\n";
    print "Words: $num_words\n";
}

if ($print_summary_counts == 1)
{
    print "Spacing\tCounts\tFraction\n";
    for (my $i = 0; $i <= $max_spacing; $i++)
    {
	if ($spacing_counts[$i] > 0)
	{
	    print "$i\t$spacing_counts[$i]\t" . &format_number($spacing_counts[$i] / $num_words, 3) . "\n";
	}
    }
}

if ($print_summary_entropy == 1)
{
    my $entropy = 0;
    my $average_length = 0;
    for (my $i = 0; $i <= $max_spacing; $i++)
    {
	if ($spacing_counts[$i] > 0)
	{
	    my $p = $spacing_counts[$i] / $num_words;
	    $entropy -= $p * log($p) / log(2);
	    $average_length += $p * $i;
	}
    }
    print "$pattern1\t$pattern2\t$num_words\t" . &format_number($average_length, 3) . "\t" . &format_number($entropy, 3) . "\n";
}

__DATA__

stab2word_pairs.pl <file>

   Takes in a stab file and extracts all words that have pattern 1 followed by pattern 2

   -1 <str>:     Pattern 1 (e.g., A)
   -2 <str>:     Pattern 2 (e.g., C)

   -h:           Compute the full histogram of pattern 1 followed by pattern 2 (do not stop after finding first pattern)

   -m <num>:     Max spacing allowed between the two patterns (default: 100)

   -p:           Print the actual words

   -ss:          Print summary of the general statistics (num sequences, words)
   -sc:          Print summary of the number in each bin
   -se:          Print summary of the entropy over spacings

