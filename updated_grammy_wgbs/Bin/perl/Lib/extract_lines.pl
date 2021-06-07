#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";
require "$ENV{PERL_HOME}/Lib/libfile.pl";
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

my $skip = get_arg("skip", 0, \%args);
my $line_increment = get_arg("i", 0, \%args);

for (my $i = 0; $i < $skip; $i++)
{
  my $line = <$file_ref>;
}

while (<$file_ref>)
{
  chomp;

  print "$_\n";

  for (my $i = 0; $i < $line_increment; $i++)
  {
    my $line = <$file_ref>;
  }
}

__DATA__

extract_lines.pl <file>

   Extracts specific lines from a file

   -skip <num>: Number of lines to skip (default: 0)
   -i <num>:    Increment number of lines to skip after extracting each row (default: 0)

