#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
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

my $key_name = get_arg("k", "", \%args);
my $num_random_sequences = get_arg("n", 1, \%args);
my $random_sequence_length = get_arg("l", 100, \%args);
my $alphabet = get_arg("a", "", \%args);
my $sequences_lengths = get_arg("f", "", \%args);
my $upper_case_letters = get_arg("u", 0, \%args);
my $delta_for_gc_content_of_file_seqs = get_arg("g", "0", \%args);
my $min_gc_content = get_arg("min_gc", 0, \%args);
my $max_gc_content = get_arg("max_gc", 1, \%args);


if ( $min_gc_content < 0 or $min_gc_content > 1 )
{
  die "Illegal minimal GC content value of $min_gc_content. Must be within [0,1].\n";
}

if ( $max_gc_content < 0 or $max_gc_content > 1 )
{
  die "Illegal maximal GC content value of $max_gc_content. Must be within [0,1].\n";
}

if ( $min_gc_content > $max_gc_content )
{
  die "Minimal GC content ($min_gc_content) is not lower or equal to the maximal GC content ($max_gc_content).\n";
}


my $is_alphabet_restricted = 0;
if ( length($alphabet) > 0 )
{
  $is_alphabet_restricted = 1;
}

my %alphabet_hash;
for (my $i = 0; $i < length($alphabet); $i++)
{
    $alphabet_hash{substr($alphabet, $i, 1)} = "1";
}

my @sequences;
while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    if (length($key_name) == 0 or $key_name eq $row[0])
    {
	push(@sequences, $_);
    }
}

my $num_sequences = @sequences;

if (length($sequences_lengths) == 0)
{
  my $num_to_extract = $num_random_sequences == -1 ? $num_sequences : $num_random_sequences;
  for (my $i = 0; $i < $num_to_extract; $i++)
  {
    my $sequence_id = $num_random_sequences == -1 ? $i : int(rand($num_sequences));
    &extract_single_sequence("Random$i", $sequence_id, $random_sequence_length, $min_gc_content, $max_gc_content);
  }
}
else
{
  open(SEQUENCE_LENGTHS_FILE, "<$sequences_lengths") or die "Could not find sequences file $sequences_lengths\n";
  while(<SEQUENCE_LENGTHS_FILE>)
  {
    chomp;

    my @row = split(/\t/);

    my $sequence_id = int(rand($num_sequences));

    my $min_gc_content_to_use = $min_gc_content;
    my $max_gc_content_to_use = $max_gc_content;

    if ( $delta_for_gc_content_of_file_seqs > 0 )
    {
      $min_gc_content_to_use = ComputeGCFraction($row[1], 0);
      $max_gc_content_to_use = $min_gc_content_to_use;
      $min_gc_content_to_use = $min_gc_content_to_use - $delta_for_gc_content_of_file_seqs;
      $max_gc_content_to_use = $max_gc_content_to_use + $delta_for_gc_content_of_file_seqs;
      if ( $min_gc_content_to_use < 0 )
      {
	$min_gc_content_to_use = 0;
      }
      if ( $max_gc_content_to_use > 1 )
      {
	$max_gc_content_to_use = 1;
      }
    }

    &extract_single_sequence($row[0], $sequence_id, length($row[1]), $min_gc_content_to_use, $max_gc_content_to_use);
  }
}

#-------------------------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------------------------
sub extract_single_sequence
{
  my ($sequence_prefix, $sequence_id, $sequence_length, $min_gc_content, $max_gc_content) = @_;

  my $done = 0;
  while ($done == 0)
  {
    my @row = split(/\t/, $sequences[$sequence_id]);
    my $sequence = $row[1];
    my $length = length($sequence);
    if ($length >= $sequence_length)
    {
      my $start_position = int(rand($length - $sequence_length));
	
      my $string = substr($row[1], $start_position, $sequence_length);
	
      if ($upper_case_letters == 1) { $string = "\U$string"; }

      $done = 1;

      if ( $is_alphabet_restricted )
      {
	for (my $j = 0; $j < length($string); $j++)
	{
	  if (length($alphabet_hash{substr($string, $j, 1)}) == 0)
	  {
	    $done = 0;
	    last;
	  }
	}
      }

      my $curr_gc_content = ComputeGCFraction($string, 0);

      if ( $curr_gc_content < $min_gc_content or $curr_gc_content > $max_gc_content )
      {
	$done = 0;
      }

      if ($done == 1)
      {
	my $end_position = $start_position + $sequence_length - 1;
		
	print "${sequence_prefix}_$row[0]_${start_position}_$end_position\t$string\n";
      }
      else
      {
	$sequence_id = int(rand($num_sequences));
      }
    }
    elsif ($num_random_sequences == -1)
    {
      $done = 1;
    }
    else
    {
      $sequence_id = int(rand($num_sequences));
    }
  }
}

__DATA__

extract_random_sequences.pl <file>

   Extracts random sequences of a given length from a file

   -k <num>:      Key of sequence to extract from (default: extract from the first sequence)

   -n <num>:      Number of sequences to extract (default: 1)
                  NOTE: if -1 is specified (you should actually write '"-1"' so it will be read as negative),
                  then will extract a random sequence from each sequence

   -l <num>:      Length of sequence to extract (default: 100)

   -u:            Convert all sequences to upper case 

   -a <str>:      Allowed alphabet in selected sequences (default: no restrictions)
                  NOTE: example alphabet ACGT

   -f <str>:      File of sequences: extract a random sequence for each sequence in the file with the same length

   -g <delta>:    Foreach sequence in file (when using the -f option), extract random sequence with same gc content,
                  with an allowed deviance of up to 'delta' (delta must be > 0).
                  Note that this overrides the values given through -min_gc/-max_gc.

   -min_gc <num>: Minimal GC content (GC ratio) of extracted sequences (default: 0)
   -max_gc <num>: Maximal GC content (GC ratio) of extracted sequences (default: 1)
