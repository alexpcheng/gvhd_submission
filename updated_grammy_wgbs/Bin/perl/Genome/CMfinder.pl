#!/usr/bin/perl
use strict;

my $EXE_DIR = "$ENV{GENIE_HOME}/Bin/CMfinder/CMfinder_0.2/bin";
my $BLAST_EXE_DIR = "$ENV{GENIE_HOME}/Bin/Blast/blast-2.2.10/bin";

# print help message
if ($ARGV[0] eq "--help") {
  `$EXE_DIR/cmfinder.pl -h`;
  exit;
}

# create fasta file
my $stab_file = shift(@ARGV);
$stab_file  =~ m/(.+)\.stab/g;
my $fasta_file = $1.".fasta";
`cat $stab_file | stab2fasta.pl > $fasta_file`;

# run cmfinder.pl
my $command = 
  "export CMfinder=$EXE_DIR; ".
  "export BLAST=$BLAST_EXE_DIR; ".
  "echo \$BLAST \$CMfinder; ".
  "$EXE_DIR/cmfinder.pl $fasta_file";
my $r = `$command`;
print "$r\n";

# remove temporary files
`rm -rf $fasta_file`;
