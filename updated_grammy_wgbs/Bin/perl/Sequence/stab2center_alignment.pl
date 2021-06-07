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

my $alignment_length = get_arg("l", "", \%args);
my $padding_character = get_arg("p", "-", \%args);
my $add_reverse_complement = get_arg("rc", 0, \%args);
my $fix_weight = get_arg("fix_weight", 0, \%args);

my $r = int(rand(100000));

my $delete_file = 0;
if (length($alignment_length) == 0)
{
  $delete_file = 1;
  open(OUTFILE, ">tmp$r");
  $alignment_length = 0;
  while(<$file_ref>)
  {
    chop;

    my @row = split(/\t/);

    my $str_length = length($row[1]);
    if ($str_length > $alignment_length)
    {
      $alignment_length = $str_length;
    }
    
    print OUTFILE "$_\n";
  }
  close(OUTFILE);
  open(FILE, "<tmp$r");
  $file_ref = \*FILE;
}

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  &ProcessSequence($row[0], $row[1], 0);

  if ($add_reverse_complement == 1)
  {
    &ProcessSequence($row[0], &ReverseComplement($row[1]), 1);
  }
}

if ($delete_file == 1) { system("rm -f tmp$r"); }

sub ProcessSequence
{
  my ($sequence_name, $sequence, $reverse) = @_;

  my $sequence_length = length($sequence);

  my $left_padding = int(($alignment_length - $sequence_length) / 2);

  if ($reverse == 1 and ($alignment_length - $sequence_length) % 2 == 1)
  {
    $left_padding++;
  }

  &PrintSequence($sequence_name, $sequence, $left_padding);

  if ($fix_weight)
  {
    if (($alignment_length - $sequence_length) % 2 == 0)
    {
      &PrintSequence($sequence_name, $sequence, $left_padding);
    }
    elsif ($reverse == 0)
    {
      &PrintSequence($sequence_name, $sequence, $left_padding + 1);
    }
    else
    {
      &PrintSequence($sequence_name, $sequence, $left_padding - 1);
    }
  }
}

sub PrintSequence
{
  my ($sequence_name, $sequence, $left_padding) = @_;

  my $sequence_length = length($sequence);

  print "$sequence_name\t";

  my $position = 0;
  for (; $position < $left_padding; $position++)
  {
    print "$padding_character";
  }

  print "$sequence";

  $position += $sequence_length;
  for (; $position < $alignment_length; $position++)
  {
    print "$padding_character";
  }
  print "\n";
}

__DATA__

stab2center_alignment.pl <file>

   Center aligns a stab file

   -l <num>:    Length of the center alignment (default: max sequence length)

   -p <str>:    Character to add in padding of center alignment (default: '-')

   -rc:         Add the reverse complement of each sequence to the alignment

   -fix_weight: Insert sequences with a length matching the alignment length twice
                and sequences not matching the alignment length once in two orientations

