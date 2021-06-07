#!/usr/bin/perl

require "$ENV{PERL_HOME}/Lib/liblist.pl";

use strict;

my $arg;
my $num           = undef;
my $replace       = 0;
my $headers       = 0;
my $print_header  = 0;
my $blanks        = 1;
my $file          = \*STDIN;

while(@ARGV)
{
  $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-n')
  {
     $arg = shift @ARGV;
     if((-f $arg) or (-l $arg) or ($arg eq '-'))
     {
        open(FILE, $arg) or die("Could not open file '$arg'");
        $num = int(<FILE>);
        close(FILE);
     }
     else
     {
        $num = int($arg);
     }
  }
  elsif($arg eq '-wr')
  {
    $replace = 1;
  }
  elsif($arg eq '-wor')
  {
    $replace = 0;
  }
  elsif($arg eq '-hnp')
  {
    $headers = 1;
    $print_header = 0;
  }
  elsif($arg eq '-hp')
  {
    $headers = 1;
    $print_header = 1;
  }
  elsif($arg eq '-nb')
  {
    $blanks = 0;
  }
  elsif((-f $arg) or ($arg eq '-'))
  {
    open($file, $arg) or die("Could not open file '$arg' for reading.");
  }
  else
  {
    die("Invalid argument '$arg'.");
    exit(1);
  }
}

my @list=();
my $item = '';
my $line = 0;

while(<$file>)
{
  $line++;
  if($line <= $headers)
  {
    if($print_header)
      { print; }
  }
  elsif($blanks or /\S/)
  {
     my $line = $_;
     push(@list, \$line);
  }
}
close($file);

$num = defined($num) ? $num : scalar(@list);
if ($replace == 0 and $num > scalar(@list))
{
  $num = scalar(@list);
}

#print STDERR "$num ", scalar(@list), " $replace\n";

my $permuted = &listPermute(\@list, $num, $replace);

foreach my $item (@{$permuted})
{
   print "$$item";
}

exit(0);

__DATA__
syntax: rand_lines.pl [OPTIONS] < INFILE

OPTIONS are:

-n N: Chooose N lines from the file (default choose all lines from file; i.e. either
      bootstraps if -wr supplied, or returns a permutation if -wor is supplied).  If
      N is a file, reads the first line and extracts a number from it.
-wr:  Choose lines with replacement
-wor: Choose lines without replacement (DEFAULT)
-hp:  The file contains a header line and the header should be printed.
-hnp: The file contains a header line and it should *not* be printed.
-b:   Skip blanks (default includes blanks contained in the file).


