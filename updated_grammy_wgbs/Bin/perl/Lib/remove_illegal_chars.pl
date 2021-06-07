#!/usr/bin/perl

use strict;

require "$ENV{PERL_HOME}/Lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my %args = load_args(\@ARGV);
my $delete = get_arg("d", 0, \%args);
my $last_line_to_process = get_arg("e", -1, \%args);

my $line = 1;
while(<STDIN>)
{
    if ($last_line_to_process == -1 or $line <= $last_line_to_process)
    {
	print &removeIllegalXMLChars($_);
    }
    else
    {
	print $_;
    }

    $line++;
}

#---------------------------------------------------------------------------
# removeIllegalXMLChars
#---------------------------------------------------------------------------
sub removeIllegalXMLChars
{
    my $str = $_[0];

    my $res_str = "";
    for (my $i = 0; $i < length($str); $i++)
    {
	my $char = substr($str, $i, 1);
	if ((ord($char) >= 32 and ord($char) <= 126) or ord($char) == 10 or ord($char) == 9)
	{
	    $res_str .= $char;
	}
    }

    if ($delete == 0)
    {
	$res_str =~ s/\&/&amp;/g;
	$res_str =~ s/\"/&quot;/g;
	$res_str =~ s/\'/&apos;/g;
	$res_str =~ s/\</&lt;/g;
	$res_str =~ s/\>/&gt;/g;
    }
    else
    {
	$res_str =~ s/\&//g;
	$res_str =~ s/\"//g;
	$res_str =~ s/\'//g;
	$res_str =~ s/\<//g;
	$res_str =~ s/\>//g;
    }
    
    return $res_str;
}

__DATA__

removeIllegalChars.pl

   Remove illegal characters from the file

   -d:       Delete the characters (default: replace with legal XML statements)

   -e <num>: Last line to process (default: -1 for all lines)

