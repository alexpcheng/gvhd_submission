#!/usr/bin/perl
use strict;

# program directory
my $RNAforester_EXE_DIR = "$ENV{GENIE_HOME}/Bin/ViennaRNA/ViennaRNA-1.6/".
  "RNAforester/src";

# arguments
if ($ARGV[0] eq "--help") {
  print STDERR <DATA>;
  exit;
}

my $command = "$RNAforester_EXE_DIR/RNAforester --fasta";
my $remove = 0;
my $file_name;

# input args
while (my $arg = shift(@ARGV)) {
  if ($arg =~ /^-l/) {
    $command = $command." -l";
  }
  elsif ($arg =~ /^-m/) {
    $command = $command." -m";
  }
  elsif ($arg =~ /^-/) {
    print STDERR <DATA>;
    exit;
  }
  elsif ($arg =~ /^-p/) {
    $command = $command." -m";
  }
  else {
    $file_name = convert($arg);
    $command = $command." -f $file_name";
    $remove = 1;
    last;
  }
}

# run command
my $output = `$command`;
print "$output \n\n\n";

if ($remove) {
  `rm -rf $file_name`;
}

# write sequences to output file

#---------------------------------------------------------------------------
# subs
#---------------------------------------------------------------------------
sub convert {
  my ($file_name) = @_;
  my $new_name = $file_name."forester";
  
  open(IN, "$file_name");
  open(OUT,">$new_name");
  
  while (<IN>) {
    my $line = $_;
    chomp($line);
    $line =~ m/^(.+)\t([ACGTUacgtu]+)\t([\.\(\)]+)/g;
    my $name = $1;
    my $seq = $2;
    $seq =~ tr/ACGUT/acguu/;
    my $struct = $3;
    print OUT "> $name\n$seq\n$struct\n";
  }
  close(IN);
  close(OUT);
  return($new_name);
}


__DATA__
---------------------------------------------------------------------------
RNAforester.pl [options] [file_name]

RNAforester reads RNA sequences and structure from the stdin and align the
sequences according to their structure.

The sequences are given in the following format:
<id> <sequence> <structure>
You can either give a file name or write the sequences to the stdin

OPTIONS

       --help                    shows this help info
       -l                        local similarity
       -m                        multiple alignment mode
       -p                        predict structures from sequences

---------------------------------------------------------------------------
