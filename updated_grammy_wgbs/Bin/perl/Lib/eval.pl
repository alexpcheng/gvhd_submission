#!/usr/bin/perl

use strict;

if ($ARGV[0] eq "--help"){
  print STDOUT <DATA>;
  exit;
}
my $input=join(" ",@ARGV);

print (eval($input));
print "\n";


__DATA__

eval.pl

Evaluates and prints an expression in perl (for make files).


