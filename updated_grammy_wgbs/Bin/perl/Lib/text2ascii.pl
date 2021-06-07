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

#my $delete = get_arg("d", 0, \%args);
print ord("\r");
print "\n";
while(<$file_ref>)
{
    my $str = $_;

    for (my $i = 0; $i < length($str); $i++)
    {
	my $char = substr($str, $i, 1);

	print "[";
	print ord($char);
	print "]";
	print "$char";
	print " ";
    }
}

__DATA__

text2ascii.pl

   Prints the ASCII value of each character in a text file

