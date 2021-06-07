#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/format_number.pl";

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

my $skip_lines = get_arg("skip", 1, \%args);

for (my $i = 0; $i < $skip_lines; $i++)
{
    my $line = <$file_ref>;
}

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  print "$row[0]\t";
  for (my $i = 1; $i < @row; $i++)
  {
      print $row[$i];
  }
  print "\n";
}

__DATA__

tab2stab.pl <file>

   Takes in a tab delimited file and converts it to a stab file

   -skip <num>: Skip (and do not print) the first <num> rows in the file (default: 1)

