#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";


my $arg;
my $file = \*STDIN;

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
my $index_of_first_column_to_reverse = get_arg("hc", 0, \%args);


while(<$file_ref>) {
  chomp;
  my @line = split(/\t/,$_);

  for ( my $i=0 ; $i < $index_of_first_column_to_reverse ; $i++ ) {
    if ( $i > 0 ) { print "\t"; }
    print $line[$i];
  }

  if ( $index_of_first_column_to_reverse > 0 ) { print "\t"; }

  for ( my $i=@line-1 ; $i >= $index_of_first_column_to_reverse ; $i-- ) {
    if ( $i < @line-1 ) { print "\t"; }
    print $line[$i];
  }
  print "\n";
}


__DATA__

syntax: reverse_column.pl TAB_FILE [OPTIONS]

   Reverses the columns of a file.

OPTIONS are:

   -hc <num>:  number of header columns to skip (default: 0)

