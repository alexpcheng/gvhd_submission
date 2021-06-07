#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";
require "$ENV{PERL_HOME}/Lab/library_helpers.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $ref_ids_str = get_arg("ref_ids", "", \%args);
my $pre = get_arg("pre", "data", \%args);
my $max_errors = get_arg("max_errors", 20, \%args);
my $strains_table = get_arg("strains_table", "$ENV{HOME}/Develop/Lab/Databases/Strains/StrainsTable.tab", \%args);
my $gopen = get_arg("gopen", 10, \%args);
my $gext = get_arg("gext", 5, \%args);
my $dbg = get_arg("debug", 0, \%args);

my @ref_ids = &parseRanges($ref_ids_str);

if ($#ref_ids < 0)
{
   print STDERR "Error: Please supply valid list of reference ids (-ref_ids parameter)\n";
   exit 1;
}

if (! -e $strains_table)
{
   print STDERR "Error: Strains table file not found ($strains_table)\n";
   exit 1;
}

my $curr_snps;
my $actual_ids_str;
my @actual_ids;

open (ACT_FILE, ">${pre}_actual_seqs.txt") or die ("Failed to open ${pre}_actual_seqs.txt for writing");

print ACT_FILE "RefID\tActualID\tnErrors\tnSNPs\tnRealErrors\n";

for my $ref (@ref_ids)
{
   print STDERR "Processing $ref sequences...\n";

   system ("dos2unix.pl < $strains_table | filter.pl -q -c 0 -estr $ref | cut -f 1,7 > tmp_${ref}.stab");
   system ("dos2unix.pl < $strains_table |  filter.pl -q -c 0 -nstr $ref | filter.pl -q -c 3 -estr $ref | filter.pl -q -c 7 -max $max_errors | cut -f 1,7 | uniq_sorted.pl -n 0 -split_by_field 0 -f_pos $ref");
   
   $actual_ids_str = `dos2unix.pl < $strains_table |  filter.pl -q -c 0 -nstr $ref | filter.pl -q -c 3 -estr $ref | filter.pl -q -c 7 -max $max_errors | cut -f 1`;
   chop $actual_ids_str;
   @actual_ids = split (/\s/, $actual_ids_str);

   if (-e "tmp_${ref}.stab" and $#actual_ids >= 0)
   {
      my $tmp_cmd = "cat ";
      for my $act (@actual_ids)
      {
	 $tmp_cmd .= "tmp_${ref}_${act}.tab ";
      }
      system($tmp_cmd . "| needle.pl  -alignto tmp_${ref}.stab -summary_output tmp_${ref}.out -alignment tmp_${ref}_align.out");
      $curr_snps = `cat tmp_${ref}.out | grep -v '^#' | grep -v Ambigious | cut -f 3,4 | modify_column.pl -c 1 -sc 0 | modify_column.pl -c 1 -a 1 | compute_column_stats.pl -c 1 -skip 0 -s | cut -f 2`;
      chop $curr_snps;
      $curr_snps = $curr_snps ? $curr_snps : 0;

      for my $act (@actual_ids)
      {
	 
	 system("needle.pl tmp_${ref}_${act}.tab -alignto tmp_${ref}.stab -summary_output tmp_${ref}_${act}.out -alignment tmp_${ref}_${act}_align.out");
	 my $curr_errors = `cat tmp_${ref}_${act}.out | grep -v '^#' | cut -f 3,4 | modify_column.pl -c 1 -sc 0 | modify_column.pl -c 1 -a 1 | compute_column_stats.pl -c 1 -skip 0 -s | cut -f 2`;
	 chop $curr_errors;
	 
	 $curr_errors = $curr_errors ? $curr_errors : 0;
	 
	 print ACT_FILE "$ref\t$act\t$curr_errors\t$curr_snps\t".($curr_errors - $curr_snps)."\n";

	 if (! $dbg)
	 {
	    system ("rm tmp_${ref}_${act}.tab tmp_${ref}_${act}.out tmp_${ref}_${act}_align.out");
	 }
      }
      
      if (! $dbg)
      {
	 system ("rm tmp_${ref}.stab tmp_${ref}.out tmp_${ref}_align.out");
      }
   }
   else
   {
      my $missing_str;
      if (-z "tmp_${ref}.stab")
      {
	 $missing_str = "NO_REFERENCE";
      }
      else
      {
	 $missing_str = "NO_ACTUAL";
      }

      print ACT_FILE "$ref\t$missing_str\t$missing_str\t$missing_str\t$missing_str\n";

      system ("rm tmp_${ref}.stab");
   }
}

close ACT_FILE;

if (-e "${pre}_actual_seqs.txt")
{
   system "cat ${pre}_actual_seqs.txt | cut -f 1,3- | average_rows.pl -skip 1 -take_min > ${pre}_ref_seq.txt";
}


__DATA__

    compare_actual_seqs_to_ref.pl

    Count SNPs in actual sequences fetched from the strains table (consensus errror in all actual sequences).


       -ref_ids <str>              Comma separated list of reference IDs to use, supports range  (e.g. '567,569,582-595,599')

       -pre <str>                  Prefix for output files (<str>_ref_seq.txt and <str>_actual_seqs.txt will be created, default: "data")

       -max_errors <num>           Discard actual sequences with more then <num> errors (default: 20)
       -strains_table <str>        Path to strain table to use (default: /home/$USER/Develop/Lab/Databases/Strains/StrainsTable.tab)

       -gopen <num>                Gap open panelty (Default = 10).
       -gext <num>                 Gap extend panelty (Default = 5).

       -debug                      Print debug output and files
