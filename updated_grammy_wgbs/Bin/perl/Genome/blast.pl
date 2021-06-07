#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $BLAST_EXE_DIR;

my $model_name = `grep 'model name' /proc/cpuinfo | uniq`;
if ($model_name =~ "AMD")
{
   my $uname = `uname -m`;
   if ($uname =~ "i686")
   {
      $BLAST_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Blast/32bit/blast-2.2.10/bin";
   }
   elsif ($uname =~ "x86_64")
   {
      $BLAST_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Blast/64bit/Sun/blast-2.2.18/bin";
   }
   else
   {
      print STDERR "Error: Unknown machine type (expecting \$MACHTYPE to be i686 or x86_64).\n";
      exit 1;
   }
}
elsif ($model_name =~ "Intel")
{
#   $BLAST_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Blast/64bit/SGI/blast-2.2.18/bin";
 $BLAST_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Blast/64bit/Sun/blast-2.2.18/bin";
}
else
{
  print STDERR "Error: Unknown machine type (expecting 'model name' (in /proc/cpuinfo) to contain \"AMD\" or \"Intel\").\n";
  exit 1;
}

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

my $database_file = get_arg("d", "", \%args);
my $processed_database_file = get_arg("pd", "", \%args);
my $one_based = get_arg("1", 0, \%args);

#----------------#
# Other options  #
#----------------#
my $flag_F = get_arg("F", "T", \%args);
my $flag_G = get_arg("G", -1, \%args);
my $flag_E = get_arg("E", -1, \%args);
my $flag_q = get_arg("q", -3, \%args);
my $flag_r = get_arg("r", 1, \%args);
my $flag_p = get_arg("p", "blastn", \%args);
my $flag_e = get_arg("e", 10.0, \%args);
my $flag_v = get_arg("v", 1000, \%args);
my $flag_M = get_arg("M", "BLOSUM62", \%args);
my $flag_g = get_arg("g", "T", \%args);
my $flag_S = get_arg("S", 3, \%args);
my $flag_W_default = ($flag_p eq "blastn") ? 11 : 3;
my $flag_W = get_arg("W", $flag_W_default, \%args);
my $print_matches = get_arg("pm", "", \%args);
my $print_query_length = get_arg("pq", "", \%args);
my $print_startend_mismatches = get_arg("pe", "", \%args);
my $print_total_mismatches  = get_arg("pt", "", \%args);


if ( $flag_G == -1 ) {
  if ( $flag_p eq "blastp" ) { $flag_G = 11; }
  else { $flag_G = 5; }
}
if ( $flag_E == -1 ) {
  if ( $flag_p eq "blastp" ) { $flag_E = 1; }
  else { $flag_E = 2; }
}


my $flags = " -F $flag_F -G $flag_G -E $flag_E -q $flag_q -r $flag_r -e $flag_e -v $flag_v -b $flag_v -M $flag_M -g $flag_g -W $flag_W -S $flag_S";

my $r = int(rand(1000000));

my $dbtype;
if (($flag_p eq "blastn") or ($flag_p eq "tblastn") or ($flag_p eq "tblastx")){ $dbtype="F" }
elsif (($flag_p eq "blastp") or ($flag_p eq "blastx")) { $dbtype="T" }
else { die "$flag_p is an invalid blast program\n" }

my $blast_database;
if (length($database_file) > 0)
{
  system("$BLAST_EXE_DIR/formatdb -i $database_file -p $dbtype -n tmp_$r -l tmp_$r");
  $blast_database = "tmp_$r";
}
elsif (length($processed_database_file) > 0)
{
  $blast_database = "$processed_database_file";
}

my $input_file = (-f $ARGV[0]) ? "-i $ARGV[0] " : "";
my $cmd = "$BLAST_EXE_DIR/blastall -p $flag_p -d $blast_database $input_file -o tmp_$r -m 8 $flags";

system($cmd);

my $subtract = $one_based == 1 ? 0 : 1;


print "Q name\tT name\t% identity\tAlignment length\tMismatches\tGap openings\tQ start\tQ end\tT start\tT end\te-value\tbit score";
if ($print_matches ne ""){ print "\tMatches" }
if ($print_query_length ne ""){ print "\tQ length" }
if ($print_startend_mismatches ne ""){ print "\tStart mismatches\tEnd mismatches" }
if ($print_total_mismatches ne ""){ print "\tTotal mismatches" }

