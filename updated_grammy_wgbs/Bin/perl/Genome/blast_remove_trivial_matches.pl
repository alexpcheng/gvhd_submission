#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $FILE_A_REF;
my $file_bl = get_arg("bl", "", \%args);

if (length($file_bl) == 0)
{
  die("The blast output file not given.\n");
}
else
{
  open(FILE_A, $file_bl) or die("Could not open the blast output file '$file_bl'.\n");
  $FILE_A_REF = \*FILE_A;
  close(FILE_A); # we just wanted to verify that the file exists.
}

my $FILE_B_REF;
my $file_chr = get_arg("chr", "", \%args);

if (length($file_chr) == 0)
{
  die("The chr file (of the blast query) not given.\n");
}
else
{
  open(FILE_B, $file_chr) or die("Could not open the chr file '$file_chr'.\n");
  $FILE_B_REF = \*FILE_B;
  close(FILE_B); # we just wanted to verify that the file exists.
}

my $file_output = get_arg("o", "", \%args);

if (length($file_output) == 0)
{
  die("The output file name must be specified.\n");
}

my $r = int(rand(1000000));

my $str1 = `cat $file_bl | cut.pl -f 2,1,9,10 | modify_column.pl -c 2 -minc 3 | cut.pl -f 1,2,3,2 | merge_columns.pl -1 1 -2 0 -d "_" | merge_columns.pl -1 0 -2 1 -d "_" | cut.pl -f 1 | paste $file_bl - > tmp_1_$r`; 

my $str2 = `cat $file_chr | modify_column.pl -c 2 -min 3 | merge_columns.pl -1 1 -2 0 -d "_" | merge_columns.pl -1 0 -2 1 -d "_" | cut.pl -f 1 > tmp_2_$r`;

my $str3 = `join.pl tmp_1_$r tmp_2_$r -1 13 -2 0 -neg -sk > $file_output`;

system("rm -f tmp_1_$r* tmp_2_$r*");


__DATA__

blast_remove_trivial_matches.pl -bl <blast> -chr <chr> -o <output>

   Takes an output of blast search <blast> and a chr file of the blast query <chr>, 
   and filters out the trival exact matches of the query, into an output file <output>.
  
   -bl <blast>:    The original blast output file.
   -chr <chr>:     The chr file for the blast query.
   -o <output>:    The output file.
