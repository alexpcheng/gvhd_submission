#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";

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

my $alphabet = get_arg("a", "", \%args);
my $print_counts = get_arg("c", "", \%args);
my $pseudo_counts = get_arg("ps", 0, \%args);
my $start_position = get_arg("s", 0, \%args);
my $end_position = get_arg("e", -1, \%args);
my $ignore_characters = get_arg("i", "", \%args);
my $skip_rows = get_arg("sk", 0, \%args);
my $weight_file_for_sequences = get_arg("wf", "", \%args);
my $markov_order = get_arg("order", 0, \%args);
my $gxw_output = get_arg("gxw", "", \%args);
my $shared_positions = get_arg("share", "", \%args);

my $r = int(rand(1000000));
open(OUTFILE, ">tmp.$r");

my $precision = 3;

my %sequences_weights;
if (length($weight_file_for_sequences) > 0)
{
   open(SEQUENCES_WEIGHTS_FILE, "<$weight_file_for_sequences");
   while(<SEQUENCES_WEIGHTS_FILE>)
   {
      chomp;

      my @row = split(/\t/);

      $sequences_weights{$row[0]} = $row[1];
   }
}

my @counts;
my @sums;
my @chars;
my %char2id;
my $max_length = 0;

if (length($alphabet) > 0)
{
    for (my $i = 0; $i < length($alphabet); $i++)
    {
	my $char = substr($alphabet, $i, 1);
	my $num_chars = @chars;
	$char2id{$char} = $num_chars;
	push(@chars, substr($alphabet, $i, 1));
    }
}
elsif ($markov_order > 0)
{
    die "If you specify a Markov order > 0, you must also specify the alphabet\n";
}

my $max_parents_index = @chars ** $markov_order;

for (my $i = 0; $i < $skip_rows; $i++) { my $line = <$file_ref>; }

print STDERR "stab2counts.pl";

my $counter = 0;

while(<$file_ref>)
{
    chomp;

    $counter++;
    if ($counter % 10000 == 0) { print STDERR "."; }

    my @row = split(/\t/);

    my $sequence_weight = length($sequences_weights{$row[0]}) > 0 ? $sequences_weights{$row[0]} : 1;

    my $str_length = length($row[1]);
    my $len = ($end_position == -1 or $end_position >= $str_length) ? $str_length : ($end_position - $start_position +1);
    if ($len > $max_length) { $max_length = $len; }
    my $string = substr($row[1], $start_position, $len);
    for (my $i = 0; $i < length($string); $i++)
    {
	my $char = substr($string, $i, 1);
	if (length($ignore_characters) == 0 or index($ignore_characters, $char) == -1)
	{
	    if (length($char2id{$char}) == 0)
	    {
		my $num_chars = @chars;
		$char2id{$char} = $num_chars;
		push(@chars, $char);
	    }

	    if ($markov_order == 0)
	    {
		$counts[$i][$char2id{$char}] += $sequence_weight;
		$sums[$i] += $sequence_weight;
	    }
	    else
	    {
		my $multiplication_factor = 1;
		my $parents_index = 0;
		my $valid = 1;
		for (my $j = $i - 1; $j >= 0 and $j >= $i - $markov_order; $j--)
		{
		    my $parent_char = substr($string, $j, 1);

		    if (length($ignore_characters) == 0 or index($ignore_characters, $parent_char) == -1)
		    {
			$parents_index += $multiplication_factor * $char2id{$parent_char};

			$multiplication_factor *= @chars;
		    }
		    else
		    {
			$valid = 0;
		    }
		}

		if ($valid == 1)
		{
		    my $edges = $markov_order > $i ? (@chars ** ($markov_order - $i)) : 1;
		    my $edge_multiplication = $markov_order > $i ? (@chars ** $i) : 0;
		    for (my $j = 0; $j < $edges; $j++)
		    {
			my $child_id = $j * $edge_multiplication + $parents_index;
			
			$child_id *= @chars;
			
			$child_id += $char2id{$char};

			$counts[$i][$child_id] += $sequence_weight;

			#print STDERR "counts[$i][$child_id]=$counts[$i][$child_id]\n";
		    }

		    $sums[$i] += $sequence_weight;
		}
	    }
	}
    }
}

my $num_child_indices = @chars * $max_parents_index;

