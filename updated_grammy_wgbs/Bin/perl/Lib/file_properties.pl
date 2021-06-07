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

my $file_name = get_arg("f", 0, \%args);
my $dir_name = get_arg("d", 1, \%args);

while(<$file_ref>)
{
  chomp;

  my @row = split(/\t/);

  if ($file_name)
  {
    my @dirs = split(/\//, $row[0]);
    print "$dirs[@dirs - 1]\n";
  }
  elsif ($dir_name)
  {
    my @dirs = split(/\//, $row[0], 2);
    print "$dirs[0]\n";
  }
}

__DATA__

file_properties.pl <file>

   Extracts properties of files

   -f: get the file name of each file
   -d: get the directory of each file

