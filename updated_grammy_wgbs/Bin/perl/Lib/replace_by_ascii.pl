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

my $ascii_to_replace = get_arg("a", 13, \%args);
my $replace_char = get_arg("r", 10, \%args);

while(<$file_ref>)
{
    my $str = $_;

    for (my $i = 0; $i < length($str); $i++)
    {
	my $char = substr($str, $i, 1);

	if (ord($char) == $ascii_to_replace)
	{
	    print chr($replace_char);
	}
	else
	{
	    print $char;
	}
    }
}

__DATA__

replace_by_ascii.pl

   Replaces characters by their ascii value to other characters

   -a <num>: Ascii number to replace (default: 13)
   -r <str>: String with which to replace the ascii values above (default: 10 ["\n"])

