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

my $word_length = get_arg("n", 5, \%args);
my $requirement = get_arg("r", "", \%args);
my $position_column = get_arg("pos", "", \%args);
my $print_words = get_arg("p", 0, \%args);
my $print_summary = get_arg("s", 0, \%args);
my $print_summary_statistics = get_arg("ss", 0, \%args);
my $print_summary_counts = get_arg("sc", 0, \%args);
my $summary_probabilities_pseudo_counts = get_arg("sp", "", \%args);

my $position_requirement = -1;
my $word_requirement = "";
if (length($requirement) > 0)
{
  my @row = split(/\,/, $requirement);
  $position_requirement = $row[0];
  $word_requirement = $row[1];
}
my $word_requirement_length = length($word_requirement);

my @position_counts;
my @chars;
my %char2id;
my $num_sequences;
my $num_words;
my $num_possible_words;

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);
  
  $num_sequences++;
  my $sequence = $row[1];

  if (length($position_column) == 0)
  {
      $num_possible_words += length($sequence) - $word_length + 1;
      for (my $i = 0; $i < length($sequence) - $word_length + 1; $i++)
      {
	  my $element = substr($sequence, $i, $word_length);

	  if ($position_requirement == -1 || substr($element, $position_requirement, $word_requirement_length) eq $word_requirement)
	  {
	      &ProcessWord($sequence, $row[0], $element, $i);
	  }
      }
  }
  else
  {
      my $position = $row[$position_column] - 1;

      my $flanking = int(($word_length + 1) / 2);
      my $start = ($position - $flanking >= 0) ? $position - $flanking : 0;
      my $end = ($position + $flanking <= length($sequence) - 1) ? $position + $flanking : length($sequence) - 1;
      my $element = substr($sequence, $start, $end - $start + 1);
      &ProcessWord($sequence, $row[0], $element, $start);
  }
}

if ($print_summary == 1)
{
  if ($print_summary_statistics == 1)
  {
      print "Sequences: $num_sequences\n";
      print "Words: $num_words\n";
      print "Possible words: $num_possible_words\n";
  }

  print "Chr";
  for (my $i = 0; $i < $word_length; $i++)
  {
      if ($print_summary_counts == 1) { print "\t$i"; }
      if (length($summary_probabilities_pseudo_counts) > 0) { print "\t$i"; }
  }
  print "\n";

  my $num_chars = @chars;

  my $total_counts = $num_words;
  if (length($summary_probabilities_pseudo_counts) > 0) { $total_counts += $num_chars * $summary_probabilities_pseudo_counts }
  for (my $i = 0; $i < $num_chars; $i++)
  {
      print "$chars[$i]";
      for (my $j = 0; $j < $word_length; $j++)
      {
	  if (length($position_counts[$j][$i]) == 0) { $position_counts[$j][$i] = 0; }

	  if (length($summary_probabilities_pseudo_counts) > 0)
	  {
	      $position_counts[$j][$i] += $summary_probabilities_pseudo_counts;
	  }

	  if ($print_summary_counts == 1) { print "\t$position_counts[$j][$i]"; }

	  if (length($summary_probabilities_pseudo_counts) > 0)
	  {
	      print "\t" . &format_number($position_counts[$j][$i] / $total_counts, 2);
	  }
      }
      print "\n";
  }
}

sub ProcessWord
{
    my ($sequence, $word_name, $word, $start_position) = @_;

    if ($print_words == 1) 
    {
	print "$word_name\t$word\t$start_position\n";
    }
    
    $num_words++;

    for (my $j = 0; $j < $word_length; $j++)
    {
	my $char = substr($sequence, $start_position + $j, 1);
	my $char_id = $char2id{$char};
	if (length($char_id) == 0)
	{
	    $char_id = @chars;
	    $char2id{$char} = $char_id;
	    push(@chars, $char);
	}
	$position_counts[$j][$char_id]++;
    }
}

__DATA__

stab2words.pl <file>

   Takes in a stub sequence file and extracts words by a defined criteria

   -n <num>:     Length of the words to extract (default: 5)
   -r <pos,seq>: Extract only words that have "seq" starting at position "pos"
                 (e.g., '1,CCAAT' will extract all words that have CCAAT in position 2)
   -pos <num>:   The position to extract from each sequence is given in column <num>

   -p:           Print the actual words

   -s:           Print summary
   -ss:          In the summaries, print the general statistics (num sequences, words, and total words)
   -sc:          In the summaries, print the number in each bin
   -sp <num>:    In the summaries, print the probabilities of each bin with pseudo counts <num>

