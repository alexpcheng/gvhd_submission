#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/libstats.pl";

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

my $word_length = get_arg("l", 6, \%args);
my $different_characters = get_arg("n", 2, \%args);
my $search_string = get_arg("s", "", \%args);
my $max_pvalue = get_arg("p", 0.05, \%args);
my $perform_non_strict_search = get_arg("non_strict", 0, \%args);
my $surpress_output_pvalues = get_arg("no_out_p", 0, \%args);
my $output_sequence = get_arg("out_seq", 0, \%args);
my $output_sequence_prefix = get_arg("out_seq_prefix", "<b><font color=\"red\">", \%args);
my $output_sequence_suffix = get_arg("out_seq_suffix", "</b></font>", \%args);

my @characters;
my %characters_hash;
my $num_characters;
my %selected_characters;
my @selected_indices;

if (length($search_string) > 0) { $different_characters = length($search_string); }

for (my $i = 0; $i < length($search_string); $i++)
{
    my $char = substr($search_string, $i, 1);
    $selected_characters{$char} = $i;
    push(@characters, $char);
    $selected_indices[$i] = $i;
}

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);
  my $sequence = $row[1];

  if (length($search_string) == 0)
  {
      @characters = ();
      %characters_hash = ();

      for (my $i = 0; $i < length($sequence); $i++)
      {
	  my $char = substr($sequence, $i, 1);
	  if (length($characters_hash{$char}) == 0)
	  {
	      $characters_hash{$char} = "1";
	      push(@characters, $char);
	  }
      }

      $num_characters = @characters;

      @selected_indices = ();
      my $flipping_index = 0;
      while ($flipping_index < $different_characters)
      {
	  my $legal_index = 1;
	  for (my $i = 0; $i < $different_characters - 1; $i++)
	  {
	      if (($characters[$selected_indices[$i + 1]] cmp $characters[$selected_indices[$i]]) >= 0)
	      {
		  $legal_index = 0;
		  last;
	      }
	  }
	  
	  %selected_characters = ();

	  if ($legal_index == 1)
	  {
	      for (my $i = $different_characters - 1; $i >= 0; $i--)
	      {
		  $selected_characters{$characters[$selected_indices[$i]]} = $i;
		  #print STDERR "$characters[$selected_indices[$i]]";
	      }
	      #print STDERR "\n";
	      
	      &ComputeEnrichment($row[0], $sequence);
	  }
	  
	  $flipping_index = 0;
	  while ($flipping_index < $different_characters)
	  {
	      $selected_indices[$flipping_index]++;
	      if ($selected_indices[$flipping_index] < $num_characters)
	      {
		  last;
	      }
	      else
	      {
		  $selected_indices[$flipping_index] = 0;
		  $flipping_index++;
	      }
	  }
      }
  }
  else
  {
      &ComputeEnrichment($row[0], $sequence);
  }
}

#---------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------
sub ComputeEnrichment
{
    my ($sequence_name, $sequence) = @_;

    my $N = length($sequence);
    my $K = 0;
    for (my $i = 0; $i < length($sequence); $i++)
    {
	my $char = substr($sequence, $i, 1);
	if (length($selected_characters{$char}) > 0) { $K++; }
    }

    my %selected_characters_count;
    for (my $i = $different_characters - 1; $i >= 0; $i--)
    {
	$selected_characters_count{$characters[$selected_indices[$i]]} = 0;
    }

    my $k = 0;
    for (my $i = 0; $i < $word_length - 1; $i++)
    {
	my $char = substr($sequence, $i, 1);
	if (length($selected_characters{$char}) > 0)
	{
	    $k++;
	    $selected_characters_count{$char}++;
	}
    }

    my @start_cluster_positions;
    push(@start_cluster_positions, -$word_length);
    my $last_printed_character = -1;
    for (my $i = $word_length - 1; $i < $N; $i++)
    {
	if ($i >= $word_length)
	{
	    my $char = substr($sequence, $i - $word_length, 1);
	    if (length($selected_characters{$char}) > 0)
	    {
		$k--;
		$selected_characters_count{$char}--;
	    }
	}

	my $char = substr($sequence, $i, 1);
	if (length($selected_characters{$char}) > 0)
	{
	    $k++;
	    $selected_characters_count{$char}++;
	}

	if ($i - $word_length + 1 > $last_printed_character)
	{
	    my $legal_counts = 1;
	    if ($perform_non_strict_search == 0)
	    {
		for (my $i = $different_characters - 1; $i >= 0; $i--)
		{
		    if ($selected_characters_count{$characters[$selected_indices[$i]]} == 0)
		    {
			$legal_counts = 0;
		    }
		}
	    }

	    if ($legal_counts == 1)
	    {
		my $pvalue = &ComputeHyperPValue($k, $word_length, $K, $N);

		if ($pvalue <= $max_pvalue)
		{
		    $last_printed_character = $i;
		    push(@start_cluster_positions, $i - $word_length + 1);

		    if ($surpress_output_pvalues == 0)
		    {
			for (my $i = $different_characters - 1; $i >= 0; $i--)
			{
			    print "$characters[$selected_indices[$i]]";
			}
			print "\t";
			
			print ($i - $word_length + 1);
			print "\t";
			print "$sequence_name\t";
			print substr($sequence, $i - $word_length + 1, $word_length) . "\t";
			print "$k\t";
			print "$word_length\t";
			print "$K\t";
			print "$N\t";
			print &format_number($pvalue, 3) . "\n";
		    }
		}
	    }
	}
    }

    if ($output_sequence == 1)
    {
	my $num_start_positions = @start_cluster_positions;

	print "$sequence_name\t";

	for (my $i = 1; $i < $num_start_positions; $i++)
	{
	    my $length = $start_cluster_positions[$i] - ($start_cluster_positions[$i - 1] + $word_length);
	    if ($length > 0)
	    {
		my $str = substr($sequence, $start_cluster_positions[$i - 1] + $word_length, $length);
		print "\L$str";
	    }

	    print "$output_sequence_prefix";
	    print substr($sequence, $start_cluster_positions[$i - 1] + $word_length + $length, $word_length);
	    print "$output_sequence_suffix";
	}
	my $length = length($sequence) - ($start_cluster_positions[$num_start_positions - 1] + $word_length);
	if ($length > 0)
	{
	    my $str = substr($sequence, $start_cluster_positions[$num_start_positions - 1] + $word_length, $length);
	    print "\L$str";
	}

	print "\n";
    }
}


__DATA__

find_sequence_clusters.pl <file>

   Takes in a stab sequence file and searches sub-sequences of a fixed length
   for enrichment of counts of some number of amino acids. For instance, can 
   find clusters of A+K in subsequences of length 6

   -l <num>:              Sub-sequences length (default: 6)

   -n <num>:              Number of combinations of different characters to count (default: 2)
   -s <str>:              Characters to search for (default: search all characters of length up to that speified by -n)

   -p <num>:              Max P-value for significance (default: 0.05)

   -non_strict:           Do not require all strings in a given sub-sequence to be present in the cluster (default: strict search)

   -no_out_p:             Do *not* output the pvalues for each cluster

   -out_seq:              Output each sequence back where the clustered positions are uppercase
   -out_seq_prefix <str>: String to output before matches, useful for html (default: <b><font color=\"red\">)
   -out_seq_suffix <str>: String to output after matches, useful for html (default: </b></font>)

