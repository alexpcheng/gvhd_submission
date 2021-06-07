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

my $print_header = get_arg("header", 0, \%args);

if ($print_header == 1)
{
  &PrintHeader();
  exit;
}

my %values;

while(<$file_ref>)
{
  chomp;

  if ($_ eq "=" and length($values{"PRIMER_PAIR_PENALTY"}) > 0)
  {
    print $values{"PRIMER_SEQUENCE_ID"} . "\t";
    print $values{"PRIMER_PAIR_PENALTY"} . "\t";
    print $values{"PRIMER_PAIR_COMPL_ANY"} . "\t";
    print $values{"PRIMER_PAIR_COMPL_END"} . "\t";
    print $values{"PRIMER_PRODUCT_SIZE"} . "\t";

    my @left_location = split(/\,/, $values{"PRIMER_LEFT"});
    print "$left_location[0]\t$left_location[1]\t";
    print $values{"PRIMER_LEFT_TM"} . "\t";
    print $values{"PRIMER_LEFT_SELF_ANY"} . "\t";
    print $values{"PRIMER_LEFT_SELF_END"} . "\t";

    my @right_location = split(/\,/, $values{"PRIMER_RIGHT"});
    $right_location[0] = length($values{"SEQUENCE"}) - $right_location[0] + 1;
    print "$right_location[0]\t$right_location[1]\t";
    print $values{"PRIMER_RIGHT_TM"} . "\t";
    print $values{"PRIMER_RIGHT_SELF_ANY"} . "\t";
    print $values{"PRIMER_RIGHT_SELF_END"} . "\t";

    print $values{"PRIMER_LEFT_SEQUENCE"} . "\t";
    print $values{"PRIMER_RIGHT_SEQUENCE"} . "\t";

    if (length($values{"PRIMER_WARNING"}) > 0)
    {
      print $values{"PRIMER_WARNING"} . "\t";
    }
    else
    {
      print "NO WARNINGS\t";
    }

    print $values{"SEQUENCE"} . "\n";
  }
  else
  {
    my @row = split(/\=/);

    $values{$row[0]} = $row[1];
  }
}

sub PrintHeader
{
  print "ID\t";
  print "PairPenalty\t";
  print "PairComplyAny\t";
  print "PairComplyEnd\t";
  print "Size\t";
  print "LeftLocation\t";
  print "LeftLength\t";
  print "LeftTM\t";
  print "LeftSelfAny\t";
  print "LeftSelfEnd\t";
  print "RightLocation\t";
  print "RightLength\t";
  print "RightTM\t";
  print "RightSelfAny\t";
  print "RightSelfEnd\t";
  print "LeftSequence\t";
  print "RightSequence\t";
  print "Warnings\t";
  print "Sequence\n";
}

__DATA__

parse_primer3.pl <file>

   Flattens the output of primer3

   -header: only output the header of the file

