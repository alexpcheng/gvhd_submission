#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $r = int(rand(1000000));
my $tmp_file_input_positive = "stab2markov_gxw_input_positive_" . $r . "_tmp";
my $tmp_file_positive = "stab2markov_gxw_positive_" . $r . "_tmp";
my $tmp_file_negative = "stab2markov_gxw_negative_" . $r . "_tmp";
my $tmp_file_negative_binomial_test = "stab2markov_gxw_negative_binomial_test_" . $r . "_tmp";
my $tmp_file_negative_binomial_test2 = "stab2markov_gxw_negative_binomial_test2_" . $r . "_tmp";
my $tmp_file_kmers_stats_for_figure = "stab2markov_gxw_kmers_stats_for_figure_" . $r . "_tmp";

my $positive_total_count = 0;
my $negative_total_count = 0;
my $positive_different_kmers_count = 0;
my $negative_different_kmers_count = 0;

my $file_ref_positive;
my $file = $ARGV[0];
my %args = load_args(\@ARGV);

my $k = get_arg("k", 1, \%args);
my $markov_order = $k - 1;
($k >= 1) or die("K must be a positive integer, given: $k\n");
my $pseudocounts = get_arg("pc", 1, \%args);
my $use_reverse_complement = !get_arg("nrc", 0, \%args);
my $print_weight_matrices_token = !get_arg("nwms", 0, \%args);
my $arg_rc = $use_reverse_complement ? "-rc" : "";
my $weight_matrix_name = get_arg("n", "Background", \%args);
my $alphabet_type = get_arg("alph", "DNA", \%args);
my $output_kmers_file = get_arg("okmers", "", \%args);
my $plot_kmers_frequencies = get_arg("okmers_png", "", \%args);
my $uniform_weight_matrix = get_arg("u", 0, \%args);
my $pos_is_sequence_counts = get_arg("sc", 0, \%args);

my %alphabet = ();
my $alphabet_str;

if ($alphabet_type eq "RNA")
{
   %alphabet = (0, 'A', 1, 'C', 2, 'G', 3, 'U');
   $alphabet_str = "ACGU";
}
elsif ($alphabet_type eq "DNA")
{
   %alphabet = (0, 'A', 1, 'C', 2, 'G', 3, 'T');
   $alphabet_str = "ACGT";
}
else
{
   die("Unrecognized alphabet type '$alphabet_type'.\n");
}
my $alphabet_size = keys(%alphabet);

my %kmers = ();
my %kmers_neg = ();
my %kmers_ratio = ();
my %kmers_stats_print = ();

if (!$uniform_weight_matrix)
{
   if ($file =~ m/^-[^\s]+/)
   {
      die("No input file given. Matched file name = '$file'");
   }
   if (length($file) < 1 or $file =~ /^-/)
   {
      open(TMP_FILE, ">$tmp_file_input_positive") or die("Could not open file '$tmp_file_input_positive' for writing (intermediate file).\n");
      while(my $l = <STDIN>)
      {
	 chomp($l);
	 print TMP_FILE "$l\n";
      }
      close(TMP_FILE);
      my $command = "";
      if ($pos_is_sequence_counts == 0)
      {
	 $command = "cat $tmp_file_input_positive | cut -f2 | sed -r 's/[^$alphabet_str]/\\n/g' | filter.pl -c 0 -minl $k | lin.pl | stab2sequence_counts.pl -k $k -sum $arg_rc | transpose.pl -q | body.pl 2 -1 > $tmp_file_positive;";
      }
      else
      {
	 $command = "cat $tmp_file_input_positive > $tmp_file_positive;";
      }
      system("$command");
      $positive_total_count = `cat $tmp_file_positive | compute_column_stats.pl -c 1 -skip 0 -s | cut -f2`;
      ($positive_total_count > 0) or die("The total number of positive counts is non-positive(if): $positive_total_count\n");
      open(FILE, "$tmp_file_positive") or die("Could not open file '$tmp_file_positive' for reading (input or intermediate file).\n");
      $file_ref_positive = \*FILE;
   }
   else
   {
      my $command = "";
      if ($pos_is_sequence_counts == 0)
      {
	 $command = "cat $file | cut -f2 | sed -r 's/[^$alphabet_str]/\\n/g' | filter.pl -c 0 -minl $k | lin.pl | stab2sequence_counts.pl -k $k -sum $arg_rc | transpose.pl -q | body.pl 2 -1 > $tmp_file_positive;";
      }
      else
      {
	 $command = "cat $file > $tmp_file_positive;";
      }
      system("$command");
      $positive_total_count = `cat $tmp_file_positive | compute_column_stats.pl -c 1 -skip 0 -s | cut -f2`;
      ($positive_total_count > 0) or die("The total number of positive counts is non-positive(else): $positive_total_count\n");
      open(FILE, $tmp_file_positive) or die("Could not open file '$file'.\n");
      $file_ref_positive = \*FILE;
   }
}
else
{
   $pseudocounts = 1;
}

