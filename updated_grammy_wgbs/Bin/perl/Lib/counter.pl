#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

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

my $start_number = get_arg("s", 1, \%args);
my $end_number = get_arg("e", 10, \%args);
my $increment_number = get_arg("i", 1, \%args);
my $delimiter = get_arg("d", "\n", \%args);

for (my $i = $start_number; $i <= $end_number; $i += $increment_number)
{
  print "$i$delimiter";
}

__DATA__

counter.pl <file>

   Generates a counter that starts from a specified number and ends 
   at another number

   -s <num>: start number (default: 1)
   -e <num>: end number (default: 10)
   -i <num>: increment (default: 1)
   -d <str>: delimiter between numbers (default: new line)

