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

my $keys_file = get_arg("k", "", \%args);
if (length($keys_file) == 0) { print STDERR "rename_keys.pl: No Keys file supplied (POSSIBLE ERROR: USE OF OLD VERSION WITH SECOND ARGUMENT RATHER THAN AS PARAMETER)\n"; }

my $row_key = get_arg("rk", 0, \%args);

my %keys;
open(KEYS_FILE, "<$keys_file") or die "could not open keys file $keys_file\n";
while(<KEYS_FILE>)
{
  chop;

  my @row = split(/\t/);

  $keys{$row[0]} = $row[1];
}

my $line = <$file_ref>;
chop $line;
my @headers = split(/\t/, $line);
for (my $i = 0; $i < @headers; $i++)
{
  if (length($keys{$headers[$i]}) > 0) { print "$keys{$headers[$i]}"; }
  else { print "$headers[$i]"; }

  if ($i < @headers - 1) { print "\t"; }
}
print "\n";

while (<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  for (my $i = 0; $i < @row; $i++)
  {
    if ($i != $row_key)
    {
      print "$row[$i]";
    }
    else
    {
      if (length($keys{$row[$row_key]}) > 0) { print "$keys{$row[$row_key]}"; }
      else { print "$row[$row_key]"; }
    }

    if ($i < @row - 1) { print "\t"; }
  }
  print "\n";
}


__DATA__

rename_keys.pl <source file>

   Rename the keys (both columns and rows) in source file using the
   keys supplied in keys file. keys file are tab delimited. keys 
   that do not exist in the keys file are not changed.

   -k <file:   keys file to use

   -rk <num>:  key for the rows in the source file (default: 0)

