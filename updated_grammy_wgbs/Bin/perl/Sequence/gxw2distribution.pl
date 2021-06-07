#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
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
my $alphabet_str = get_arg("a", "A;C;G;T", \%args);
my $background_matrix_file = get_arg("b", "", \%args);
my $print_marginal_distributions = get_arg("m", 0, \%args);
my $print_max_sequence = get_arg("max", 0, \%args);
my $print_sequence_scores = get_arg("s", "", \%args);
my $sequence_score_to_print = get_arg("seq", "", \%args);
my $sequence_file_score_to_print = get_arg("fseq", "", \%args);
my $double_stranded_binding = get_arg("ds", 0, \%args);

my @alphabet = split(/\;/, $alphabet_str);
my $alphabet_size = @alphabet;

my %alphabet_hash;
for (my $i = 0; $i < $alphabet_size; $i++)
{
    $alphabet_hash{$alphabet[$i]} = $i;
}

my @background_weights;
if (length($background_matrix_file) > 0)
{
    my $weights_str = `grep Weights $background_matrix_file`;
    $weights_str =~ /Weights=[\"]([^\"]+)[\"]/;

    @background_weights = split(/\;/, $1);
}

#print STDERR "Background weights=[@background_weights]\n";exit;

my @weights;  # (sequence_position, markov order, parent index, child index)
my $counter = 0;
my $num_bases = 0;
my $num_parents = 0;
my $has_weights = 0;

while(<$file_ref>)
{
  chop;

  if (/<WeightMatrix.*Name=[\"]([^\"]+)[\"]/)
  {
      $has_weights = 0;
      #print STDERR "Processing $1\n";
  }
  elsif (/<Order.*Markov=[\"]([^\"]+)[\"].*Parents=[\"]([^\"]+)[\"].*Weights=[\"]([^\"]+)[\"]/)
  {
      $has_weights = 1;

      my $markov = $1;
      my $parents = $2;
      my @row = split(/\;/, $3);

      if ($parents > $num_parents) { $num_parents = $parents; }

      $num_bases = @row;
      for (my $i = 0; $i < @row; $i++)
      {
	  $weights[$counter][$markov][$parents][$i] = $row[$i];
	  #print STDERR "  weights[$counter][$markov][$parents][$i] = $row[$i]\n";
      }
  }
  elsif (/<Order.*Markov=[\"]([^\"]+)[\"].*Weights=[\"]([^\"]+)[\"]/)
  {
      $has_weights = 1;

      my $markov = $1;
      my @row = split(/\;/, $2);

      $num_bases = @row;
      for (my $i = 0; $i < @row; $i++)
      {
	  $weights[$counter][$markov][$i] = $row[$i];
	  #print STDERR "  weights[$counter][$markov][$i] = $row[$i]\n";
      }
  }
  elsif (/<[\/]WeightMatrix/)
  {
      if ($has_weights == 1)
      {
	  $counter++;
      }
  }
}

if ($print_marginal_distributions == 1)
{
    print "P";
    for (my $j = 0; $j <= $num_parents; $j++)
    {
	for (my $k = 0; $k < $num_bases; $k++)
	{
	    print "\t$alphabet[$j]$alphabet[$k]";
	}
    }
    print "\n";
}

my @marginal_distribution;
my @prev_distribution;
my @log_max_path;
my @log_max_trace;
for (my $i = 0; $i < $counter; $i++)
{
    if ($i == 0)
    {
	if ($print_marginal_distributions == 1) { print "$i"; }
	for (my $j = 0; $j < $num_bases; $j++)
	{
	    if ($print_marginal_distributions == 1) { print "\t$weights[$i][0][$j]"; }

	    $prev_distribution[$j] = $weights[$i][0][$j];
	    $marginal_distribution[$i][$j] = $weights[$i][0][$j];

	    $log_max_path[$i][$j] = log($weights[$i][0][$j]);
	}
	if ($print_marginal_distributions == 1) { print "\n"; }
    }
    else
    {
	if ($print_marginal_distributions == 1) { print "$i"; }
	my @current_distribution;
	my $sum = 0;
	for (my $j = 0; $j <= $num_parents; $j++)
	{
	    for (my $k = 0; $k < $num_bases; $k++)
	    {
		if ($print_marginal_distributions == 1) { print "\t"; }
		my $probability = $weights[$i][1][$j][$k] * $prev_distribution[$j];
		if ($print_marginal_distributions == 1) { print &format_number($probability, 3); }
		$sum += $probability;

		$current_distribution[$k] += $probability;
		$marginal_distribution[$i][$k] += $probability;

		my $log_weight = length($weights[$i][1][$j][$k]) > 0 ? log($weights[$i][1][$j][$k]) : 0;
		if ($j == 0 or ($log_max_path[$i - 1][$j] + $log_weight) > $log_max_path[$i][$k])
		{
		    #print STDERR "log_max_path[$i][$k] = ";
		    #print STDERR ($log_max_path[$i - 1][$j] + $log_weight);
		    #print STDERR " log_max_trace[$i][$k] = $j";
		    #print STDERR "\n";

		    $log_max_path[$i][$k] = $log_max_path[$i - 1][$j] + $log_weight;
		    $log_max_trace[$i][$k] = $j;
		}
	    }
	}
	@prev_distribution = @current_distribution;
	if ($print_marginal_distributions == 1) { print "\t$sum\n"; }
    }
}

#------------------------------------------------------------------------------------------
# MAX AND MIN SEQUENCES
#------------------------------------------------------------------------------------------
if ($print_max_sequence == 1)
{
    my $max_index;
    my $max;
    for (my $j = 0; $j < $num_bases; $j++)
    {
	if ($j == 0 or $log_max_path[$counter - 1][$j] > $max)
	{
	    $max = $log_max_path[$counter - 1][$j];
	    $max_index = $j;
	}
    }
    my $max_str = "$alphabet[$max_index]";
    
    my $current_index = $max_index;
    for (my $i = $counter - 1; $i > 0; $i--)
    {
	$max_str .= $alphabet[$log_max_trace[$i][$current_index]];
	$current_index = $log_max_trace[$i][$current_index];
    }
    
    print &Reverse($max_str) . "\n";
}

#------------------------------------------------------------------------------------------
# GENERATE SCORE DISTRIBUTIONS FOR SEQUENCES
#------------------------------------------------------------------------------------------
if (length($print_sequence_scores) > 0)
{
    my $kmer_length = $print_sequence_scores;
    my $max_sequence_index = $alphabet_size ** $kmer_length;

    for (my $i = 0; $i < $max_sequence_index; $i++)
    {
	my @sequence = &GetSequenceIDs($i, $kmer_length);

	&PrintSubSequenceScore(\@sequence);
    }
}

#------------------------------------------------------------------------------------------
# GENERATE SCORE DISTRIBUTIONS FOR A SPECIFIC SEQUENCE
#------------------------------------------------------------------------------------------
if (length($sequence_score_to_print) > 0)
{
    my @sequence;

    for (my $i = 0; $i < length($sequence_score_to_print); $i++)
    {
	push(@sequence, $alphabet_hash{substr($sequence_score_to_print, $i, 1)});
    }

    if (length($$sequence_score_to_print) < $counter)
    {
	&PrintSubSequenceScore(\@sequence);
    }
    else
    {
	&PrintSequenceScore(\@sequence);
    }
}

#------------------------------------------------------------------------------------------
# GENERATE SCORE DISTRIBUTIONS FOR SPECIFIC SEQUENCES FROM A STAB FILE
#------------------------------------------------------------------------------------------
if (length($sequence_file_score_to_print) > 0)
{
    open(STAB_FILE, "<$sequence_file_score_to_print");
    while(<STAB_FILE>)
    {
	chop;

	my @row = split(/\t/);

	my @sequence;

	for (my $i = 0; $i < length($row[1]); $i++)
	{
	    push(@sequence, $alphabet_hash{substr($row[1], $i, 1)});
	}

	print "$row[0]\t";

	if (length($row[1]) < $counter)
	{
	    &PrintSubSequenceScore(\@sequence);
	}
	else
	{
	    &PrintSequenceScore(\@sequence);
	}
    }
}

#------------------------------------------------------------------------------------------
# PRINT SCORE FOR A SPECIFIC SEQUENCE
#------------------------------------------------------------------------------------------
sub PrintSubSequenceScore
{
    my ($sequence_str) = @_;

    my @sequence = @{$sequence_str};
    my $kmer_length = @sequence;

    my $sequence_str = "";
    for (my $j = 0; $j < @sequence; $j++) { $sequence_str .= $alphabet[$sequence[$j]]; }
    my $global_max_score = 0;
    my $global_max_position = 0;
    for (my $j = 1; $j < $counter - $kmer_length + 1; $j++)
    {
	my $max_probability = 0;
	my $parent_index = 0;
	for (my $k = 0; $k < $alphabet_size; $k++)
	{
	    my $probability = $weights[$j][1][$k][$sequence[0]];
	    if ($k == 0 or $probability > $max_probability)
	    {
		$max_probability = $probability;
		$parent_index = $k;
	    }
	}
	
	#print "P($alphabet[$sequence[0]] | $alphabet[$parent_index]) = $weights[$j][1][$parent_index][$sequence[0]]\n";
	my $score = log($weights[$j][1][$parent_index][$sequence[0]]);
	my $bck_score = length($background_matrix_file) > 0 ? log($background_weights[$sequence[0]]) : 0;
	
	for (my $k = 1; $k < @sequence; $k++)
	{
	    #print "P($alphabet[$sequence[$k]] | " . $alphabet[$sequence[$k - 1]] . ") = " . $weights[$j + $k][1][$sequence[$k - 1]][$sequence[$k]] . "\n";
	    $score += log($weights[$j + $k][1][$sequence[$k - 1]][$sequence[$k]]);

	    $bck_score += length($background_matrix_file) > 0 ? log($background_weights[$sequence[$k]]) : 0;
	}
	
	#print "$i Seq=$sequence_str j=$j score=$score\n";

	if (length($background_matrix_file) > 0)
	{
	    $score -= $bck_score;
	}
	
	if ($j == 1 or $score > $global_max_score)
	{
	    $global_max_score = $score;
	    $global_max_position = $j;
	}
    }
    
    print "$sequence_str\t" . &format_number($global_max_score, 3) . "\t";
    print &format_number($global_max_score / $kmer_length, 3) . "\t$global_max_position\n";
}

#------------------------------------------------------------------------------------------
# PRINT SCORE FOR A SPECIFIC SEQUENCE
#------------------------------------------------------------------------------------------
sub PrintSequenceScore
{
    my ($sequence_str) = @_;

    my @sequence = @{$sequence_str};

    #print STDERR "Seq=@sequence\n";

    my @sequence_rc;
    if ($double_stranded_binding == 1)
    {
      for (my $i = 0; $i < @sequence; $i++)
      {
	push(@sequence_rc, 3 - $sequence[@sequence - $i - 1]);
      }
    }

    my $sequence_str = "";
    for (my $j = 0; $j < @sequence; $j++) { $sequence_str .= $alphabet[$sequence[$j]]; }
    #print STDERR "Seq=$sequence_str\n";
    my $sequence_rc_str = "";
    for (my $j = 0; $j < @sequence; $j++) { $sequence_rc_str .= $alphabet[$sequence_rc[$j]]; }
    #print STDERR "Seq=$sequence_rc_str\n";

    my $global_max_score = 0;
    my $global_max_position = 0;
    for (my $j = 0; $j <= @sequence - $counter; $j++)
    {
	#print STDERR "P($alphabet[$sequence[$j]]) = $weights[0][0][$sequence[$j]]\n";

	my $score = log($weights[0][0][$sequence[$j]]);
	if ($double_stranded_binding == 1)
	{ 
	  $score += log($weights[0][0][$sequence_rc[$j]]);
	}
	my $bck_score = length($background_matrix_file) > 0 ? log($background_weights[$sequence[$j]]) : 0;
	if ($double_stranded_binding == 1)
	{ 
	  $bck_score += length($background_matrix_file) > 0 ? log($background_weights[$sequence_rc[$j]]) : 0;
	}
	#print STDERR "k=0 score=$score\n";
	
	for (my $k = 1; $k < $counter; $k++)
	{
	    my $s = $j + $k;

	    #print STDERR "P($alphabet[$sequence[$s]] | " . $alphabet[$sequence[$s - 1]] . ") = " . $weights[$k][1][$sequence[$s - 1]][$sequence[$s]] . "\n";

	    my $order = length($weights[$k][1][$sequence[$s - 1]][$sequence[$s]]) > 0 ? 1 : 0;
	    if ($order == 1)
	    {
	      $score += log($weights[$k][1][$sequence[$s - 1]][$sequence[$s]]);
	      #print STDERR "k=$k score=" . log($weights[$k][1][$sequence[$s - 1]][$sequence[$s]]) . "\n";
	      if ($double_stranded_binding == 1)
	      { 
		$score += log($weights[$k][1][$sequence_rc[$s - 1]][$sequence_rc[$s]]);
	      }
	    }
	    else
	    {
	      $score += log($weights[$k][0][$sequence[$s]]);
	      if ($double_stranded_binding == 1)
	      { 
		$score += log($weights[$k][0][$sequence_rc[$s]]);
	      }
	    }

	    $bck_score += length($background_matrix_file) > 0 ? log($background_weights[$sequence[$s]]) : 0;
	    if ($double_stranded_binding == 1)
	    {
	      $bck_score += length($background_matrix_file) > 0 ? log($background_weights[$sequence_rc[$s]]) : 0;
	    }
	}

	if (length($background_matrix_file) > 0)
	{
	    $score -= $bck_score;
	}
	
	if ($j == 0 or $score > $global_max_score)
	{
	    $global_max_score = $score;
	    $global_max_position = $j;
	}
    }
    
    print "$sequence_str\t" . &format_number($global_max_score, 3) . "\n";
    #print &format_number($global_max_score / @sequence, 3) . "\t$global_max_position\n";
}

#------------------------------------------------------------------------------------------
# GET SEQUENCE IDS
#------------------------------------------------------------------------------------------
sub GetSequenceIDs
{
    my ($sequence_id, $sequence_length) = @_;

    my @res;

    for (my $i = 0; $i < $sequence_length; $i++)
    {
	$res[$sequence_length - 1 - $i] = $sequence_id % $alphabet_size;

	$sequence_id = int($sequence_id / $alphabet_size);
    }

    return @res;
}

__DATA__

gxw2distribution.pl <gxm file>

   Outputs the distribution of bases along the motif and the max sequence

   -a <str>:    Alphabet (default: 'A;C;G;T')

   -b <str>:    Background gxw file (optional)

   -m:          Print the marginal distributions
   -max:        Print the max sequence
   -s <num>:    Print scores of all sequences of length <num>
   -seq <str>:  Print the score of the sequence specified by <str>
   -fseq <str>: Print the score of the sequence specified by the stab file <str>

   -ds:         Double stranded binding

