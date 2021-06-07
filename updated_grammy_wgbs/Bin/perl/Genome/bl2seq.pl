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

my $input_file1 = get_arg("i", "", \%args);
my $input_file2 = get_arg("j", "", \%args);
my $output_format = get_arg("f", "1", \%args);
my $filter = get_arg("nofilter","T",\%args);
my $output_file = get_arg("o", "", \%args);
my $blast_program = get_arg("b", "blastn", \%args);

if ($filter==1) { $filter="F" }

die ("Required parameter is missing!\n") unless ($input_file1 and $input_file2);
die ("Required parameter is missing!\n") unless ($output_file);

die ("Input file $input_file1 not found!\n") unless (-e $input_file1);
die ("Input file $input_file2 not found!\n") unless (-e $input_file2);


system("$BLAST_EXE_DIR/bl2seq -i $input_file1 -j $input_file2 -p $blast_program  -o $output_file -D $output_format -F $filter");


__DATA__

bl2seq.pl <file>

   Takes in as input two fasta files containing one sequence each and BLASTs the two sequences against each other.

   -i <str>:       Sequence I fasta file (required)
   -j <str>:       Sequence II fasta file (required)
   -o <str>:       Output file (required)
   -nofilter:      Turn off sequence filtering (default: off (sequence is filtered))
   -b <str>:       Sets BLAST program type to use (blastp, blastn, blastx, etc) (default: blastn)
   -f <num>:       Set BLAST output format (default: 1 (table))
