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

my $default_value = get_arg("d", 0, \%args);

my %strings_hash;
my %strings_lengths;
my $done = 0;
my $counter = 1;
while ($done == 0)
{
    my $str_num = get_arg("s$counter", "", \%args);
    if (length($str_num) > 0)
    {
	my @string = split(/\,/, $str_num);

	$strings_hash{$string[0]} = $string[1];
	$strings_lengths{length($string[0])} = "1";
	$counter++;
    }
    else
    {
	$done = 1;
    }
}

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    print "$row[0]";

    my $str_length = length($row[1]);
    for (my $i = 0; $i < $str_length; $i++)
    {
	my $value = $default_value;
	foreach my $len (keys %strings_lengths)
	{
	    my $str = substr($row[1], $i, $len);

	    if (length($strings_hash{$str}) > 0)
	    {
		$value = $strings_hash{$str};
		last;
	    }
	}

	print "\t$value";
    }

    print "\n";
}

__DATA__

stab2function.pl <file>

   Converts each sequence to a numerical function and outputs it as a tab file

   -s1 <str,num>: Sequence str, at its start position will be assigned the value <num>
   -s2 <str,num>: ... (Example: TA,1.5)

   -d <num>:      Default number to assign (default: 0) in case a sequence is not hit

