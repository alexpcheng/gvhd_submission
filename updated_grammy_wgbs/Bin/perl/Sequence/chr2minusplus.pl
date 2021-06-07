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

my $start_column = get_arg("s", 2, \%args);
my $end_column = get_arg("e", 3, \%args);
my $no_minusplus_column = get_arg("n", 0, \%args);
my $do_inverse = get_arg("inv", 0, \%args);

while(<$file_ref>)
{
  chop;

  my @row = split(/\t/);

  if ( $do_inverse ) {
    if ( $row[$end_column+1] eq "-" ) {
      my $tmp = $row[$start_column];
      $row[$start_column] = $row[$end_column];
      $row[$end_column] = $tmp;
    }

    print join("\t", splice(@row, 0, $end_column+1), splice(@row, 1) );
  }

  else {
    my $minusplus = $row[$start_column] < $row[$end_column] ? "+" : "-";

    if ($row[$end_column] < $row[$start_column])
      {
	my $tmp = $row[$start_column];
	$row[$start_column] = $row[$end_column];
	$row[$end_column] = $tmp;
      }

    if ($no_minusplus_column){
      print join("\t", splice(@row, 0, $end_column + 1), @row);
    }
    else{
      print join("\t", splice(@row, 0, $end_column + 1), $minusplus, @row);
    }
  }

  print "\n";
}

__DATA__

chr2minusplus.pl <file>

   Converts a chr file to a minus/plus format. The +/- column is printed right after the end column.

   -s <num>: Column of start location (default: 2)
   -e <num>: Column of end location (default: 3)
   -n:       No +/- column
   -inv:     Perform the inverse. assumes that input chr includes a +/- column right after the end column.