if (length($shared_positions) > 0)
{
    my @lines = split(/\ /, $shared_positions);
    foreach my $line (@lines)
    {
	my @row = split(/\,/, $line);

	for (my $i = 0; $i < @row; $i++)
	{
	    $row[$i] -= $start_position;
	}

	for (my $i = 0; $i < $num_child_indices; $i++)
	{
	    my $sum = 0;
	    for (my $j = 0; $j < @row; $j++)
	    {
		$sum += $counts[$row[$j]][$i];
	    }

	    for (my $j = 0; $j < @row; $j++)
	    {
		$counts[$row[$j]][$i] = $sum;
	    }
	}

	my $sum = 0;
	for (my $j = 0; $j < @row; $j++)
	{
	    $sum += $sums[$row[$j]];
	}
	for (my $j = 0; $j < @row; $j++)
	{
	    $sums[$row[$j]] = $sum;
	}
    }
}

@chars = sort { $a cmp $b } @chars;

print OUTFILE "Char";
for (my $i = 0; $i < $max_length; $i++)
{
    print OUTFILE "\t$i";
}
print OUTFILE "\n";

for (my $i = 0; $i < $num_child_indices; $i++)
{
    if ($markov_order == 0)
    {
	print OUTFILE "$chars[$i]";
    }
    else
    {
	my $global_char = $i;
	my $char = $global_char % @chars;
	my $child = $chars[$char];

	$global_char /= @chars;

	my @parents;
	for (my $j = 0; $j < $markov_order; $j++)
	{
	    $char = $global_char % @chars;
	    push(@parents, $chars[$char]);
	    $global_char /= @chars;
	}

	for (my $j = 0; $j < @parents; $j++)
	{
	    print OUTFILE "$parents[$j]";
	}

	print OUTFILE "$child";
    }

    for (my $j = 0; $j < $max_length; $j++)
    {
      my $pseudo_count = $pseudo_counts / (length($alphabet) ** ($markov_order + 1));
      if ($markov_order == 0)
      {
	my $char_id = $char2id{$chars[$i]};

	if ($print_counts == 1)
	{
	  my $count = $pseudo_count + $counts[$j][$char_id];
	  if (length($count) == 0) { print OUTFILE "\t0"; }
	  else { print OUTFILE "\t$count"; }
	}
	else
	{
	  my $prob = $pseudo_count + $counts[$j][$char_id];
	  my $sum = @chars * $pseudo_count + $sums[$j];
	  print OUTFILE "\t";
	  if ($sum == 0) { print OUTFILE "0"; }
	  else { print OUTFILE &format_number($prob / $sum, $precision); }
	}
      }
      else
      {
	if ($print_counts == 1)
	{
	  my $count = $pseudo_count + $counts[$j][$i];
	  if (length($count) == 0) { print OUTFILE "\t0"; }
	  else { print OUTFILE "\t$count"; }
	}
	else
	{
	  my $prob = $pseudo_count + $counts[$j][$i];
	  my $sum = @chars * $pseudo_count + $sums[$j];
	  print OUTFILE "\t";
	  if ($sum == 0) { print OUTFILE "0"; }
	  else { print OUTFILE &format_number($prob / $sum, $precision); }
	}
      }
    }

    print OUTFILE "\n";
}

if (length($gxw_output) == 0)
{
    system("cat tmp.$r");
}
else
{
    my $exec_str = "cat tmp.$r ";
    $exec_str   .= "| transpose.pl ";
    $exec_str   .= "| cut -f2- ";
    $exec_str   .= "| lines2line.pl ";
    $exec_str   .= "| cut -f5- ";
    $exec_str   .= "| add_column.pl -b -s '$gxw_output' ";
    $exec_str   .= "| tab2gxw.pl ";
    system("$exec_str");
}

&DeleteFile("tmp.$r");

print STDERR "Done\n";

__DATA__

alignment2counts.pl <file>

   Given a multiple sequence alignment, computes counts or probabilities
   for nucleotides in certain positions

   -a <str>:     Alphabet to use (default: induce the alphabet from the file. Example: 'ACGT')

   -c:           Compute counts (default: probabilities)
   -ps <num>:    Pseudo counts to add (default: 0)

   -s <num>:     Start position (default: 0)
   -e <num>:     End position (default: -1 for all columns)

   -i <str>:     Ignore all characters in <str> (default: '')

   -sk <num>:    Skip the first <num> rows in the file (default: 0)

   -wf <str>:    Weight file for sequences. Format: <seq name><tab><seq weight>

   -order <num>: Markov order for the counts (default: 0)

   -gxw <str>:   Output a gxw file with a motif named <str>

   -share <str>: List of columns that share parameters in the estimation.
                 Format is space-separated list of comma separated columns (e.g., '1,4 2,7')

