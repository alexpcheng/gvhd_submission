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
my $minimum_length = get_arg("l", 0, \%args);
my $expand_on_both = get_arg("b", 0, \%args);
my $expand_on_start = get_arg("s", 0, \%args);
my $expand_on_end = get_arg("e", 0, \%args);
my $expansion_string = get_arg("c", "-", \%args);

my $expansion_string_length = length($expansion_string);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  print "$row[0]\t";

  my $prefix = "";
  my $suffix = "";

  my $sequence_length = length($row[1]);
  while ($sequence_length < $minimum_length)
  {
    if ($expand_on_start == 1 or $expand_on_both == 1)
    {
      $prefix .= "$expansion_string";
      $sequence_length += $expansion_string_length;
    }

    if ($expand_on_end == 1 or $expand_on_both == 1)
    {
      $suffix .= "$expansion_string";
      $sequence_length += $expansion_string_length;
    }
  }

  print "$prefix$row[1]$suffix\n";
}

__DATA__

expand_sequences.pl <file>

   Given a stab file, expand each sequence to a minimum length

   -l <num>: Minimum length of each sequence

   -b:       Each expansion step expands the sequence on both ends
   -s:       Each expansion step expands the sequence at its start
   -e:       Each expansion step expands the sequence at its end

   -c <str>: Character(s) to expand in each step

