#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

my $NETBLAST_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Blast/netblast-2.2.13/bin";

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

my $echoed_args = 	echo_arg("n", \%args) . 
					echo_arg("d", \%args); 

my $r = int(rand(1000000));

my $input_file = (-f $ARGV[0]) ? "-i $ARGV[0] " : "";
system("$NETBLAST_EXE_DIR/blastcl3 -p blastn $echoed_args $input_file -o tmp_$r -m 8");

system("cat tmp_$r | cap.pl 'Query id,Subject id,% identity,alignment length,mismatches,gap openings,q. start,q. end,s. start,s. end,e-value,bit score'");
system("rm tmp_$r*");

__DATA__

netblast.pl <file>

   Takes in as input a query fasta file and performs a remote BLAST query. 

   -d <str>:  Database (default = nr)

              Multiple database names (bracketed by quotations) are 
              accepted. Example: -d "nr est" 

  -n  MegaBlast search [T/F]
    default = F