my $pseudo_norm_positive = ($positive_total_count > 0) ? $positive_total_count + (($alphabet_size ** $k) * $pseudocounts) : 1;
my $pseudo_norm_negative = ($negative_total_count > 0) ? $negative_total_count + (($alphabet_size ** $k) * $pseudocounts) : 1;

my $first_index_inc = 0;
for (my $i = 1; $i < $k; $i++)
{
   $first_index_inc = ($first_index_inc + ($alphabet_size ** $i));
}
my $last_index_exc = ($first_index_inc + ($alphabet_size ** $k));

for (my $i = $first_index_inc; $i < $last_index_exc; $i++)
{
   my $j = $i;
   my $seq = "";
   while ($j >= $alphabet_size)
   {
      my $d = ($j % $alphabet_size);
      $j = int($j / $alphabet_size) - 1;
      $seq = "$alphabet{ $d }" . "$seq";
   }
   $seq = "$alphabet{ $j }" . "$seq";
   $kmers{ $seq } = $pseudocounts;
   $kmers_neg{ $seq } = $pseudocounts;
}

if (!$uniform_weight_matrix)
{
   while(my $l = <$file_ref_positive>)
   {
      chomp($l);
      my @r = split(/\t/,$l);
      $kmers{ $r[0] } = ($kmers{ $r[0] } + $r[1]);
   }
}

my $neg = get_arg("neg", "", \%args);
my $neg_is_sequence_counts = get_arg("negsc", 0, \%args);
my $neg_binomial_test = get_arg("negb", "", \%args);
my $neg_binomial_test_bonferroni = get_arg("negb_bonf", "", \%args);
my $pvalue_threshold = (length($neg_binomial_test) > 0) ? $neg_binomial_test : 0;
$pvalue_threshold = (length($neg_binomial_test_bonferroni) > 0) ? ($neg_binomial_test  / ($alphabet_size ** $k)) : $pvalue_threshold;
my $normalize_weights = ((length($neg) == 0) or (!get_arg("nnorm", 0, \%args)));
my $file_ref_negative;
my $file_ref_binomial;

