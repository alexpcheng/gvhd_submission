#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/load_args.pl";

use strict;

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
my $count_rows = get_arg("r", "", \%args);
my $count_columns = get_arg("c", "", \%args);
my $skip_header_rows = get_arg("skip", 0, \%args);
my $skip_header_columns = get_arg("skipc", 0, \%args);


my $num_rows=0;
my $num_columns=0;
$num_rows-=$skip_header_rows;
$num_columns-=$skip_header_columns;

while (<$file_ref>){
  if ($count_columns ne "" and $num_columns==-$skip_header_columns){
    $num_columns+=split/\t/;
  }
  $num_rows++;
}

if ($count_rows ne ""){
  print $num_rows;
}
if ($count_rows ne "" and $count_columns ne ""){
  print "\t";
}
if ($count_columns ne ""){
  print $num_columns;
}
print "\n";

__DATA__

tabsize.pl

counts number of rows/columns in tab file

  -r :           count rows
  -c :           count columns
  -skip <num>:   do not count first <num> rows (default 0)
  -skipc <num>:  do not count first <num> columns (default 0)