print "\n";

my $current_hit="";
my $current_hit_length=0;
my $get_query_lengths=0;

my $infile_finished = 0;
my $infile_line;

if ($print_query_length ne "" or $print_startend_mismatches ne "" or $print_total_mismatches ne ""){ $get_query_lengths=1 }
if ($get_query_lengths){ open (INFILE,$file) }
open (RESULTS,"tmp_$r");
while(<RESULTS>){
  chomp;
  my @hit=split/\t/;

  if ($hit[6]>$hit[7]){
    my $tmp=$hit[7];
    $hit[7]=$hit[6];
    $hit[6]=$tmp;
    $tmp=$hit[8];
    $hit[8]=$hit[9];
    $hit[9]=$tmp;
  }

  $hit[6]-=$subtract;
  $hit[7]-=$subtract;
  $hit[8]-=$subtract;
  $hit[9]-=$subtract;


  while ($get_query_lengths and $current_hit ne $hit[0] and $infile_finished == 0)
  {
    $infile_line =<INFILE>;
    if (length($infile_line) > 0) 
    {
       if ($infile_line =~ /^>(\S+)/)
       {
	  $current_hit=$1;
	  $infile_line = <INFILE>;
	  chomp $infile_line;
	  if (length($infile_line) <= 0)
	  {
	     print STDERR "Error in input fasta file - Id $current_hit has no sequence\n";
	     exit 1;
	  }
	  else
	  {
	     $current_hit_length = length($infile_line);
	  }
       }
    } 
    else 
    {
       $infile_finished = 1;
    }
  }

  print join("\t",@hit);
  if($print_matches){ print "\t",$hit[3]-$hit[4]-$hit[5] }
  if($print_query_length){ print "\t$current_hit_length" }
  if($print_startend_mismatches){
    my $start_mismatches=$hit[6]+$subtract-1;
    my $end_mismatches=$current_hit_length-($hit[7]+$subtract);
    print "\t$start_mismatches\t$end_mismatches";
  }
  if ($print_total_mismatches)
  {
     my $total_mismatches = $hit[6] - 1 + $current_hit_length - $hit[7] + $hit[4];
     print "\t$total_mismatches";
  }
  print "\n";
}
close (RESULTS);
if ($get_query_lengths){ close (INFILE) }

system("rm tmp_$r*");

__DATA__

blast.pl <file>

   Takes in as input a query fasta file and a database fasta file and queries 
   the database using blast with the query fasta file. Note that the query
   file may contain multiple sequences.
   
   NOTE: The original blast.pl reproted locations in 1-base, but now it works in 0-base (16 May 2006)!!!

   -d <str>:  Database fasta file
   -pd <str>: Processed database file (do not run formatdb on it)

   -1:        Report results in 1-based coordinates (default: 0-based)

   -p <str>:  Program type: blastn/blastp/tblastn/tblastx/blastx (default: blastn)
   -F <T/F>:  Filter query sequence using 'DUST' for blastn, 'SEG' for others (default: T)
   -G <int>:  Cost to open a gap (default: 5 nucleotide, 11 protein)
   -E <int>:  Cost to extend a gap (default: 2 nucleotide, 1 protein)
   -q <int>:  Penalty for a mismatch (nucleotide only) (default: -3)
   -r <r>:    Reward for a match (nucleotide only) (default: 1)
   -M <str>:  Matrix: BLOSUM45/BLOSUM62/BLOSUM80/PAM30/PAM70 (protein only) (default: BLOSUM62)
   -g <T/F>:  Allow gaps (default: T)
   -e <real>: Expectation value (E) threshold (default: 10.0)
   -v <int>:  Maximal number of hits to show per query sequence (default: 1000) 
   -W <int>:  Word size of the "seed" (default: 11 for blastn, 3 for other programs). 
   -S <int>:  Specifies which nucleotide query strand to use in the search. (1=fwd, 2=rev, 3=both (default))

   -pm :      Print number of matches
   -pq :      Print query length
   -pe :      Print edge mismatches (start and end separately)


