#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $BLAST_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Blast/64bit/blast-2.2.14/bin";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}


my %args = load_args(\@ARGV);

my $input_file = get_arg("i", "", \%args);
my $output_format = get_arg("f", "8", \%args);
my $sequence_type = get_arg("protein", "F", \%args);
my $filter = get_arg("nofilter","T",\%args);
my $output_file = get_arg("o", "", \%args);
my $blast_program = get_arg("b", "blastn", \%args);

if ($sequence_type==1) { $sequence_type="T" }
if ($filter==1) { $filter="F" }

die ("Required parameter is missing!\n") unless ($input_file and $output_file);
die ("Input file not found!\n") unless (-e $input_file);

my $r = int(rand(1000000));
system("$BLAST_EXE_DIR/formatdb -i $input_file -p $sequence_type -n tmp_db_$r -t tmp_db_$r");
system("$BLAST_EXE_DIR/blastall -p $blast_program -d tmp_db_$r -o $output_file -m $output_format -i $input_file -F $filter");
system ("rm -f tmp_db_$r.*");


__DATA__

blast_all_vs_all.pl <file>

   Takes in as input fasta file and BLASTs all sequences against each other.

   -i <str>:       Query fasta file (required)
   -o <str>:       Output file (required)

   -protein:       Sets input sequence type to amino acids (default: off)
   -nofilter:      Turn off sequence filtering (default: off (sequence is filtered))
   -b <str>:       Sets BLAST program type to use (blastp, blastn, blastx, etc) (default: blastn)
   -f <num>:       Set BLAST output format (default: 8 (table))
