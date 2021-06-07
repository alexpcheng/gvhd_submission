#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";
require "$ENV{PERL_HOME}/Lib/system.pl";

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
my $window_size = get_arg("w", 100, \%args);
my $window_jump = get_arg("j", 100, \%args);

my $counter = 1;
while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  for (my $i = 0; $i <= length($row[1]) - $window_size; $i += $window_jump)
  {
    my $end = $i + $window_size - 1;
    print "$row[0]\t$counter\t$i\t$end\n";
    $counter++;
  }
}

__DATA__

stab2windowchr.pl <file>

   Outputs a chr file of windows around each sequence

   -w <num>: Window size (default: 100)
   -j <num>: Window jump (default: 100)