if ((length($neg) > 0) and (!$uniform_weight_matrix))
{
   ($pseudocounts > 0) or die("In order to use the negative collection set the pseudocounts > 0. Given: $pseudocounts\n");
   if ($neg_is_sequence_counts == 0)
   {
      open(FILE_NEG, $neg) or die("Could not open the negative collection stab file '$neg'.\n");
      close(FILE_NEG);
      my $command = "cat $neg | cut -f2 | sed -r 's/[^$alphabet_str]/\\n/g' | filter.pl -c 0 -minl $k | lin.pl | stab2sequence_counts.pl -k $k -sum $arg_rc | transpose.pl -q | body.pl 2 -1 > $tmp_file_negative;";
      system("$command");
   }
   else
   {
      open(FILE_NEG, $neg) or die("Could not open the negative collection sequence counts file '$neg'.\n");
      close(FILE_NEG);
      my $command = "cat $neg > $tmp_file_negative;";
      system("$command");
   }

   $negative_total_count = `cat $tmp_file_negative | compute_column_stats.pl -c 1 -skip 0 -s | cut -f2`;
   $negative_different_kmers_count = `cat $tmp_file_negative | stab2sequence_counts.pl -k $k -sum -$arg_rc | transpose.pl -q | body.pl 2 -1 | wc -l`;
   ($negative_total_count > 0) or die("The total number of negative counts is non-positive: $negative_total_count\n");
   open(FILE_NEG, $tmp_file_negative) or die("Could not open file '$tmp_file_negative' (intermediate file).\n");
   $file_ref_negative = \*FILE_NEG;

   $pseudo_norm_negative = $negative_total_count + (($alphabet_size ** $k) * $pseudocounts);

   while(my $l = <$file_ref_negative>)
   {
      chomp($l);
      my @r = split(/\t/,$l);
      $kmers_neg{ $r[0] } = ($kmers_neg{ $r[0] } + $r[1]);
   }

   if (length($neg_binomial_test) > 0)
   {
      open(TMP_FILE2, ">$tmp_file_negative_binomial_test") or die("Could not open file '$tmp_file_negative_binomial_test' for writing (intermediate file).\n");
      for (my $i = $first_index_inc; $i < $last_index_exc; $i++)
      {
	 my $j = $i;
	 my $seq = "";
	 while ($j >= $alphabet_size)
	 {
	    my $d = ($j % $alphabet_size);
	    $j = int($j / $alphabet_size) - 1;
	    $seq = "$alphabet{ $d }" . "$seq";
	 }
	 $seq = "$alphabet{ $j }" . "$seq";

	 my $tmp_p = ($kmers_neg{ $seq } / $pseudo_norm_negative);
	 my $tmp_n = $pseudo_norm_positive;
	 my $tmp_r = $kmers{ $seq };

	 print TMP_FILE2 "$seq\t$tmp_p\t$tmp_n\t$tmp_r\n";
      }
      close(TMP_FILE2);

      my $command = "compute_binomial_pvalue.pl $tmp_file_negative_binomial_test -pc 1 -nc 2 -rc 3 -2 -skip 0 > $tmp_file_negative_binomial_test2;";
      system("$command");
   }
}

for (my $i = $first_index_inc; $i < $last_index_exc; $i++)
{
   my $j = $i;
   my $seq = "";
   while ($j >= $alphabet_size)
   {
      my $d = ($j % $alphabet_size);
      $j = int($j / $alphabet_size) - 1;
      $seq = "$alphabet{ $d }" . "$seq";
   }
   $seq = "$alphabet{ $j }" . "$seq";

   $kmers_ratio{ $seq } = ($negative_total_count > 0) ? (($kmers{ $seq } / $pseudo_norm_positive) / ($kmers_neg{ $seq } / $pseudo_norm_negative)) : ($kmers{ $seq } / $pseudo_norm_positive);
   $kmers_stats_print{ $seq } = (length($neg) > 0) ? "$kmers_ratio{ $seq }" : "";
}

if ((length($neg) > 0) and (length($neg_binomial_test) > 0) and (!$uniform_weight_matrix))
{
   open(FILE_BINOMIAL, $tmp_file_negative_binomial_test2) or die("Could not open file '$tmp_file_negative_binomial_test2' (intermediate file).\n");
   $file_ref_binomial = \*FILE_BINOMIAL;

   while(my $l = <$file_ref_binomial>)
   {
      chomp($l);
      my @r = split(/\t/,$l);
      my $tmp_previous_stats_print = $kmers_stats_print{ $r[0] };
      $kmers_stats_print{ $r[0] } = "$r[4]" ."\t". "$pvalue_threshold" ."\t". "$tmp_previous_stats_print";
      if ($r[4] > $pvalue_threshold)
      {
	 $kmers_ratio{ $r[0] } = 1.0;
      }
   }
   close(FILE_BINOMIAL);
}

## print the statistics file

if (length($output_kmers_file) > 0)
{
   open(OUTPUT_KMERS_FILE, ">$output_kmers_file") or die("Could not open file '$output_kmers_file' for writing.\n");
   my $norm = 0;

   for my $kmer ( keys %kmers_ratio )
   {
      $norm = $norm + $kmers_ratio{$kmer};
   }

   if ((length($neg) > 0) and (length($neg_binomial_test) > 0))
   {
      print OUTPUT_KMERS_FILE "Kmer\tWeight\tPval\tPval threshold\tRatio\n";
   }
   elsif (length($neg) > 0)
   {
      print OUTPUT_KMERS_FILE "Kmer\tWeight\tRatio\n";
   }
   else
   {
      print OUTPUT_KMERS_FILE "Kmer\tWeight\n";
   }

   foreach my $kmer (sort {$kmers_ratio{$b} <=> $kmers_ratio{$a}} keys %kmers_ratio)
   {
      my $tmp_print_norm_weight = ($kmers_ratio{$kmer} / $norm);

      if (length($neg) > 0)
      {
	 my $tmp_print_pval_pvalthreshold_ratioraw = $kmers_stats_print{$kmer};
	 print OUTPUT_KMERS_FILE "$kmer\t$tmp_print_norm_weight\t$tmp_print_pval_pvalthreshold_ratioraw\n";
      }
      else
      {
	 print OUTPUT_KMERS_FILE "$kmer\t$tmp_print_norm_weight\n";
      }
   }
   close(OUTPUT_KMERS_FILE);
}

