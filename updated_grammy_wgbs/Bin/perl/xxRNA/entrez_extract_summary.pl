#!/usr/bin/perl
use strict;

my ($name, $symbol, $chr, $locus, $start, $end, $sign, $gid);
my $to_print = 0;
while (<STDIN>) {
  chomp $_;
  if ($_ =~ m/^ Official Symbol (.+) and Name:(.+)\[/g) {
    $symbol = $1;
    $name = $2;
  }
  elsif ($_ =~ m/^ Chromosome: (.+); Location: (.+)/g) {
    $chr = $1;
    $locus = $2;
  }
  elsif ($_ =~ m/^ Chromosome: (.+)/g) {
    $chr = $1;
    $locus = "?";
  }
  elsif ($_ =~ m/^Mitochondrion: (MT)/g) {
    $chr = $1;
    $locus = "?";
  }
  elsif ($_ =~ m/^ Annotation:  Chromosome .+ \((\d+)\.\.(\d+)(.*)\)/g) {
    $to_print = 1;
    $start = $1;
    $end = $2;
    if ($3 =~ m/complement/g) {
      $sign = "-";
    }
    else {
      $sign = "+";
    }
  }
  elsif ($_ =~ m/^ Annotation: .+ \((\d+)\.\.(\d+)(.*)\)/g) {
    $to_print = 1;
    $start = $1;
    $end = $2;
    if ($3 =~ m/complement/g) {
      $sign = "-";
    }
    else {
      $sign = "+";
    }
  }
  elsif ($_ =~ m/^ GeneID: (\d+)/g) {
    $gid = $1;
  }
  elsif ($_ =~ m/^\d+:/g) {
    if ($to_print) {
      print "$gid\t$chr\t$start\t$end\t$sign\t$symbol\t$name\n";
    }
    $name = "";
    $symbol = "";
    $chr = "";
    $locus = "";
    $start = "";
    $end = "";
    $sign = "";
    $gid = "";
    $to_print = 0;
  }
}
print "\n";
