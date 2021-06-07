#!/usr/bin/perl
use strict;


# help mesasge
if (($ARGV[0] eq "--help") or (scalar(@ARGV) != 2)){
  print STDOUT <DATA>;
  exit;
}

# parameters
my $file1 = $ARGV[0];
my $file2 = $ARGV[1];


# read first file
my @list;
open(FILE1, $file1) or die("Could not open file '$file1'.\n");
while (<FILE1>) {
  chomp;
  push(@list, $_);
}
close(FILE1);

open(FILE2, $file2) or die("Could not open file '$file2'.\n");
while (<FILE2>) {
  chomp;
  my $line = $_;

  foreach my $val (@list) {
    print "$line\t$val\n";
  }
}
close(FILE2);



__DATA__

all_pairs.pl <file_name1> <file_name2>

take as input 2 files, each with a list of values (one value per row)
and create a list of all pairs of lines(tab delimited).
The first file is read into memory, thus recomanded to be shorter