if ((length($neg) > 0) and (length($plot_kmers_frequencies) > 0))
{
   open(OUTPUT_KMERS_FILE_FOR_FIGURE, ">$tmp_file_kmers_stats_for_figure") or die("Could not open file '$tmp_file_kmers_stats_for_figure' for writing (intermediate file).\n");
   for my $kmer ( keys %kmers )
   {
      my $tmp_pos = log($kmers{$kmer});
      my $tmp_neg = log($kmers_neg{$kmer});
      print OUTPUT_KMERS_FILE_FOR_FIGURE "$kmer\t$tmp_neg\t$tmp_pos\n";
   }
   close(OUTPUT_KMERS_FILE_FOR_FIGURE);
   my $figure_file_name = "$output_kmers_file" . ".png";
   my $command = "make_gnuplot_graph.pl $tmp_file_kmers_stats_for_figure -x1 2 -y1 3 -k1 Kmers -ds1 point -xl \"log(frequnecy) negative_set\" -yl \"log(frequnecy) positive_set\" -t \"$k mers frequencies in the two data sets\" -o $figure_file_name -png";
   #print STDERR "$command\n";
   system("$command");
}

## print the weight matrix

if ($print_weight_matrices_token)
{
   print STDOUT "<WeightMatrices>\n";
}
print STDOUT "<WeightMatrix Name=\"$weight_matrix_name\" Type=\"MarkovOrder\" LeftPaddingPositions=\"0\" RightPaddingPositions=\"0\" Order=\"$markov_order\">\n";

my $parent = -1;

for (my $my_markov_order = 0; $my_markov_order <= $markov_order; $my_markov_order++)
{
   for (my $i=0; $i < ($alphabet_size ** $my_markov_order); $i++)
   {
      my $parents_print_format = &ParentsIndex2PrintFormat($parent);
      my @weights = &CalcWeights($parent);

      print STDOUT "  <Order Markov=\"$my_markov_order\" ";
      if ($my_markov_order > 0)
      {
	 print STDOUT "Parents=\"$parents_print_format\" ";
      }
      print STDOUT "Weights=\"";


      for (my $j=0; $j < @weights -1; $j++)
      {
	 print STDOUT "$weights[$j];";
      }
      my $j = @weights -1;
      print STDOUT "$weights[$j]\"></Order>\n";

      $parent++;
   }
}

print STDOUT "</WeightMatrix>\n";
if ($print_weight_matrices_token)
{
   print STDOUT "</WeightMatrices>\n";
}

system("/bin/rm -f $tmp_file_input_positive $tmp_file_positive $tmp_file_negative $tmp_file_negative_binomial_test $tmp_file_kmers_stats_for_figure");

sub ParentsIndex2PrintFormat
{
   my $parent = shift;
   my $j = $parent;
   my $seq = "";
   if ($j >= 0)
   {
      while ($j >= $alphabet_size)
      {
	 my $d = ($j % $alphabet_size);
	 $j = int($j / $alphabet_size) - 1;
	 $seq = "$d" . ";" . "$seq";
      }
      $seq = "$j" . ";" . "$seq";
   }

   chop($seq);
   return $seq;
}

