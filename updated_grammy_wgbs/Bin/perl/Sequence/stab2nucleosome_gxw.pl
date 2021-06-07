#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file_ref_positive;
my $file = $ARGV[0];
my %args = load_args(\@ARGV);

my $nucleosome_background_matrix_name = "NucleosomeBackground";
my $nucleosome_background_matrix = get_arg("nucbck", "", \%args);
my $nucleosome_half_length = get_arg("lhf", 73, \%args);
my $pivot = $nucleosome_half_length + 1;
my $k = get_arg("k", 2, \%args);
my $markov_order = $k - 1;
($k >= 1) or die("K must be a positive integer, given: $k\n");
my $smooth_half_window = get_arg("sm", 1, \%args);
my $markov_gxw_template_name = get_arg("np", "Nuc", \%args);
my $pseudocounts = get_arg("pc", 1, \%args);
my $nucleosome_weight_matrix_name = get_arg("n", "Nucleosome", \%args);
my $alphabet_str = "ACGT";

my $r = int(rand(1000000));
my $tmp_file_input_positive = "stab2nucleosome_gxw_input_positive_" . $r . "_tmp";
my $tmp_file_positive = "stab2nucleosome_gxw_positive_" . $r . "_tmp";
my $tmp_file_positive_chr = "stab2nucleosome_gxw_positive_chr_" . $r . "_tmp";
my $tmp_file_negative_chr = "stab2nucleosome_gxw_negative_chr_" . $r . "_tmp";
my $tmp_file_negative_sequence_counts_tmp1 = "stab2nucleosome_gxw_negative_sequence_counts_tmp1_" . $r . "_tmp";
my $tmp_file_negative_sequence_counts = "stab2nucleosome_gxw_negative_sequence_counts_" . $r . "_tmp";
my $command = "";

if (length($file) < 1 or $file =~ /^-/)
{
   open(TMP_FILE, ">$tmp_file_input_positive") or die("Could not open file '$tmp_file_input_positive' for writing (intermediate file).\n");
   while(my $l = <STDIN>)
   {
      chomp($l);
      print TMP_FILE "$l\n";
   }
   close(TMP_FILE);

   $command = "cat $tmp_file_input_positive | stab2reverse_complement.pl | cat - $tmp_file_input_positive | lin.pl | merge_columns.pl -d _ > $tmp_file_positive;";
   system("$command");
}
else
{
   $command = "cat $file | stab2reverse_complement.pl | cat - $file | lin.pl | merge_columns.pl -d _ > $tmp_file_positive;";
   system("$command");
}

my $uniform_positions = get_arg("u", "", \%args);
my @uniform_positions_list = split(/,/,$uniform_positions);
my %uniform_positions_hash = ();
foreach my $uni_pos (@uniform_positions_list)
{
   $uniform_positions_hash{$uni_pos} = 1;
}

my $take_over_total_non_uniformed_positions = get_arg("overbck", 0, \%args);

print STDOUT "<WeightMatrices>\n";

if (length($nucleosome_background_matrix) > 0)
{
   my $str2print = `cat $nucleosome_background_matrix | sed '/WeightMatrices/d'`; #### | sed -r 's/Name=\"[^\S]+\"/Name=\"$nucleosome_background_matrix_name\"/'`;
   my @lines2print = split(/\n/,$str2print);
   for (my $l = 0; $l < @lines2print; $l++)
   {
      my $tmp2print = $lines2print[$l];
      chomp($tmp2print);
      print STDOUT "$tmp2print\n";
   }
}

## prepare the stab file of all non-uniform positions, for the negative set (normalization by collection's background)

$command = "echo -n > $tmp_file_negative_sequence_counts_tmp1";
system("$command");

if ($take_over_total_non_uniformed_positions != 0)
{
   if ($take_over_total_non_uniformed_positions == 1)
   {
      for (my $i=1; $i<=$k; $i++)
      {
	 for (my $position = 0; $position <= $nucleosome_half_length; $position++)
	 {
	    if ($i <= ($position+1))
	    {
	       #my $k_eff = $k < ($position+1) ? $k : ($position+1);
	       my $real_position = $pivot + $position;

	       if (!exists $uniform_positions_hash{$position})
	       {
		  $command = "cat $tmp_file_positive | stab2length.pl | lin.pl | add_column.pl -b -s s | merge_columns.pl | add_column.pl -s 1 | cut.pl -f 2,1,4,3 | chr_append_flanking_regions.pl -exact_l $i -b | modify_column.pl -c 2,3 -a $position | modify_column.pl -c 3 -a $smooth_half_window | modify_column.pl -c 2 -s $smooth_half_window > $tmp_file_negative_chr; cat $tmp_file_positive | extract_sequence.pl -f $tmp_file_negative_chr | cut -f2 | sed -r 's/[^$alphabet_str]/\\n/g' | filter.pl -c 0 -minl $i | lin.pl | stab2sequence_counts.pl -k $i -sum | transpose.pl -q | body.pl 2 -1 >> $tmp_file_negative_sequence_counts_tmp1";
	       system("$command");
	       }
	    }
	 }
	 $command = "cat $tmp_file_negative_sequence_counts_tmp1 | list2neighborhood.pl -sum | sort > $tmp_file_negative_sequence_counts$i";
	 system("$command");
	 $command = "echo -n > $tmp_file_negative_sequence_counts_tmp1";
	 system("$command");
      }
   }
   else
   {
      for (my $i=1; $i<=$k; $i++)
      {
	 $command = "cat $take_over_total_non_uniformed_positions | cut -f2 | sed -r 's/[^$alphabet_str]/\\n/g' | filter.pl -c 0 -minl $i | lin.pl | stab2sequence_counts.pl -k $i -sum | transpose.pl -q | body.pl 2 -1 | sort > $tmp_file_negative_sequence_counts$i";
	 system("command");
      }
   }
}

