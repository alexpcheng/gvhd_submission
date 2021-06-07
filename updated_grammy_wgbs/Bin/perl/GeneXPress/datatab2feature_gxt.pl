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

my $feature_name = get_arg("f", "Value", \%args);
my $use_column_header_as_feature_name = get_arg("e", 0, \%args);

my $line = <$file_ref>;
chop $line;
my @headers = split(/\t/, $line);

while(<$file_ref>)
{
    chop;

    my @row = split(/\t/);

    for (my $i = 1; $i < @row; $i++)
    {
	if (length($row[$i]) > 0)
	{
	    print "$row[0]\t";
	    print "$row[0] $headers[$i]\t";
	    print ($i - 1);
	    print "\t";
	    print "$i\t";
	    if ($use_column_header_as_feature_name == 1)
	    {
		print "$headers[$i]\t";
	    }
	    else
	    {
		print "$feature_name\t";
	    }
	    print "$row[$i]\n";
	}
    }
}

__DATA__

datatab2featuregxt.pl <file> 

    Creates a feature gxt file from a data-tab file.

    NOTE: creates only the tab delimited fields. Run the output 
          through tab2feature_gxt.pl to get the full feature gxt

    -f <str>: String to use for the feature name (default: 'Value')
    -e:       Use the column name as the feature name (overrides the -f option)