sub CalcWeights
{
   my $parent = shift;
   my $j = $parent;
   my $seq = "";
   if ($j >= 0)
   {
      while ($j >= $alphabet_size)
      {
	 my $d = ($j % $alphabet_size);
	 $j = int($j / $alphabet_size) - 1;
	 $seq = "$alphabet{ $d }" . "$seq";
      }
      $seq = "$alphabet{ $j }" . "$seq";
   }

   my $prefix = "$seq";

   my $suffix_length = (($k - length($prefix)) - 1);

   my $first_index_inc = 0;
   for (my $i = 1; $i < $suffix_length; $i++)
   {
      $first_index_inc += ($alphabet_size ** $i);
   }
   my $last_index_exc = $first_index_inc + ($alphabet_size ** $suffix_length);
   my $total_counts = 0;
   my @res;
   for (my $letter = 0; $letter < $alphabet_size; $letter++)
   {
      $res[$letter] = 0;
   }

   for (my $letter = 0; $letter < $alphabet_size; $letter++)
   {
      my $letter_str = "$alphabet{ $letter }";

      if ($suffix_length > 0)
      {
	 for (my $i = $first_index_inc; $i < $last_index_exc; $i++)
	 {
	    my $j1 = $i;
	    my $suffix = "";
	    while ($j1 >= $alphabet_size)
	    {
	       my $d = ($j1 % $alphabet_size);
	       $j1 = int($j1 / $alphabet_size) - 1;
	       $suffix = "$alphabet{ $d }" . "$suffix";
	    }
	    $suffix = "$alphabet{ $j1 }" . "$suffix";
	    my $kmer_str = "$prefix" . "$letter_str" . "$suffix";
	    my $tmp_count = $kmers_ratio{ $kmer_str };
	    $res[$letter] = $res[$letter] + $tmp_count;
	    $total_counts = $total_counts + $tmp_count;
	 }
      }
      else
      {
	 my $kmer_str = "$prefix" . "$letter_str";
	 my $tmp_count = $kmers_ratio{ $kmer_str };

	 $res[$letter] = $res[$letter] + $tmp_count;
	 $total_counts = $total_counts + $tmp_count;
      }
   }

   for (my $letter = 0; $letter < $alphabet_size; $letter++)
   {
      if ($normalize_weights)
      {
	 $res[$letter] = $res[$letter] / $total_counts;
      }
   }

   return @res;
}

__DATA__

stab2markov_gxw.pl <file.stab>

   Takes in a stab file and construct a (K-1)-order Markov model (gxw format) by counting all Kmers in the sequences set.

   Can work in a discriminating framework by taking the ratio of Kmer counts between a positive and negative sequences sets
   (the negative collection is given by the -neg flag).

   -k <int>              The Kmer length (the 'K'...), i.e. the markov order plus one (default: 1)

   -u                    Output a uniform weight matrix (the input stab file is not needed) (default: constract by the stab file)

   -neg <file.stab>      A negative collection of sequences (default: use only positive collection).
                         If given, constructs the model by enrichment of Kmers in the positive vs the negative collections
                         i.e., probability ~ Kmer-positive-counts/Kmer-negative-counts

   -sc                   Declare that the input file <file.stab> is not a stab file, but a sequence counts file,
                         i.e., two columns: col1= name of Kmer and col2= counts (including pseudocounts if needed), with no header
                         (default: expects a stab input file)

   -negsc                Declare that the <file.stab> given in the '-neg' flag is not a stab file, but a sequence counts file,
                         i.e., two columns: col1= name of Kmer and col2= counts (including pseudocounts if needed), with no header
                         (default: '-neg' expects a stab file)

   -nnorm                In '-neg' mode only: do not normalize the weights (default: normalize)

   -negb <double>        Use a binomial test (positive to negative, including pseudocounts) and flatten non significant ratios,
                         i.e. "pvalue > <double>" (default: use raw ratios).

                         ** Notice: the binomial test fails numerically for large numbers, so having many sequences you'd get a 0 p-value **

   -negb_bonf            Apply a Bonfferoni correction on the binomial test (default: don't)

   -pc <int>             Pseudo-count for all Kmers (default: 1 count)

   -nrc                  Do **not** count Kmers on the reverse complements of the sequences (default: use reverse complements)

   -n <str>              The weight matrix name (default: "Background")

   -alph <TYPE>          The alphabet type, with TYPE = DNA/RNA (default = DNA)

   -okmers <file_name>   Output to <file_name> the list of all Kmers with their weights (and other statistics for the -neg and -negb flags)
                         in a descending order, after taking the pseudocounts and ratios with the negative set (default: do not output such a file).

   -okmers_png           Output a dot-plot of the Kmers' frequencies in the positive and negative sets (must have both -neg & -okmers flags),
                         using the same name as in -okmers with suffix ".png" (default: no plot)

   -nwms                 Don't print the "<WeightMatrices>" tokens, i.e. the first and last lines (defaut: print them)


