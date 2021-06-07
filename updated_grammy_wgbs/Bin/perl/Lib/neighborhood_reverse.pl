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
#my $no_center_pairs = get_arg("nc", 0, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  print "$row[0]";

  for (my $i = @row - 1; $i >= 1; $i--)
  {
    print "\t$row[$i]";
  }

  print "\n";
}


__DATA__

neighborhood_reverse.pl <file>

   Print the neighborhood of each member in reverse order

