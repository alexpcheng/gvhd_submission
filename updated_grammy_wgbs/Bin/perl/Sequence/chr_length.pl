#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Sequence/sequence_helpers.pl";

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
my $last = get_arg("last", 0, \%args);

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/, $_, 5);

    my $length = $row[2] < $row[3] ? ($row[3] - $row[2] + 1) : ($row[2] - $row[3] + 1);

    if ($last) {print "$_\t$length\n"}
    else {print "$length\t$_\n"}
}

__DATA__

chr_length.pl <file>

   Given a .chr file, computes the length of each item and adds it as the first column

  -last:   add length as last column
