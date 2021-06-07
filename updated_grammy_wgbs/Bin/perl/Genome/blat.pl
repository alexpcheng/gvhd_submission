#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

my $BLAT_EXE = "$ENV{GENIE_HOME}/Bin/Blat/blat";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);

my $database = get_arg("d", "", \%args);
my $queries_file = get_arg("q", "", \%args);
my $min_identity = get_arg("identity", 90, \%args);
my $print_header = get_arg("header", 0, \%args);
my $tile_size = get_arg("tile_size", 11, \%args);
my $no_ooc = get_arg("no_ooc", 0, \%args);
my $ooc_file = get_arg("ooc_file", "", \%args);

my $make_ooc = get_arg("make_ooc", 0, \%args);
my $ooc_output_file = get_arg("ooc_output_file", "" , \%args);

my $ooc_command = "";
my $database_dir = "";
my $pid = $$;

if ($print_header == 1)
{
  &PrintHeader;
  exit 0;
}

my @database_file_list = ();
if (-d $database)
{
   $database_dir = $database;
   foreach my $file ( `ls $database/*.fas`)
   {
      chop($file);
      push (@database_file_list, $file);
   }
}
else
{
   $database_dir = `dirname $database`;
   push (@database_file_list, $database);
}

if ($make_ooc == 1)
{
   if (length($ooc_output_file) == 0)
   {
      $ooc_output_file = "${tile_size}.ooc";
   }
}
elsif ($no_ooc == 0)
{
   if (length($ooc_file) == 0)
   {

      if (-e "${tile_size}.ooc")
      {
	 $ooc_file = "${tile_size}.ooc";
      }
      elsif (-e "${database_dir}/${tile_size}.ooc")
      {
	 $ooc_file = "${database_dir}/${tile_size}.ooc";
      }
      else
      {
	 print STDERR "Error: Overused tile file (${tile_size}.ooc) not found in current directory or at $database_dir\n";
	 exit 1;
      }
   }
   
   if (! -e $ooc_file)
   {
      print STDERR "Error: overused tile file ($ooc_file) not found.\n";
      exit 1;
   }
   else
   {
      $ooc_command = "-ooc=${ooc_file}";
   }
}
elsif (! -e $queries_file)
{
   print STDERR "Error: Queries fasta file ($queries_file) not found.\n";
   exit 1;
}

foreach my $db_file (@database_file_list)
{
   if ($make_ooc == 1)
   {
      system "echo $db_file >> tmp_${pid}_seq_list";
   }
   else
   {
      my $basename_file = `basename $db_file`;
      chop ($basename_file);
      system "$BLAT_EXE -tileSize=${tile_size} $ooc_command $db_file $queries_file tmp_blat_${basename_file}_${pid}.psl -noHead -minIdentity=$min_identity > /dev/null\n";
      system "cat tmp_blat_${basename_file}_${pid}.psl >> tmp_blat_${pid}.psl";
      system "rm tmp_blat_${basename_file}_${pid}.psl"; 
   }
}

if ($make_ooc == 1)
{
   system "$BLAT_EXE -makeOoc=${ooc_output_file} -tileSize=${tile_size} tmp_${pid}_seq_list /dev/null /dev/null";
   system "rm tmp_${pid}_seq_list";
}
else
{
   &PrintHeader;
   system "sort.pl tmp_blat_${pid}.psl -c0 9 | modify_column.pl -c 11 -a 1 | modify_column.pl -c 15 -a 1";
   system "rm tmp_blat_${pid}.psl";
}

sub PrintHeader
{
  print "Match\tMismatch\tRep match\tN's\tQ inserts\tQ inserts bps\tT inserts\tT inserts bp\tstrand\tQ name\tQ size\tQ start\tQ end\tT name\tT size\tT start\tT end\tBlock count\tBlock sizes\tQ starts\tT starts\n";
}

__DATA__

blat.pl

   Takes a query fasta file and a database fasta file/s and queries 
   the database using blat with the query fasta file. Note that the query
   file may contain multiple sequences.
   
   -d <str>:         Database fasta file or directory containing fasta files. Note that the maximum length of 
                     sequences in the fasta files is 67108864 bp.

   -q <str>:         Fasta file containing the queries.

   -identity <num>:  Minimum sequence identity (default: 90)

   -header:          Only print out the file header

   -ooc_file:        Name (full path) of overused tile file to use (default is <tile size>.ooc which is expected 
                     to be found in the current directory or in the directory of the database fasta file/s).

   -no_ooc:          Do not use the overused tile file (the ooc file). Default behavior is to use the ooc file, 
                     which runs much faster but ignores areas with repetitions. Yair - please clarify.
   
   -make_ooc:        Make overused tile file from the database fasta file (the queries file is ignored).
   -ooc_output_file: Overused tile file name (relevant only when -make_ooc is specified, default is N.ooc where N is the tile_size).
   -tile_size:       sets the size of match that triggers an alignment. Usually between 8 and 12 (Default is 11).


