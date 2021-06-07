#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

#----------------#
# Load arguments #
#----------------#
my $file = $ARGV[0];
my %args = load_args(\@ARGV);
my $use_reverse_complement = get_arg("rc", 0, \%args);
my $take_frequencies_not_counts = get_arg("f", 0, \%args);

my $k = get_arg("k", 2, \%args);
($k >= 1) or die("K must be a positive integer, given: $k\n");

#---------------#
# TMP dir/files #
#---------------#
my $r = int(rand(1000000));
my $tmp_dir = "tmp_stab2positional_sequence_counts_" . "$r";
my $command = "mkdir -p $tmp_dir";
system("$command");
my $tmp_input_file_stab = "$tmp_dir/tmp_input_file.stab";

#-----------------#
# Read input file #
#-----------------#
if (length($file) < 1 or $file =~ /^-/)
{
   open(TMP_FILE, ">$tmp_input_file_stab") or die("Could not open file '$tmp_input_file_stab' for writing (intermediate file).\n");
   while(my $l = <STDIN>){ chomp($l); print TMP_FILE "$l\n"; }
   close(TMP_FILE);
}
else
{
   $tmp_input_file_stab = $file;
}

#---------------------------------#
# Compute statistics per position #
#---------------------------------#
my $max_sequence_length = `cat $tmp_input_file_stab | stab2length.pl | cut -f2 | sort -nr | head -n1`;
chomp($max_sequence_length);

for(my $i=0; $i<=($max_sequence_length-$k); $i++)
{
   my $tmp_output_file_tab2 = "$tmp_dir/tmp_output_file_$i.tab";
   my $i_from = 1 + $i;
   my $i_to = $i_from + $k -1;
   my $add_flags = "";
   if ($use_reverse_complement)
   {
      $add_flags = $add_flags . " -rc ";
   }
   if ($take_frequencies_not_counts)
   {
      $add_flags = $add_flags . " -f ";
   }
   $command = "cat $tmp_input_file_stab | extract_sequence.pl -s $i_from -e $i_to| stab2sequence_counts.pl -p 5 -k $k -sum " . $add_flags . " | transpose.pl -q | body.pl 2 -1 | sort -k 1 > $tmp_output_file_tab2";
   system("$command");
}

#----------------------------------------------#
# Collect results per position into one matrix #
#----------------------------------------------#
$command = "cat $tmp_dir/tmp_output_file_*.tab | cut -f1 | sort | uniq | sort > $tmp_dir/tmp_output_file.tab";
system("$command");

for(my $i=0; $i<=($max_sequence_length-$k); $i++)
{
   my $tmp_output_file_tab2 = "$tmp_dir/tmp_output_file_$i.tab";
   $command = "cat $tmp_dir/tmp_output_file.tab | join.pl -q -1 1 -2 1 -o 0 - $tmp_output_file_tab2 > $tmp_dir/tmp_output_file2.tab; cat $tmp_dir/tmp_output_file2.tab > $tmp_dir/tmp_output_file.tab";
   system("$command");
}

my $res_matrix_str = `cat $tmp_dir/tmp_output_file.tab | sort -k1 | transpose.pl -q | lin.pl -0 | transpose.pl -q`;


chomp($res_matrix_str);
my @res_matrix_rows = split(/\n/,$res_matrix_str);

#------------#
# Header row #
#------------#
my $l = $res_matrix_rows[0];
chomp($l);
my @row = split(/\t/,$l);
print STDOUT "Kmer\\Pos";
for(my $i=1;$i<@row;$i++)
{
   print STDOUT "\t$i";
}
print STDOUT "\n";

#------------#
# Other rows #
#------------#
for(my $j=1;$j<@res_matrix_rows;$j++)
{
   $l = $res_matrix_rows[$j];
   chomp($l);
   @row = split(/\t/,$l);
   print STDOUT "$row[0]";
   for(my $i=1;$i<@row;$i++)
   {
      print STDOUT "\t$row[$i]";
   }
   print STDOUT "\n";
}

#------------------#
# Clean up TMP dir #
#------------------#
system("/bin/rm -rf $tmp_dir");

#--------#
# --help #
#--------#

__DATA__

stab2positional_sequence_counts.pl <file.stab>

   Takes in a stab file sequences and construct a m x n matrix, with entry <i,j> the count
   of kmer i at position j in the sequence alignment. n is detrmined by the longest sequence.

  -k <int>       The Kmer length (the K) taken for the statistics in each position (default: 2)
  -rc            Count Kmers also from the reverse complement sequence (default: only forward strand)
  -f             Report frequencies instead of counts (default: report counts)
