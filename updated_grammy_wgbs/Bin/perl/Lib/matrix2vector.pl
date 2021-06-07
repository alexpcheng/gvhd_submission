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

my $skipc =  get_arg("skipc", "1", \%args);
my $skip =  get_arg("skip", "1", \%args);
my $delim = get_arg("delim", "\t", \%args);

die ("negative number of columns to skip $skipc\n") if ($skipc < 0);
die ("negative number of rows to skip $skip\n") if ($skip < 0);


my $line = "";
my $out_string = "";

my $line_index = 0;
while ($line_index < $skip)
{
    <$file_ref>;
    $line_index++;
}

while($line = <$file_ref>)
{
    chomp($line);
    my @row = split(/\t/, $line);
    for (my $i = $skipc; $i < @row; $i++)
    {
	if ($out_string ne "")
	{
	    $out_string = $out_string.$delim.$row[$i]; 
	}
	else
	{
	    $out_string = $row[$i];
	}
    }
}
print "$out_string\n";

__DATA__

matrix2vector.pl <file>

   Converts a matrix into a vector

   -skipc <num>:   number of columns to skip (default: 1)
   -skip <num>:   number of rows to skip (default: 1)
   -delim <str>: the delimiter between vector entries(default : \t)
