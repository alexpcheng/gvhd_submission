#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
 print STDOUT <DATA>;
 exit;
}

my %args = load_args(\@ARGV);

my $start_number = get_arg("s", 1, \%args);
my $end_number = get_arg("e", 100, \%args);
my $increment = get_arg("i", 1, \%args);

for (my $i = $start_number; $i <= $end_number; $i += $increment)
{
  print "$i\n";
}

__DATA__

number_generator.pl

   Creates a sequence of numbers according to specifications

   -s <num>: Start number (default: 1)
   -e <num>: End number   (default: 100)
   -i <num>: Increment    (default: 1)

