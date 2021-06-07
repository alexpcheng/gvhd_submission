#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
#require "$ENV{PERL_HOME}/Lib/format_number.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $matrix_file = $ARGV[0];
my $matrix_file_ref;

my $scale_by_all_matrix = get_arg("all", 0, \%args);
my $standarize = get_arg("st", 0, \%args);
my $add_value = get_arg("a", 0, \%args);

if (length($matrix_file) < 1 or $matrix_file =~ /^-/)
{
  $matrix_file_ref = \*STDIN;
}
else
{
  open(MATRIX_FILE, $matrix_file) or die("Could not open the tab-delimited matrix file '$matrix_file'.\n");
  $matrix_file_ref = \*MATRIX_FILE;
}

my $r = rand();
my $tmp_file_name = "tmp_" . "$r";
my $tmp_file_ref;
my $tmp_file_read_ref;

if ($scale_by_all_matrix)
{
   open(TMP_FILE, ">$tmp_file_name");
   $tmp_file_ref = \*TMP_FILE;
}

my $DEBUG = 1;

my $INFINITY = 100000000;
my $INFINITY_NEG = -100000000;

# skip 1st row (header)
my $tmp_row = <$matrix_file_ref>;
chomp($tmp_row);

print STDOUT "$tmp_row\n";

my $min_all = $INFINITY;
my $max_all = $INFINITY_NEG;
my $mean_all = 0;
my $var_all = 0;
my $std_all = 0;
my $eff_i = 0;

if ($scale_by_all_matrix)
{
   while($tmp_row = <$matrix_file_ref>)
   {
      chomp($tmp_row);
      my @tmp = split(/\t/,$tmp_row,-1);

      # skip 1st column (header)
      my $column_header = shift(@tmp);

      for (my $i=0; $i < @tmp; $i++)
      {
	 if (length($tmp[$i]) > 0)
	 {
	    $eff_i++;
	    $min_all = ($tmp[$i] < $min_all) ? $tmp[$i] : $min_all;
	    $max_all = ($tmp[$i] > $max_all) ? $tmp[$i] : $max_all;
	    my $tmp_a = (($eff_i - 1) / $eff_i);
	    $var_all = (($tmp_a * $var_all) + ((1 - $tmp_a) * (($tmp[$i] - $mean_all) ** 2)));
	    $mean_all = (($tmp_a * $mean_all) + ((1 - $tmp_a) * ($tmp[$i])));
	 }
      }

      print $tmp_file_ref "$tmp_row\n";
   }
}

if ($scale_by_all_matrix)
{
   close($tmp_file_ref);
   open(TMP_FILE_READ, "$tmp_file_name");
   $tmp_file_read_ref = \*TMP_FILE_READ;
   $std_all = ($var_all > 0) ? sqrt($var_all) : 1;
}

$tmp_row = ($scale_by_all_matrix) ? <$tmp_file_read_ref> : <$matrix_file_ref>;

while($tmp_row)
{
   chomp($tmp_row);
   my @tmp = split(/\t/,$tmp_row,-1);

   # skip 1st column (header)
   my $column_header = shift(@tmp);

   my $min = $INFINITY;
   my $max = $INFINITY_NEG;
   my $mean = 0;
   my $var = 0;
   my $std = 0;
   my $eff_i = 0;

   if ($scale_by_all_matrix)
   {
      $min = $min_all;
      $max = $max_all;
      $mean = $mean_all;
      $std = $std_all;
   }
   else
   {
      for (my $i=0; $i < @tmp; $i++)
      {
	 if (length($tmp[$i]) > 0)
	 {
	    $eff_i++;
	    $min = ($tmp[$i] < $min) ? $tmp[$i] : $min;
	    $max = ($tmp[$i] > $max) ? $tmp[$i] : $max;
	    my $tmp_a = (($eff_i - 1) / $eff_i);
	    $var = (($tmp_a * $var) + ((1 - $tmp_a) * (($tmp[$i] - $mean) ** 2)));
	    $mean = (($tmp_a * $mean) + ((1 - $tmp_a) * ($tmp[$i])));
	 }
      }
      $std = ($var > 0) ? sqrt($var) : 1;
   }

   my $tmp_sub = ($standarize) ? $mean : $min;
   my $tmp_div = ($standarize) ? $std : ($max - $min);

   my @tmp1 = map { (length($_) > 0) ? ($add_value + (($_ - $tmp_sub) / $tmp_div)) : $_ } @tmp;

   print STDOUT "$column_header";

   for (my $i=0; $i < @tmp1; $i++)
   {
      print STDOUT "\t$tmp1[$i]";
   }

   print STDOUT "\n";

   $tmp_row = ($scale_by_all_matrix) ? <$tmp_file_read_ref> : <$matrix_file_ref>;
}

if ($scale_by_all_matrix)
{
   close($tmp_file_read_ref);
   system("/bin/rm -f $tmp_file_name");
}

#---------------------------------------------------------------------#
# --help                                                              #
#---------------------------------------------------------------------#

__DATA__

 Syntax:         tab_scale_rows.pl <matrix.tab>

 Description:    Given a matrix <matrix.tab> (tab file format), can scale/standarize each row seperatly or
                 all matrix together. Scaling is done by substructing the min and dividing by (max-min),
                 while standarization is done by substructing the mean and dividing by the standard deviation.

                 Assume <matrix.tab> has one row header and one column header. Can handle with missing values.

 Output:         A tab file format file of the scaled matrix.

 Flags:

  -all           Scale/Standarize with respect to the entire matirx (default: for each row seperatly)

  -st            Standarize the data (default: scale the data).

  -a <int>       Add <int> to the transformed value (defualt = 0).
