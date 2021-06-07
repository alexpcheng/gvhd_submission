#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


my $arg;
my $file = \*STDIN;

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
my $headers = get_arg("h", 0, \%args);
my $string = get_arg("s", "", \%args);
my $delimiter = get_arg("d", "", \%args);

if ($string ne ""){
  my @tmp=split/$delimiter/,$string;
  print $tmp[$#tmp];
  for (1..$#tmp){print $delimiter,$tmp[$#tmp-$_];}
  print "\n";
  exit ;
}

for (1..$headers){
  my $tmp=<$file_ref>;
  print $tmp;
}

my @rows;
while(<$file_ref>)
{
  push(@rows, $_);
}

for (my $i = @rows - 1; $i >= 0; $i--)
{
  print "$rows[$i]";
}

__DATA__

syntax: reverse.pl TAB_FILE [OPTIONS]

   Reverses a file (first line printed last, last printed first)
   NOTE: loads file into memory.

OPTIONS are:

   -h <num>:   number of header rows to skip
   -s <str>:   reverse a string instead of a file (default off)
   -d <str>:   delimiter for string reversal (default: "")