## print the position specific markov weight matrices

for (my $position = 0; $position <= $nucleosome_half_length; $position++)
{
   my $k_eff = $k < ($position+1) ? $k : ($position+1);
   my $real_position = $pivot + $position;
   my $markov_gxw_name = "$markov_gxw_template_name$real_position";
   my $str2print = "";

   if (exists $uniform_positions_hash{$position})
   {
      $str2print = `stab2markov_gxw.pl -u -k $k_eff -nrc -n $markov_gxw_name -pc $pseudocounts -nwms`;
   }
   else
   {
      $command = "cat $tmp_file_positive | stab2length.pl | lin.pl | add_column.pl -b -s s | merge_columns.pl | add_column.pl -s 1 | cut.pl -f 2,1,4,3 | chr_append_flanking_regions.pl -exact_l $k_eff -b | modify_column.pl -c 2,3 -a $position | modify_column.pl -c 3 -a $smooth_half_window | modify_column.pl -c 2 -s $smooth_half_window > $tmp_file_positive_chr";

      system("$command");

      if ($take_over_total_non_uniformed_positions == 0)
      {
	 $str2print = `cat $tmp_file_positive | extract_sequence.pl -f $tmp_file_positive_chr | stab2markov_gxw.pl - -k $k_eff -nrc -n $markov_gxw_name -pc $pseudocounts -nwms`;
      }
      else
      {
	 $str2print = `cat $tmp_file_positive | extract_sequence.pl -f $tmp_file_positive_chr | stab2markov_gxw.pl - -k $k_eff -nrc -n $markov_gxw_name -pc $pseudocounts -nwms -neg $tmp_file_negative_sequence_counts$k_eff -negsc -nnorm`;
      }
   }

   my @lines2print = split(/\n/,$str2print);
   for (my $l = 0; $l < @lines2print; $l++)
   {
      my $tmp2print = $lines2print[$l];
      chomp($tmp2print);
      print STDOUT "$tmp2print\n";
   }
}

## print the nucleosome weight matrix
my $nucleosome_weight_matrix_left_padding_positions = 0;
my $nucleosome_weight_matrix_right_padding_positions = 0;

print STDOUT "<WeightMatrix Name=\"$nucleosome_weight_matrix_name\" Type=\"Nucleosome\" LeftPaddingPositions=\"$nucleosome_weight_matrix_left_padding_positions\" RightPaddingPositions=\"$nucleosome_weight_matrix_right_padding_positions\" DoubleStrandBinding=\"false\" EffectiveAlphabetSize=\"4\" Alphabet=\"ACGT\" >\n";

if (length($nucleosome_background_matrix) > 0)
{
   print STDOUT "  <SubMatrix Name=\"$nucleosome_background_matrix_name\"></SubMatrix>\n";
}
for (my $position = 0; $position <= $nucleosome_half_length; $position++)
{
   my $real_position = $pivot + $position;
   my $markov_gxw_name = "$markov_gxw_template_name$real_position";

   print STDOUT "  <SubMatrix Name=\"$markov_gxw_name\"></SubMatrix>\n";
}

print STDOUT "</WeightMatrix>\n";
print STDOUT "</WeightMatrices>\n";

system("/bin/rm -f $tmp_file_input_positive $tmp_file_positive $tmp_file_positive_chr $tmp_file_negative_chr $tmp_file_negative_sequence_counts_tmp1");
for (my $i=1; $i<=$k; $i++)
{
   system("/bin/rm -f $tmp_file_negative_sequence_counts$i");
}

__DATA__

stab2nucleosome_gxw.pl <file.stab>

   Takes in a stab file of aligned nucleosomal sequences and construct a (K-1)-order Nucleosome model (gxw format) by counting
   all dyad-symmetric position specific Kmers in the sequences set.


  -lhf <int>                The length of half the nucleosome (default: 73, i.e. a nucleosome of length 1+2*73=147bp)

  -k <int>                  The Kmer length (the K) taken for the statistics in each position, i.e. the Markov order plus one (default: 2)

  -sm <int>                 The smoothing window half size, for smoothing the Kmers around each position (default: 1bp)

  -pc <int>                 Set a pseudocount for each Kmer (default: 1)

  -np <str>                 The template name for each intrenal Markov order weight matrix (default: "Nuc", i.e. the matrix of position 14 is named "Nuc14")

  -n <str>                  The name of the new Nucleosome weight matrix (default: "Nucleosome")

  -u <int{1},,...,int{k}>   Set positions int{1} to int{k} (dyad is position 0) with uniform weight matrices (default: all matrices are constructed by data)

  -overbck <file.stab>      Take the position specific distributions (all non uniformed positions, see '-u') over (divided by) the K-order Markov model of the sequences in <file.stab>
                            (as a 'negative collection' in stab2markov_gxw.pl). If <file.stab> is not given, then use all non uniformed ('-u') positions as the negative sequence collection
                            (default: dont normalize, i.e. no negative sequences).

                            **** We do not normalize here these resulted weights, but the NucleosomeWeightMatrix does that upon construction.  ***

  -nucbck <file.gxw>        Add <file.gxw> as the nucleosome-background weight matrix. ** ASSUME Name="NucleosomeBackground" ** (default: no nucleosome background matrix)

